//
//  AllTypeManager.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "GAllTypeManager.hpp"
#include "GOCClassInfo.hpp"
#include "GRuntimeContext.hpp"
#include "GEnumInfo.hpp"
#include "GCommanFunc.hpp"
#include "GPropInfo.hpp"
#include "GParamInfo.hpp"

namespace ocgen {
using namespace std;

static BaseType* genTypeByFile(ifstream& file) {
    BaseType * t = nullptr;
    string s;
    B_Type b_type;
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
            case B_Enum:
                t = new EnumInfo();
                break;
            default:
                t = new OCClassInfo();
                break;
        }
        t->b_type = b_type;
        t->name = types[2];
        t->libName = tokens[1];
    }
    while(getline(file,s))
    {
        if(s!="") t->initByOneLine(s);
    }
    return t;
}


static InterfaceType * getInterfaceByFile(ifstream & file) {
    InterfaceType * inter = new InterfaceType();
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
            MethodInfo * method = new MethodInfo();
            method->methodType = B_EMethod_NONE;
            {
                std::regex reg("[+-]\\s*\\(([\\w]*)\\)\\s*(\\w+)");
                std::cmatch m;
                auto ret = std::regex_search(s.c_str(), m, reg);
                if (ret)
                {
                    method->declare = s;
                    method->retType = normalizeType(m[1]);
                    method->name = m[2];
                }
            }
            {
                std::smatch m;
                std::regex reg("(\\w+)\\s*\\:\\(([\\w* <>]*)\\)\\s*(\\w+)");
                string::const_iterator start = s.begin();
                string::const_iterator end = s.end();
                while (std::regex_search(start, end, m, reg))
                {
                    ParamInfo * parm = new ParamInfo();
                    parm->name = m[1];
                    parm->type = normalizeType(m[2]);
                    parm->var = m[3];
                    method->params.push_back(parm);
                    start = m[0].second;    //更新搜索起始位置,搜索剩下的字符串
                }
               
            }
            inter->methods.push_back(method);
        }
    }
    return inter;
}


void AllTypeManager::loadAllInterface() {
    interfaceTotalWeight = 0;
    NSString * folder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"File/cm/interface/"];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:folder];
    for (NSString *subpath in subpaths) {
        if ([subpath hasSuffix:@".cm"]) {
            ifstream infile;
            infile.open([[folder stringByAppendingPathComponent:subpath] UTF8String]);
            if(infile.is_open()) {
                InterfaceType* type = getInterfaceByFile(infile);
               if(type) {
                   interfaceArr.push_back(type);
                   interfaceTotalWeight += type->weight;
               }
               infile.close();
           }
       }
    }
}

void AllTypeManager::loadAllType()
{
    NSString * folder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"File/cm/type/"];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:folder];
    for (NSString *subpath in subpaths) {
        if ([subpath hasSuffix:@".cm"]) {
            ifstream infile;
            infile.open([[folder stringByAppendingPathComponent:subpath] UTF8String]);
            if(infile.is_open()) {
                BaseType* type = genTypeByFile(infile);
                    if(type) {
                        classMap[type->name] = type;
                        if(type->b_type == B_Type::B_Class) {
                            allCls.push_back(dynamic_cast<OCClassInfo*>(type));
                        }
                    }
                infile.close();
            }
      }
   }
}

InterfaceType * AllTypeManager::randomAInterface() {
    int weight = arc4random() % interfaceTotalWeight;
    for(auto itr = interfaceArr.begin(); itr != interfaceArr.end(); itr++) {
        if(weight < (*itr)->weight) {
            return *itr;
        }
        weight -= (*itr)->weight;
    }
    return nullptr;
}

AllTypeManager::AllTypeManager() {
    loadAllType();
    loadAllInterface();
}

AllTypeManager* AllTypeManager::getInstance() {
    static AllTypeManager* ins = nullptr;
    if(!ins){
        ins = new AllTypeManager();
    }
    return ins;
}


std::string& AllTypeManager::randomAType(RuntimeContext * context, int commonWeight) {
    static vector<std::string> baseTypes = {
        "int", "float", "bool", "NSString"
    };
    if((arc4random() % 100) < commonWeight) {
        return baseTypes[arc4random() % baseTypes.size()];
    }
    int index = arc4random() % (allCls.size() + customCls.size());
    OCClassInfo * randomClass;
    if(index < allCls.size()) {
        randomClass = allCls[index];
    } else {
        randomClass = customCls[index - allCls.size()];
    }
    if(context && context->cls) {
        context->cls->addDep(context, randomClass->name);
    }
    return randomClass->name;
}

bool AllTypeManager::isCanOpType(std::string& type) {
    if(getType(type)) {
        return true;
    }
    static vector<std::string> baseTypes = {
        "int", "float", "bool", "CGFloat", "id"
    };
    for(auto itr = baseTypes.begin(); itr != baseTypes.end(); itr++) {
        if(type.find(*itr) == 0) {
            return true;
        }
    }
    return false;
}

bool AllTypeManager::isNumType(std::string& type) {
    if(!isCanOpType(type)) {
        return false;
    }
    static vector<std::string> baseTypes = {
        "int", "float", "CGFloat"
    };
    for(auto itr = baseTypes.begin(); itr != baseTypes.end(); itr++) {
        if(type.find(*itr) == 0) {
            return true;
        }
    }
    return false;
}

BaseType * AllTypeManager::getType(std::string tname) {
    replace_all_distinct(tname, "*", "");
    replace_all_distinct(tname, " ", "");
    if(classMap.find(tname) != classMap.end()) {
        return classMap[tname];
    }
    if(tname == "id") {
        int index = arc4random() % (allCls.size() + customCls.size());
        OCClassInfo * randomClass;
        if(index < allCls.size()) {
            randomClass = allCls[index];
        } else {
            randomClass = customCls[index - allCls.size()];
        }
        return randomClass;
    }
    return nullptr;
}

void AllTypeManager::addCustomType(BaseType * cls) {
    classMap[cls->name] = cls;
    customCls.push_back(dynamic_cast<OCClassInfo *>(cls));
}

void AllTypeManager::clearAllCustomType() {
    for(auto itr = customCls.begin(); itr != customCls.end(); itr++) {
        classMap.erase((*itr)->name);
    }
    customCls.clear();
}

std::string AllTypeManager::formatType(std::string& tname) {
    BaseType* t = getType(tname);
    if(t && t->b_type == B_Class) {
        return tname + "* ";
    }
    vector<string> words;
    split(tname, words, "-");
    if(words[0] == "string") {
        return "char *";
    }
    return words[0] + " ";
}

}

