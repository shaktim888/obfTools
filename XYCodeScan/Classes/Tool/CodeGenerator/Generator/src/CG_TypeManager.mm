//
//  CG_TypeManager.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#include "CG_TypeManager.hpp"
#import "UserConfig.h"
#include "NameGeneratorExtern.h"

namespace gen {

static char randomOneChar()
{
    switch (arc4random() % 3) {
        case 0:
            return char('a' + arc4random() % 26);
            break;
        case 1:
            return char('A' + arc4random() % 26);
            break;
        default:
            return char('0' + arc4random() % 10);
            break;
    }
}

HYClassInfo * TypeManager::genEmptyClass(int classType,const char *className) {
    if(classMap.find(className) != classMap.end()) {
        return classMap[className];
    }
    HYClassInfo * info = new HYClassInfo(classType, className);
    classMap[className] = info;
    return info;
}

HYClassInfo *TypeManager::findOneExistClass(int classType) {
    if(classMap.size() == 0) return nullptr;
    int totalWeight = 0;
    for(auto itr = classMap.begin(); itr != classMap.end(); itr++) {
        if(itr->second && itr->second->isCanCreate && itr->second->classType == classType) {
            totalWeight += itr->second->weight ;
        }
    }
    if(totalWeight > 0) {
        int index = arc4random() % totalWeight + 1;
        auto itr = classMap.begin();
        do{
            if(itr->second && itr->second->isCanCreate && itr->second->classType == classType) {
                index -= itr->second->weight;
            }
            if(index > 0) {
                itr++;
            } else {
                break;
            }
        } while(itr != classMap.end());
        if(itr != classMap.end() && itr->second) {
            if(curClass) {
                curClass->usedClass.insert(itr->second);
            }
            return itr->second;
        }
    }
    return nullptr;
}

const std::vector<int> TypeManager::getMethodTypes(int classType) {
    switch (classType) {
        case Class_OC:
        {
            static std::vector<int> oc_types = {
                Method_OC_Object,
                Method_OC_Static,
                Method_C_OC
            };
            return oc_types;
            break;
        }
        case Class_Cplus:
        {
            static std::vector<int> cplus_type = {
                Method_Cplus_Public,
                Method_Cplus_Protected,
                Method_Cplus_Private,
                Method_Cplus_Static,
                Method_C
            };
            return cplus_type;
            break;
        }
        case Class_Lua:
        {
            static std::vector<int> lua_types = {
                Method_Lua_Object,
            };
            return lua_types;
            break;
        }
        case Class_Js:
        {
            static std::vector<int> js_types = {
                Method_Js_Local,
                Method_Js_Object,
            };
            return js_types;
            break;
        }
        default:
        {
            static std::vector<int> c_types = {
                Method_C
            };
            return c_types;
            break;
        }
    }
}

const std::vector<int> TypeManager::getTypes(int classType) {
    switch (classType) {
        case Class_OC:
        {
            std::vector<int> oc_types = {
                C_int,
                C_float,
                C_double,
                C_char,
                C_int_ptr,
                C_float_ptr,
                C_double_ptr,
                Cplus_bool_ptr,
            };
            for(int i = 0 ; i < [UserConfig sharedInstance].stringWeight; i++) {
                oc_types.push_back(C_char_ptr);
            }
            for(int i = 0; i < [UserConfig sharedInstance].OCWeight; i++) {
                oc_types.push_back(Class_OC);
            }
            return oc_types;
            break;
        }
        case Class_Cplus:
        {
            std::vector<int> cplus_types = {
                C_int,
                C_float,
                C_double,
                C_char,
                C_int_ptr,
                C_float_ptr,
                C_double_ptr,
                Cplus_bool,
                Cplus_bool_ptr,
                Class_Cplus,
            };
            
            for(int i = 0 ; i < [UserConfig sharedInstance].stringWeight; i++) {
                cplus_types.push_back(C_char_ptr);
            }
            
            return cplus_types;
            break;
        }
        case Class_Lua:
        {
            static std::vector<int> lua_types = {
                Class_Lua,
                Lua_Table,
                Lua_Number,
                Lua_String,
//                Method_Lua_Local
            };
            return lua_types;
            break;
        }
        case Class_Js:
        {
            static std::vector<int> js_types = {
                Class_Js,
                Js_Number,
                Js_String,
                Js_Object,
            };
            return js_types;
            break;
        }
        default:
        {
            std::vector<int> c_types = {
                C_int,
                C_float,
                C_double,
                C_char,
                C_int_ptr,
                C_float_ptr,
                C_double_ptr,
            };
            
            for(int i = 0 ; i < [UserConfig sharedInstance].stringWeight; i++) {
                c_types.push_back(C_char_ptr);
            }
            return c_types;
            break;
        }
    }
}

int TypeManager::getEntityTypeByClassType(int classType) {
    switch (classType) {
        case Class_OC:
            return Class_OC;
            break;
        case Class_Cplus:
            return Class_Cplus;
            break;
        default:
            return Type_NULL;
            break;
    }
}

const std::vector<int>& TypeManager::getLogicTypes() {
    static std::vector<int> logicType = {
        Logic_VarOperation,
        Logic_CreateVar,
        Logic_CallExistFunc,
        Logic_CallExistFunc,
        Logic_IF,
        Logic_While,
        Logic_For,
    };
    return logicType;
}

int TypeManager::getClassTypeByMethodType(int methodType)
{
    int classType = Type_NULL;
    switch (methodType) {
        case Method_Cplus_Public:
        case Method_Cplus_Protected:
        case Method_Cplus_Private:
        case Method_Cplus_Constructor:
            classType = Class_Cplus;
            break;
        case Method_OC_Object:
        case Method_OC_Constructor:
        case Method_OC_Static:
        case Method_C_OC:
            classType = Class_OC;
            break;
        case Method_Lua_Local:
        case Method_Lua_Object:
            classType = Class_Lua;
            break;
        case Method_Js_Object:
        case Method_Js_Local:
            classType = Class_Js;
            break;
        default:
            classType = Type_NULL;
            break;
    }
    return classType;
}

std::string TypeManager::getTypeName(HYVarInfo * var) {
    if(!var) return "void";
    if(var->type->cls) {
        if(var->type->cls->classType == Class_Js) {
            return "var";
        }
        if(var->type->cls->classType == Class_Lua) {
            return "local";
        }
        return var->type->cls->name + " *";
    }
    return var->type->name;
}

std::string TypeManager::_genTypeValueByClass(int type, HYClassInfo * cls) {
    HYEntityType * defType = nullptr;
    if(typeMap.find(type) != typeMap.end()) {
        defType = typeMap[type];
    }
    if(defType && defType->genEntity) {
        return defType->genEntity();
    }
    if(cls) {
        if(curClass) {
            curClass->usedClass.insert(cls);
        }
        if(cls->genEntity) {
            return cls->genEntity();
        } else {
            switch (cls->classType) {
                case Class_OC:
                    return string("[[") + cls->name + " alloc] init]";
                    break;
                case Class_Cplus:
                    return string("new ") + cls->name + "()";
                    break;
                case Class_Js:
                    return string("new ") + cls->name + "()";
                    break;
                case Class_Lua:
                    return cls->name + ".new()";
                    break;
                default:
                    break;
            }
        }
    }
    return "0";
}

std::string TypeManager::genRandomString(bool isFileName) {
    string ret;
    if(isFileName)
    {
        ret += genNameForCplus(CResName, false);
        ret += (arc4random() % 2 ? ".png" : ".jpg");
    }
    else
    {
        int wordMin = MIN([UserConfig sharedInstance].stringWordMin, [UserConfig sharedInstance].stringWordMax);
        int wordMax = MAX([UserConfig sharedInstance].stringWordMin, [UserConfig sharedInstance].stringWordMax);
        int wordNum = wordMin;
        if(wordMax != wordMin) {
            wordNum += arc4random() % (wordMax - wordMin);
        }
        
        int k = 0;
        for(int i = 0; i < wordNum; i++) {
            ret += genNameForCplus(CWordName, false);
            k++;
            if( i < wordNum - 1) {
                if(k >= 3 && arc4random() % 100 <= k * 12) {
                    ret += ",";
                    k = 0;
                }
                ret += " ";
            }
        }
    }
    return ret;
}

std::string TypeManager::_genTypeValueByType(HYEntityType * type) {
    return _genTypeValueByClass(type->typeKey, type->cls);
}

std::string TypeManager::_genTypeValueByName(int type, const char * className) {
    HYClassInfo * cls = nullptr;
    if(className && classMap.find(className) != classMap.end()) {
        cls = classMap[className];
    }
    return _genTypeValueByClass(type, cls);
}

HYEntityType *TypeManager::getOrCreateType(int type, HYClassInfo * cls) {
    auto cache = typeMap[type];
    if(cache) return cache;
    if(!cls && (type == Class_OC || type == Class_Cplus)) {
        cls = findOneExistClass(type == Class_OC ? Class_OC : Class_Cplus);
    }
    return new HYEntityType(type, cls);
}


void TypeManager::buildDefaultClass() {
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSNumber");
        info->isSystem = true;
        info->weight = 2;
        info->genEntity = [](){
            return "@" + to_string(arc4random() % 100 + 1);
        };
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "intValue";
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "floatValue";
            method->retType = new HYVarInfo(getOrCreateType(C_float));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "boolValue";
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "doubleValue";
            method->retType = new HYVarInfo(getOrCreateType(C_double));
            info->methods.push_back(method);
        }
    }
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSString");
        info->isSystem = true;
        info->weight = 2;
        info->genEntity = [this](){
            return "@\"" + genRandomString((arc4random() % 100) <= 20) + "\"";
        };
//        {
//            auto method = new HYMethodInfo(Method_OC_Object);
//            method->parent = info;
//            method->name = "UTF8String";
//            method->retType = new HYVarInfo(getOrCreateType(C_char_ptr));
//            info->methods.push_back(method);
//        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "stringByAppendingString";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "stringByAppendingString";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "isEqualToString";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "isEqualToString";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "pathExtension";
            method->retType = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "length";
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "hasPrefix";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "hasPrefix";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "hasSuffix";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "hasSuffix";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
    }
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSArray");
        info->isSystem = true;
        info->genEntity = [=]() {
            string ret = std::string("@[");
            string types[] = {
                "NSNumber",
                "NSString"
            };
            string t = types[arc4random() % getArrSize(types)];
            for( int i = arc4random() % 5; i >= 0; i--) {
                if(i == 0) {
                    ret += _genTypeValueByName(Class_OC, t.c_str());
                } else {
                    ret += _genTypeValueByName(Class_OC, t.c_str()) + ",";
                }
            }
            ret += "]";
            return ret;
        };
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "indexOfObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "indexOfObject";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "containsObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "containsObject";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "count";
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
    }
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSMutableArray");
        info->isSystem = true;
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "indexOfObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "indexOfObject";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "containsObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "containsObject";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "count";
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "addObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "addObject";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "removeObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "removeObject";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "removeLastObject";
            info->methods.push_back(method);
        }
    }
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSDictionary");
        info->isSystem = true;
        info->genEntity = [=](){
            std::string ret = std::string("@{");
            string types[] = {
                "NSNumber",
                "NSString"
            };
            for( int i = arc4random() % 3; i >= 0; i--) {
                string& t = types[arc4random() % getArrSize(types)];
                if(i == 0) {
                    ret += string("@\"") + genNameForCplus(CVarName, false) + string("\" : ") + _genTypeValueByName(Class_OC, t.c_str());
                } else {
                    ret += string("@\"") + genNameForCplus(CVarName, false) + string("\" : ") + _genTypeValueByName(Class_OC, t.c_str()) + ", ";
                }
            }
            ret += "}";
            return ret;
        };
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "allKeys";
            method->retType = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSArray"]));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "allValues";
            method->retType = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSArray"]));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "count";
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "objectForKey";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "objectForKey";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
    }
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSMutableDictionary");
        info->isSystem = true;
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->name = "allKeys";
            method->retType = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSArray"]));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "allValues";
            method->retType = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSArray"]));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "count";
            method->retType = new HYVarInfo(getOrCreateType(C_int));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "objectForKey";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "objectForKey";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "removeAllObjects";
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "removeObjectForKey";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSNumber"]));
                arg->name = "removeObjectForKey";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "setObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSNumber"]));
                arg->name = "setObject";
                method->args.push_back(arg);
            }
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "forKey";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
    }
    {
        HYClassInfo * info = genEmptyClass(Class_OC, "NSMutableSet");
        info->isSystem = true;
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "containsObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "containsObject";
                method->args.push_back(arg);
            }
            method->retType = new HYVarInfo(getOrCreateType(Cplus_bool));
            info->methods.push_back(method);
        }
        {
            auto method = new HYMethodInfo(Method_OC_Object);
            method->parent = info;
            method->name = "addObject";
            {
                auto arg = new HYVarInfo(getOrCreateType(Class_OC, classMap["NSString"]));
                arg->name = "addObject";
                method->args.push_back(arg);
            }
            info->methods.push_back(method);
        }
    }
}

void TypeManager::buildDefaultTypes() {
    {
        HYEntityType * type = new HYEntityType(C_int);
        type->name = "int";
        type->genEntity = []() {
            return to_string(arc4random() % 100 + 1);
        };
        type->isCache = true;
        typeMap[C_int] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_float);
        type->name = "float";
        type->genEntity = []() {
            std::string ret = to_string(arc4random() % 1000);
            ret += "." + to_string(arc4random() % 100 + 1) + "f";
            return ret;
        };
        type->isCache = true;
        typeMap[C_float] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_double);
        type->name = "double";
        type->genEntity = []() {
            std::string ret = to_string(arc4random() % 1000);
            ret += "." + to_string(arc4random() % 100 + 1);
            return ret;
        };
        type->isCache = true;
        typeMap[C_double] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_char);
        type->name = "char";
        type->genEntity = []() {
            std::string ret = string("'");
            ret += randomOneChar();
            ret += "'";
            return ret;
        };
        type->isCache = true;
        typeMap[C_char] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_int_ptr);
        type->name = "int *";
        type->genEntity = [=]() {
            std::string ret = "(int[]){";
            for(int i = arc4random() % 5; i >= 0; i--) {
                if(i == 0){
                    ret += _genTypeValueByClass(C_int);
                } else {
                    ret += _genTypeValueByClass(C_int) + ", ";
                }
            }
            ret += "}";
            return ret;
        };
        type->isCache = true;
        typeMap[C_int_ptr] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_float_ptr);
        type->name = "float *";
        type->genEntity = [=]() {
            std::string ret = "(float[]){";
            for(int i = arc4random() % 5; i >= 0; i--) {
                if(i == 0){
                    ret += _genTypeValueByClass(C_float);
                } else {
                    ret += _genTypeValueByClass(C_float) + ", ";
                }
            }
            ret += "}";
            return ret;
        };
        type->isCache = true;
        typeMap[C_float_ptr] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_double_ptr);
        type->name = "double *";
        type->genEntity = [=]() {
            std::string ret = "(double[]){";
            for(int i = arc4random() % 5; i >= 0; i--) {
                if(i == 0){
                    ret += _genTypeValueByClass(C_double);
                } else {
                    ret += _genTypeValueByClass(C_double) + ", ";
                }
            }
            ret += "}";
            return ret;
        };
        type->isCache = true;
        typeMap[C_double_ptr] = type;
    }
    {
        HYEntityType * type = new HYEntityType(C_char_ptr);
        type->name = "char *";
        type->genEntity = [=]() {
            return "\"" + genRandomString((arc4random() % 100) <= 20) + "\"";
        };
        type->isCache = true;
        typeMap[C_char_ptr] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Cplus_bool);
        type->name = "bool";
        type->genEntity = [=]() {
            return (arc4random() % 2 == 0) ? "true" : "false";
        };
        type->isCache = true;
        typeMap[Cplus_bool] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Cplus_bool_ptr);
        type->name = "bool *";
        type->genEntity = [=]() {
            std::string ret = "(bool[]){";
            for(int i = arc4random() % 5; i >= 0; i--) {
                if(i == 0){
                    ret += _genTypeValueByClass(Cplus_bool);
                } else {
                    ret += _genTypeValueByClass(Cplus_bool) + ", ";
                }
            }
            ret += "}";
            return ret;
        };
        type->isCache = true;
        typeMap[Cplus_bool_ptr] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Lua_Number);
        type->name = "local";
        type->genEntity = [=]() {
            return to_string(arc4random() % 100);
        };
        type->isCache = true;
        typeMap[Lua_Number] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Lua_String);
        type->name = "local";
        type->genEntity = [=]() {
            std::string ret = "\"";
            for(int i = arc4random() % 5; i > 0; i--) {
                ret += randomOneChar();
            }
            ret += "\"";
            return ret;
        };
        type->isCache = true;
        typeMap[Lua_String] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Lua_Table);
        type->name = "local";
        type->genEntity = [=]() {
            return "{}";
        };
        type->isCache = true;
        typeMap[Lua_Table] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Js_Number);
        type->name = "var";
        type->genEntity = [=]() {
            return to_string(arc4random() % 100);
        };
        type->isCache = true;
        typeMap[Js_Number] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Js_String);
        type->name = "var";
        type->genEntity = [=]() {
            std::string ret = "\"";
            for(int i = arc4random() % 5; i > 0; i--) {
                ret += randomOneChar();
            }
            ret += "\"";
            return ret;
        };
        type->isCache = true;
        typeMap[Js_String] = type;
    }
    {
        HYEntityType * type = new HYEntityType(Js_Object);
        type->name = "var";
        type->genEntity = [=]() {
            return "{}";
        };
        type->isCache = true;
        typeMap[Js_Object] = type;
    }
}
}
