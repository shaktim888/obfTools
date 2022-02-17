//
//  XCM_Handler.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "XClass_Handler.h"
#include "XCommanFunc.hpp"
#include "XOCClass.hpp"
#include "XCodeLine.h"
#include "XOCPropInfo.hpp"

using namespace hygen;

static OCMethodType getEMethodByString(std::string & type)
{
    if(type.find("m1") == 0) {
        return OCMethodType::OCMethodType_Init;
    }
    if(type.find("m2") == 0) {
        return OCMethodType::OCMethodType_Create;
    }
    if(type.find("m") == 0) {
        return OCMethodType::OCMethodType_Method;
    }
    if(type.find("p") == 0) {
        return OCMethodType::OCMethodType_Property;
    }
    return OCMethodType::OCMethodType_NONE;
}

static OCClassType getBTypeByString(std::string & type) {
   if(type == "struct") {
       return OCClassType::OCClassType_Struct;
   }
   if(type == "class") {
       return OCClassType::OCClassType_Class;
   }
   if(type == "enum") {
       return OCClassType::OCClassType_Enum;
   }
   return OCClassType::OCClassType_NONE;
}

static std::string _normalizeType(std::string t) {
    string s = string_tolower(t);
    static vector<std::string> baseTypes = {
        "int", "float", "bool"
    };
    for(auto itr = baseTypes.begin(); itr != baseTypes.end(); itr++) {
        if(s.find(*itr) == 0) {
            t = s;
            return t;
        }
    }
    return t;
}


static void initOCClassByOneLine(OCClass* obj, std::string &s)
{
    std::vector<string> tokens;
    split(s,tokens, "##");
    std::vector<string> types;
    split(tokens[1], types, "#", 1);
    OCMethodType mt = getEMethodByString(types[0]);
    switch (mt) {
        case OCMethodType::OCMethodType_Method:
        case OCMethodType::OCMethodType_Init:
        case OCMethodType::OCMethodType_Create:
        {
            OCMethod * method = new OCMethod(obj);
            method->call = types[1];
            method->methodType = mt;
            if(tokens.size() > 2) {
                std::vector<string> args;
                split(tokens[2], args, ",");
                method->retType = obj->name;
                for(auto it = args.begin(); it != args.end(); ++it){
                    if(mt == OCMethodType::OCMethodType_Method && it == args.begin()) {
                        method->retType = _normalizeType(*it);
                    } else {
                        OCParam * p = new OCParam();
                        p->typeName = _normalizeType(*it);
                        method->params.push_back(p);
                    }
                }
            }
            if(mt == OCMethodType::OCMethodType_Method)   obj->publicMethods.push_back(method);
            if(mt == OCMethodType::OCMethodType_Init)     obj->initMethods.push_back(method);
            if(mt == OCMethodType::OCMethodType_Create)   obj->createMethods.push_back(method);
            vector<string> mflag;
            split(types[0], mflag, "_");
            if(mflag.size() > 1) {
                for(int i = 1; i < mflag.size(); i++) {
                    if(mflag[i] == "const") {
                        method->isconst = true;
                    }
                }
            }
            break;
        }
        case OCMethodType::OCMethodType_Property:
        {
            PropInfo * prop = new PropInfo();
            prop->varName = types[1];
            prop->typeName = _normalizeType(tokens[2]);
            obj->props.push_back(prop);
            vector<string> mflag;
            split(types[0], mflag, "_");
            if(mflag.size() > 1) {
                for(int i = 1; i < mflag.size(); i++) {
                    if(mflag[i] == "read") {
                        prop->readonly = true;
                    } else if(mflag[i] == "write") {
                        prop->writeonly = true;
                    }
                }
            }
            
            break;
        }
        default:
            break;
    }
    
}

static void initEnumByOneLine(EnumInfo * e, std::string& s)
{
    std::vector<string> tokens;
    split(s,tokens, "##");
    std::vector<string> types;
    split(tokens[1], types, "#", 1);
    e->items.push_back(types[1]);
}


static BaseClass* genTypeByFile(ifstream& file) {
    BaseClass * t = nullptr;
    string s;
    OCClassType b_type;
start:
    if(getline(file,s))
    {
        if(s.find("#") == string::npos) {
            goto start;
        }
        std::vector<string> tokens;
        split(s,tokens, "##");
        std::vector<string> types;
        split(tokens[0], types, "#");
        b_type = getBTypeByString(types[1]);
        switch (b_type) {
            case OCClassType_Enum:
                t = new EnumInfo();
                break;
            default:
                t = new OCClass();
                break;
        }
        t->classType = b_type;
        t->name = types[2];
        t->libName = tokens[1];
    }
    while(getline(file,s))
    {
        if(s!="")
        {
            if(b_type == OCClassType_Enum) {
                initEnumByOneLine(dynamic_cast<EnumInfo*>(t), s);
            } else {
                initOCClassByOneLine(dynamic_cast<OCClass*>(t), s);
            }
        }
    }
    return t;
}


static OCInterface * getInterfaceByFile(ifstream & file) {
    OCInterface * inter = new OCInterface();
    string s;
start:
    if(getline(file,s)) {
        if(s.find("#") == string::npos) {
            goto start;
        }
        std::vector<string> tokens;
        split(s,tokens, "##");
        if(tokens.size() >= 3) {
            inter->libName = tokens[2];
        }
        inter->weight = atoi(tokens[0].c_str());
        std::vector<string> types;
        split(tokens[1], types, "#");
        if(types[0] == "interface") {
            inter->name = types[1];
        }
    }


    while(getline(file,s))
    {
        if(s!="") {
            OCMethod * method = new OCMethod(inter);
            method->methodType = OCMethodType_NONE;
            {
                std::regex reg("[+-]\\s*\\(([\\w]*)\\)\\s*(\\w+)");
                std::cmatch m;
                auto ret = std::regex_search(s.c_str(), m, reg);
                if (ret)
                {
                    method->declare = s;
                    method->retType = _normalizeType(m[1]);
                    method->methodName = m[2];
                }
            }
            {
                std::smatch m;
                std::regex reg("(\\w+)\\s*\\:\\(([\\w* <>]*)\\)\\s*(\\w+)");
                string::const_iterator start = s.begin();
                string::const_iterator end = s.end();
                while (std::regex_search(start, end, m, reg))
                {
                    OCParam * parm = new OCParam();
                    parm->paramName = m[1];
                    parm->typeName = _normalizeType(m[2]);
                    parm->varName = m[3];
                    method->params.push_back(parm);
                    start = m[0].second;    //更新搜索起始位置,搜索剩下的字符串
                }

            }
            inter->methods.push_back(method);
        }
    }
    return inter;
}
Class_Handler::Class_Handler() {
    loadAllType();
    loadAllInterface();
}

void Class_Handler::loadAllInterface() {
    interfaceTotalWeight = 0;
    NSString * folder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"File/cm/interface/"];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:folder];
    for (NSString *subpath in subpaths) {
        if ([subpath hasSuffix:@".cm"]) {
            ifstream infile;
            infile.open([[folder stringByAppendingPathComponent:subpath] UTF8String]);
            if(infile.is_open()) {
                OCInterface* type = getInterfaceByFile(infile);
               if(type) {
                   interfaceArr.push_back(type);
                   interfaceTotalWeight += type->weight;
               }
               infile.close();
           }
       }
    }
}

void Class_Handler::loadAllType()
{
    NSString * folder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"File/cm/type/"];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:folder];
    for (NSString *subpath in subpaths) {
        if ([subpath hasSuffix:@".cm"]) {
            ifstream infile;
//            NSLog(@"%@", [folder stringByAppendingPathComponent:subpath]);
            infile.open([[folder stringByAppendingPathComponent:subpath] UTF8String]);
            if(infile.is_open()) {
                BaseClass* type = genTypeByFile(infile);
                    if(type) {
                        classMap[type->name] = type;
                        if(type->classType == OCClassType::OCClassType_Class) {
                            allSysCls.push_back(dynamic_cast<OCClass*>(type));
                        }
                    }
                infile.close();
            }
      }
   }
}

void Class_Handler::loadSupportTypes()
{
    NSString * file_path = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"File/cm/oc.type"];
    ifstream infile;
    infile.open([file_path UTF8String]);
    if(infile.is_open()) {
        std::string s;
        while(getline(infile,s))
        {
            if(s!="")
            {
                std::vector<std::string> vecs;
                split(s, vecs, "_");
                if(vecs.size() > 1) {
                    trueTypes[vecs[0]] = atoi(vecs[1].c_str());
                }
            }
        }
        infile.close();
    }
}

// -------------------上面是加载部分----------
void Class_Handler::addDep(Context * context, std::string clsName) {
    replace_all_distinct(clsName, "*", "");
    replace_all_distinct(clsName, " ", "");
    BaseClass * c = classMap[clsName];
    if(c) {
        std::string libPath;
        if(c->libName != "") {
            libPath = "<" + c->libName + "/"+ c->libName + ".h>";
        } else {
            libPath = "\"" + c->name + ".h\"";
        }
        context->addDep(libPath);
    }
}

void Class_Handler::removeDep(Context * context, std::string clsName) {
    BaseClass * c = classMap[clsName];
    if(c) {
        std::string libPath;
        if(c->libName != "") {
            libPath = "<" + c->libName + "/"+ c->libName + ".h>";
        } else {
            libPath = "\"" + c->name + ".h\"";
        }
        context->removeDep(libPath);
    }
}

std::string Class_Handler::newInst(Context* context, std::string& typeName, float &maxValue, float &minValue, bool forceCreate) {
    std::string formatVarType = typeName;
    replace_all_distinct(formatVarType, "*", "");
    replace_all_distinct(formatVarType, " ", "");
    BaseClass* c = classMap[formatVarType];
    if(c) {
        addDep(context, c->name);
        if(forceCreate || c->classType == OCClassType_Class || c->classType == OCClassType_Struct) {
            Var * var = new Var();
            string code = c->onCreate(context);
            var->typeName = c->name;
            var->order = context->curBlock->genAnOrder();
            std::string varname = randomAVarName();
            var->varName = varname;
            auto line = new CodeLine();
            line->code = formatName(context, c->name) + varname + "="+ code + ";";
            line->order = var->order;
            context->curBlock->addLine(line);
            context->curBlock->addVar(var);
            return varname;
        } else {
            return c->onCreate(context);
        }
    }
    else {
        context->manager->createNewValue(context, formatVarType, maxValue, minValue, forceCreate);
    }
    return "";
}

void Class_Handler::onCall(Context* context, Var * var) {
    BaseClass * c = classMap[var->typeName];
    if(c) {
        c->onCall(context, var);
    }
}

void Class_Handler::supportTypes(CodeMode cmode, bool isRun, std::vector<struct TypeWeight*> &vec) {
    if(cmode & CodeMode_CXX) {
        for(auto itr = cxxCustomCls.begin(); itr != cxxCustomCls.end(); itr++) {
            auto item = new TypeWeight();
            item->typeName = *itr;
            item->weight = 1;
            vec.push_back(item);
        }
    }
    if(cmode & CodeMode_OC) {
        for(auto itr = ocCustomCls.begin(); itr != ocCustomCls.end(); itr++) {
            auto item = new TypeWeight();
            item->typeName = *itr;
            item->weight = 1;
            vec.push_back(item);
        }
        if(isRun) {
            for(auto itr = trueTypes.begin(); itr != trueTypes.end(); itr++) {
                auto item = new TypeWeight();
                item->typeName = itr->first;
                item->weight = itr->second;
                vec.push_back(item);
            }
        } else {
            for(auto itr = allSysCls.begin(); itr != allSysCls.end(); itr++) {
                auto item = new TypeWeight();
                item->typeName = (*itr)->name;
                item->weight = 1;
                vec.push_back(item);
            }
        }
    }
}

void Class_Handler::addCls(hygen::BaseClass *cls) {
    classMap[cls->name] = cls;
    OCClass * ocls = dynamic_cast<OCClass *>(cls);
    if(ocls) {
        ocCustomCls.push_back(cls->name);
    } else {
        CXXClass * cxx = dynamic_cast<CXXClass* >(cls);
        if(cxx) {
            cxxCustomCls.push_back(cls->name);
        }
    }
}

std::string Class_Handler::formatName(Context* context, std::string typeName) {
    replace_all_distinct(typeName, "*", "");
    replace_all_distinct(typeName, " ", "");
    BaseClass * c = classMap[typeName];
    if(c) {
        if(c->classType == OCClassType_Class) {
            return typeName + "*";
        } else {
            return typeName;
        }
    }
    return typeName;
}

int Class_Handler::supportMode() {
    return CodeMode_OC;
}

std::string Class_Handler::getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue) {
    BaseClass * c = classMap[var->typeName];
    if(c) {
        return c->genBool(context, var, isTrue);
    }
    return "";
}

void Class_Handler::removeAllCustomCls() {
    for(auto itr = ocCustomCls.begin(); itr != ocCustomCls.end(); itr++) {
        classMap.erase(*itr);
    }
    ocCustomCls.clear();
    for(auto itr = cxxCustomCls.begin(); itr != cxxCustomCls.end(); itr++) {
        classMap.erase(*itr);
    }
    cxxCustomCls.clear();
}





