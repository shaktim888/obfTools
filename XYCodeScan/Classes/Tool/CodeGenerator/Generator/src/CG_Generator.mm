//
//  CG_Generator.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#include "CG_Generator.hpp"
#include "CG_ClassInfo.hpp"
#include "CG_MethodInfo.hpp"
#import "UserConfig.h"
#include "NameGeneratorExtern.h"
#include "CG_Context.hpp"
#include "CG_TypeManager.hpp"

namespace gen {

static void reviewAllCalled(HYMethodInfo * method, std::set<HYMethodInfo *> &record) {
    if(method->called.size() > 0)
    {
        for(auto iter = method->called.begin(); iter != method->called.end() ; ++iter)
        {
            auto m = *iter;
            if(m && record.count(m) == 0) {
                record.insert(m);
                reviewAllCalled(m, record);
            }
        }
    }
}

static bool mySortFunction(HYMethodInfo* i, HYMethodInfo* j) {
    return i->methodType > j->methodType;
}

void CodeGenerator::removeMethod(HYMethodInfo * method)
{
    if(method->parent)
    {
        for(auto itr = method->parent->methods.begin(); itr != method->parent->methods.end(); itr++) {
            if(*itr == method) {
                method->parent->methods.erase(itr);
                break;
            }
        }
    } else {
        for(auto itr = localMethods.begin(); itr != localMethods.end(); itr++) {
            if(*itr == method) {
                localMethods.erase(itr);
                break;
            }
        }
    }
}

HYVarInfo *CodeGenerator::genVarDeclare(int type, bool isArg, int classType) {
    // todo:
    if(classType != Type_NULL) {
        auto types = manager->getTypes(classType);
        type = types[arc4random() % types.size()];
    }
    if(type == Type_NULL) {
        auto types = manager->getTypes(Type_NULL);
        type = types[arc4random() % types.size()];
    }
    HYClassInfo * cls = nullptr;
    if(type == Class_OC || type == Class_Cplus || type == Class_Js || type == Class_Lua) {
        cls = manager->findOneExistClass(type);
        if(!cls) {
            if(type == Class_OC || type == Class_Cplus)
                type = C_char_ptr;
            else if(type == Class_Lua)
                type = Lua_String;
            else
                type = Js_String;
        }
    }
    auto typestruct = manager->getOrCreateType(type, cls);
    HYVarInfo * info = new HYVarInfo(typestruct);
    info->name = genNameForCplus(isArg ? CArgName : CVarName, true);
    info->val = manager->_genTypeValueByType(typestruct);
    return info;
}


HYClassInfo *CodeGenerator::genClass(int classType) {
    genNameClearCache(CFuncName);
    HYClassInfo * info = new HYClassInfo(classType, genNameForCplus(CTypeName, true));
    manager->curClass = info;
    // 1. 添加自己的属性;
    int propNum = arc4random() % 4 + 2;
    for(int i = 0; i <= propNum; i++) {
        auto m = genVarDeclare(Type_NULL,false, classType);
        if(m->type->cls && m->type->cls->constructor)
        {
            // 防止循环创建
            std::set<HYMethodInfo *> called;
            reviewAllCalled(m->type->cls->constructor, called);
            if(called.count(info->constructor)) {
                i--;
                continue;
            }
            info->usedClass.insert(m->type->cls);
        }
        info->members.push_back(m);
    }
    // 2. 添加一些函数
    int funcNum = arc4random() % 4 + 3;
    auto methodTypes = manager->getMethodTypes(classType);
    for(int i = 0;i <= funcNum; i++) {
        auto method = genMethodDeclare(info, methodTypes[arc4random() % methodTypes.size()]);
        if(method->isObject) {
            info->methods.push_back(method);
        } else {
            localMethods.push_back(method);
        }
    }
    sort(info->methods.begin(), info->methods.end(), mySortFunction);

    // 生成构造函数
    HYMethodInfo * constructor = genConstructorMethod(info);
    if(constructor) {
        info->constructor = constructor;
        for(auto itr = info->usedClass.begin(); itr != info->usedClass.end(); itr++) {
            HYClassInfo * c = *itr;
            if(c->constructor) {
                info->constructor->called.insert((*itr)->constructor);
            }
        }
    }
    manager->classMap[info->name] = info;
    return info;
}

void CodeGenerator::buildClass(HYClassInfo * info) {
    std::cout<< "正在生成类：" << info->name << std::endl;
    clearGlobalMethod();
    manager->curClass = info;
    auto count = info->methods.size();
    for (int i = 0; i < count;i++) {
        buildMethod(info->methods[i]);
    }
    if(info->constructor) {
        buildMethod(info->constructor);
    }
    buildClassBody(info);
}

HYMethodInfo *CodeGenerator::genMethodDeclare(HYClassInfo * parent, int methodType) {
    genNameClearCache(CArgName);
    genNameClearCache(CVarName);
    int classType = parent ? parent->classType : manager->getClassTypeByMethodType(methodType);
    HYMethodInfo * method = new HYMethodInfo(methodType);
    if(methodType == Method_OC_Constructor || methodType == Method_Cplus_Constructor) {
        method->name = parent->name;
    }
    else
    {
        method->name = genNameForCplus(CFuncName, true);
        // 生成参数
        int argNum = arc4random() % 3;
        for( int i =0 ; i< argNum;i++) {
            method->args.push_back(genVarDeclare(Type_NULL, true, classType));
        }
        auto types = manager->getTypes(classType);
        if(arc4random() % (types.size() + 1) == 0) {
            method->retType = nullptr;
        } else {
            method->retType = genVarDeclare(Type_NULL, false, classType);
        }
    }
    method->parent = parent;
    
    return method;
}

std::string CodeGenerator::genMethodBodyStr(HYMethodInfo * method, int deep, int lines) {
    if(method->methodType == Method_OC_Constructor || method->methodType == Method_Cplus_Constructor) {
        return genInitAllMembers(method->parent, deep);
    } else {
        if(lines == 0) {
            lines =arc4random() % 5 + 5;
        }
        std::vector<HYVarInfo *> allVaribles;
        auto count = method->args.size();
        for(int i = 0; i< count; i++) {
            allVaribles.push_back(method->args[i]->clone());
        }
        if(method->methodType == Method_OC_Object ||
           method->methodType == Method_Cplus_Public ||
           method->methodType == Method_Cplus_Private ||
           method->methodType == Method_Cplus_Protected){
            for(int i = 0; i < method->parent->members.size(); i++) {
                allVaribles.push_back( method->parent->members[i]->clone() );
            }
        }
        std::string body = "";
        genNameClearCache(CVarName);
//        std::string body = getGapByOffset(1) + "asm (\"\");\n";
        while(lines > 0) {
            body += genBlockCode(method, deep, allVaribles, lines);
        }
        body += decideBlockEnd(body) + genMethodRetCode(deep, method, allVaribles);
        // 要释放后续创建的变量
        for(int i = 0; i < allVaribles.size(); i++) {
            delete allVaribles[i];
        }
        return body;
    }
}



std::string CodeGenerator::getGapByOffset(int offset) {
    string ret = "";
    for(int i = 0; i < offset; i++) {
        ret += "    ";
    }
    return ret;
}

std::string CodeGenerator::genMethodRetCode(int deep, HYMethodInfo * method, std::vector<HYVarInfo *>& vars)
{
    if(method->retType ) {
        auto var = selectVar(vars, method->retType->type);
        
        string ret = "";
        if(var) {
            ret += getGapByOffset(deep) + "return " + var->name + ";";
        } else {
            if(method->retType->type->cls) {
                HYVarInfo * var = new HYVarInfo(manager->getOrCreateType(method->retType->type->typeKey, method->retType->type->cls));
                var->name = genNameForCplus(CVarName, true);
                var->val = manager->_genTypeValueByType(method->retType->type);
                ret += getGapByOffset(deep) + genVarDeclareStr(var) + "\n";
                ret += getGapByOffset(deep) + "return " + var->name + ";";
                delete var;
            } else {
                auto val = getGapByOffset(deep) + "return " + manager->_genTypeValueByType(method->retType->type);
                ret += val + ";";
            }
        }
        return ret;
    }
    return "";
}

std::string CodeGenerator::genBlockCode( HYMethodInfo * method, int offset, std::vector<HYVarInfo *>& vars, int& lines) {
    auto storeLen = vars.size();
    string ret = "";
//    std::cout << lines << std::endl;
//    if( lines <= 0 && method->retType ) {
//        if(offset <= 1) {
//            lines--;
//            ret = getGapByOffset(offset) + decideReturnValue(NULL, method, vars);
//        }
//    } else {
    lines--;
    HYCodeBlock * block = nullptr;
    
    if(lines < 0){
        block = genCodeByType(method, vars, lines, Logic_VarOperation);
        addBlockCode(offset, ret, block);
    } else {
        const std::vector<int>& logicTypes = manager->getLogicTypes();
        auto len = logicTypes.size();
        int rd = arc4random() % logicTypes[len - 1];
        for(int i = 0; i < len; i++) {
            if(rd < logicTypes[i]) {
                // 最顶层不让return
                //            if(len > 1 && offset == 1 && logicTypes[i] == Logic_RETURN) {
                //                i = (i + (arc4random() % (len - 1)) + 1) % len;
                //            }
                //                std::cout << "type:" << i << endl;
                block = genCodeByType(method, vars, lines, logicTypes[i]);
                addBlockCode(offset, ret, block);
                break;
            }
        }
    }
    if(block && block->needRevert)
    {
        while(vars.size() > storeLen) {
            auto var = vars.back();
            vars.pop_back();
            delete var;
        }
        delete block;
    }
//        if( offset == 1 && lines <= 0 && method->retType ) {
//            ret += getGapByOffset(offset) + decideReturnValue(block, method, vars);
//        }
//    }
    return ret;
}


HYCodeBlock* CodeGenerator::genCodeByType(HYMethodInfo * fromMethod, std::vector<HYVarInfo *>& vars, int& lines, int type) {
    HYCodeBlock * block = nullptr;
    auto len = vars.size();
    switch (type) {
        case Logic_VarOperation:
        {
            if(vars.size() > 0) {
                int pos = arc4random() % len;
                auto var = vars[pos];
                auto cinfo = var->type->cls;
                if(cinfo) {
                    auto rmethod = findMethodWithReturnType(true, cinfo->methods, nullptr, fromMethod);
                    if(rmethod) {
                        block = new HYCodeBlock();
                        bool isCreateVar = rmethod->retType && arc4random() % 2 == 1;
                        if(isCreateVar)
                        {
                            auto genVar = new HYVarInfo(manager->getOrCreateType(rmethod->retType->type->typeKey, rmethod->retType->type->cls));
                            genVar->name = genNameForCplus(CVarName, true);
                            genVar->val = genCallBody(block, fromMethod, rmethod, vars, var);
                            block->body = genVarDeclareStr(genVar);
                            vars.push_back(genVar);
                        } else {
                            block->body = genCallBody(block, fromMethod, rmethod, vars, var) + ";";
                        }
                    }
                } else {
                    block = operatorVar(fromMethod, var, vars);
                    if(block && block->body != "") {
                        block->body = block->body;
                    }
                }
                
            } else {
                block = genCodeByType(fromMethod, vars, lines, Logic_CreateVar);
            }
            break;
        }
        case Logic_CreateVar:
        {
            block = new HYCodeBlock();
            auto var = genVarDeclare(Type_NULL, false, fromMethod->parent ? fromMethod->parent->classType : Type_NULL);
            var->val = decideTypeValue(nullptr, fromMethod, var->type, vars);
            vars.push_back(var);
            block->body = genVarDeclareStr(var);
            break;
        }
        case Logic_CallExistFunc:
        {
            HYMethodInfo * callm = nullptr;
            if(fromMethod->parent) {
                if(fromMethod->parent->methods.size() > 1) {
                    callm = findMethodWithReturnType(true, fromMethod->parent->methods, nullptr, fromMethod);
                }
            }
            if(!callm && localMethods.size() > 0) {
                callm = findMethodWithReturnType(false, localMethods, nullptr, fromMethod);
            }
            if(callm) {
                block = new HYCodeBlock();
                block->body = genCallBody(block, fromMethod, callm, vars) + ";";
            } else {
                block = genCodeByType(fromMethod, vars, lines, Logic_VarOperation);
            }
            break;
        }
        case Logic_IF:
        {
            block = genIfBlock(fromMethod, vars);
            if(block) {
                block->needRevert = true;
                int rd = arc4random() % 3 + 3;
                int record = vars.size();
                while(rd > 0) {
                    string code = genBlockCode(fromMethod, 1, vars, lines);
                    if(code == "") break;
                    block->beforeBody += code + decideBlockEnd(code);
                    rd--;
                }
                while(record < vars.size()) {
                    auto t = vars.back();
                    delete t;
                    vars.pop_back();
                }
                rd = arc4random() % 3 + 3;
                while(rd > 0) {
                    string code = genBlockCode(fromMethod, 1, vars, lines);
                    if(code == "") break;
                    block->afterBody += code + decideBlockEnd(code);
                    rd--;
                }
            }
            break;
        }
        case Logic_While:
        {
            block = genWhileBlock(fromMethod, vars);
            if(block) {
                block->needRevert = true;
                int rd = arc4random() % 3 + 1;
                while(rd > 0) {
                    string code = genBlockCode(fromMethod, 1, vars, lines);
                    if(code == "") break;
                    block->body += code + decideBlockEnd(code);
                    rd--;
                }
            }
            break;
        }
        case Logic_For:
        {
            block = genForBlock(fromMethod, vars);
            if(block) {
                block->needRevert = true;
                int rd = arc4random() % 3 + 1;
                while(rd > 0) {
                    string code = genBlockCode(fromMethod, 1, vars, lines);
                    if(code == "") break;
                    block->body += code;
                    rd--;
                }
            }
            break;
        }
//        case Logic_RETURN:
//        {
//            block = new HYCodeBlock();
//            block->body = decideReturnValue(block, fromMethod, vars);
//            break;
//        }
        default:
            break;
    }
    return block;
    
}

std::string CodeGenerator::genVarDeclareStr(HYVarInfo *var) {
    string ret = "";
    ret += manager->getTypeName(var) + " ";
    ret += var->name + " = " + var->val + ";";
    return ret;
}

std::string CodeGenerator::setVarValueStr(HYVarInfo * var) {
    string ret = "";
    ret += var->name + " = " + var->val + ";";
    return ret;
}
//
//std::string CodeGenerator::decideReturnValue(HYCodeBlock * block, HYMethodInfo *method, std::vector<HYVarInfo *> &vars) {
//    if(method->retType ) {
//        auto var = selectVar(vars, method->retType->type);
//        return genReturnStr(var, method->retType->type);
//    }
//    return "return;";
//}

std::string CodeGenerator::decideConditionStr(HYCodeBlock * block, HYMethodInfo * fromMethod, std::vector<HYVarInfo *> &vars) {
    if(vars.size() > 0){
        int pos = arc4random() % vars.size();
        static std::vector<string> boolOp = {
            "&&" , "||"
        };
        int count = arc4random() % 1 + 1;
        string ret = "";
        for(int i = 0; i < count; i++){
            if(i == 0) {
                ret += _genConditionStr(block, fromMethod, vars[pos], vars);
            } else {
                ret += string(" ") + boolOp[arc4random() % boolOp.size()] + " " + _genConditionStr(block, fromMethod, vars[pos], vars);
            }
        }
        if(ret == "")
        {
            // 在lua和oc中可以通过变量来判断
            if(fromMethod && vars.size() > 0) {
                int classType = manager->getClassTypeByMethodType(fromMethod->methodType);
                if(classType == Class_OC || classType == Class_Lua) {
                    auto select = vars[arc4random() % vars.size()];
                    return select->name;
                }
            }
            return "1";
        }
        return ret;
    } else {
        return "1";
    }
}

HYVarInfo *CodeGenerator::selectVar(std::vector<HYVarInfo *> &vars, HYEntityType *type, bool mustSelect, HYVarInfo *skipVar) {
    std::vector<HYEntityType*> types = { type };
    return selectVar(vars, types, mustSelect, skipVar);
}

HYVarInfo *CodeGenerator::selectVar(std::vector<HYVarInfo *>& vars, std::vector<HYEntityType*>& types, bool mustSelect, HYVarInfo * skipVar) {
    if(!mustSelect) {
        if(arc4random() % 100 < 10) {
            return nullptr;
        }
    }
    auto len = vars.size();
    if(len > 0) {
        int pos = arc4random() % len;
        for(int i = 0; i < len; i ++) {
            if(!skipVar || vars[pos] != skipVar) {
                for(int i = 0; i < types.size(); i++) {
                    HYEntityType * info = types[i];
                    if(info->isEqual(vars[pos]->type)) {
                        return vars[pos];
                    }
                }
            }
            pos = (pos + 1) % len;
        }
    }
    return nullptr;
}

std::string CodeGenerator::genCallBody(HYCodeBlock * block, HYMethodInfo* fromMethod, HYMethodInfo *method, std::vector<HYVarInfo *> &vars, HYVarInfo * runVar) {
    if(fromMethod) {
        fromMethod->called.insert(method);
    }
    string ret = "";
    switch (method->methodType) {
        case Method_C:
        case Method_C_OC:
        {
            ret = method->name + "(";
            int argsNum = (int)method->args.size();
            for(int i = 0; i < argsNum; i++) {
                ret += (i != 0 ? "," : "") + decideTypeValue(block, method, method->args[i]->type, vars);
            }
            ret += ")";
            break;
        }
        case Method_OC_Static:
        {
            // [AA funcName:a0 a1:v1 a2:v2];
            ret = "[";
            ret += method->parent->name;
            ret += string(" ") + method->name;
            for(int i = 0; i < method->args.size(); i++) {
                string val = decideTypeValue(block, fromMethod, method->args[i]->type, vars);
                if(i == 0){
                    ret += string(":") + val;
                } else {
                    ret +=std::string(" ") + method->args[i]->name + ":" + val;
                }
            }
            ret += "]";
            break;
        }
        case Method_OC_Object:
        {
            // [self funcName:a0 a1:v1];
            ret = "[";
            ret += (runVar ? runVar->name : "self");
            ret += string(" ") + method->name;
            for(int i = 0; i < method->args.size(); i++) {
                string val = decideTypeValue(block, fromMethod, method->args[i]->type, vars);
                if(i == 0){
                    ret += string(":") + val;
                } else {
                    ret +=std::string(" ") + method->args[i]->name + ":" + val;
                }
            }
            ret += "]";
            break;
        }
        case Method_Cplus_Public: case Method_Cplus_Protected: case Method_Cplus_Private:
        {
            // this.funcName(v1, v2, ....)
            ret = runVar ? runVar->name + "->" : "this->";
            ret += method->name + "(";
            int argsNum = (int)method->args.size();
            for(int i = 0; i < argsNum; i++) {
                ret += string(i == 0 ? "" : ",") + decideTypeValue(block, fromMethod, method->args[i]->type, vars);
            }
            ret += ")";
            break;
        }
        case Method_Cplus_Static:
        {
            // class::func(v1,v2)
            ret = method->parent->name + "::" + method->name + "(";
            int argsNum = (int)method->args.size();
            for(int i = 0; i < argsNum; i++) {
                ret += string(i == 0 ? "" : ",") + decideTypeValue(block, fromMethod, method->args[i]->type, vars);
            }
            ret += ")";
            break;

            break;
        }
        case Method_Lua_Local:
        case Method_Lua_Object:
        {
            if(method->methodType == Method_Lua_Object) {
                ret = runVar ? runVar->name + ":" : "self:";
            } else {
                ret = "";
            }
            ret += method->name + "(";
            int argsNum = (int)method->args.size();
            for(int i = 0; i < argsNum; i++) {
                ret += string(i == 0 ? "" : ",") + decideTypeValue(block, fromMethod, method->args[i]->type, vars);
            }
            ret += ")";
            break;
        }
        case Method_Js_Local:
        case Method_Js_Object:
        {
            if(method->methodType == Method_Js_Object) {
                ret = runVar ? runVar->name + "." : "this.";
            } else {
                ret = "";
            }
            ret += method->name + "(";
            int argsNum = (int)method->args.size();
            for(int i = 0; i < argsNum; i++) {
                ret += string(i == 0 ? "" : ",") + decideTypeValue(block, fromMethod, method->args[i]->type, vars);
            }
            ret += ")";
            break;
        }
        default:
            break;
    }
    
    return ret;
}

int CodeGenerator::getConstructorType(int classType) {
    switch (classType) {
        case Class_OC:
            return Method_OC_Constructor;
            break;
        case Class_Cplus:
            return Method_Cplus_Constructor;
            break;
        default:
            break;
    }
    return Method_None;
}

HYMethodInfo *CodeGenerator::genConstructorMethod(HYClassInfo *c) {
    int t = getConstructorType(c->classType);
    if(t != Method_None) {
        auto info = genMethodDeclare(c, t);
        return info;
    }
    return nullptr;
}

std::string CodeGenerator::genInitAllMembers(HYClassInfo * info, int deep) {
    string ret = "";
    for(int i = 0; i < info->members.size(); i++) {
        auto m = info->members[i];
        ret += getGapByOffset(deep) + setVarValueStr(m);
        ret += decideBlockEnd(ret);
    }
    return ret;
}

std::string CodeGenerator::_genConditionStr(HYCodeBlock * block, HYMethodInfo * fromMethod, HYVarInfo *var, std::vector<HYVarInfo *> &vars) {
    static std::vector<string> numOp = {
        "==", "!=", ">=", ">", "<=", "<"
    };
    static std::vector<string> luaNumComp = {
        "==", "~=", ">=", ">", "<=", "<"
    };
    static std::vector<string> luaStrComp = {
        "==", "~="
    };
    static std::vector<string> jsStrComp = {
        "==", "!="
    };
    switch (var->type->typeKey) {
        case C_int : case C_float: case C_double: case C_char: case Js_Number:
        {
            return var->name + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, var->type, vars, var);
            break;
        }
        case Cplus_bool:
        {
            return var->name + std::string(arc4random() % 2 ? "==" : "!=") + decideTypeValue(block, fromMethod, var->type, vars);
            break;
        }
        case Class_Cplus: case Class_OC:
        {
            HYClassInfo * cinfo = var->type->cls;
            if(cinfo) {
                if(arc4random() % 100 <= 20) {
                    auto method = findMethodWithReturnType(true, cinfo->methods, manager->typeMap[C_int], fromMethod);
                    if(method) {
                        return genCallBody(block, fromMethod, method, vars, var) + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[C_int], vars, var);
                    }
                }
                auto method = findMethodWithReturnType(true, cinfo->methods, manager->typeMap[Cplus_bool], fromMethod);
                if(method) {
                    return genCallBody(block, fromMethod, method, vars, var);
                } else {
                    return "true";
                }
            }
            break;
        }
        case Cplus_bool_ptr:
        {
            return std::string(arc4random() % 2 ? "!" : "") + var->name + "[0]" + std::string(arc4random() % 2 ? "==" : "!=") + decideTypeValue(block, fromMethod, manager->typeMap[Cplus_bool], vars, var);
            break;
        }
        case C_int_ptr: case C_double_ptr: case C_float_ptr:
        {
            int t = 0;
            if(var->type->typeKey == C_int_ptr) t = C_int;
            else if(var->type->typeKey == C_double_ptr) t = C_double;
            else if(var->type->typeKey == C_float_ptr) t = C_float;
            return var->name + "[0]" + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[t], vars, var);
            break;
        }
        case C_char_ptr:
        {
//            int rd = arc4random() % 2;
//            switch (rd) {
//                case 1:
//                {
//                    return string("strlen(") + var->name + ")" + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod,  typeMap[C_int], vars, var);
//                    break;
//                }
//                default:
//                {
            return var->name + "[0]" + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[C_char], vars, var);
//                    break;
//                }
//            }
            break;
        }
        case Lua_Number: {
            return var->name + luaNumComp[arc4random() % luaNumComp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[Lua_Number], vars, var);
            break;
        }
        case Lua_String: {
            int rd = arc4random() % 2;
            switch (rd) {
                case 1:
                {
                    return string("#") + var->name + luaNumComp[arc4random() % luaNumComp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[Lua_Number], vars, var);
                    break;
                }
                default:
                {
                    std::vector<HYEntityType *> types = {manager->typeMap[Lua_Number] , manager->typeMap[Lua_String]};
                    return var->name + luaStrComp[arc4random() % luaStrComp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[Lua_String], types, vars, var);
                    break;
                }
            }
            break;
        }
        case Js_String:
        {
            int rd = arc4random() % 2;
            switch (rd) {
                case 1:
                {
                    return var->name + ".length " + numOp[arc4random() % luaNumComp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[Js_Number], vars, var);
                    break;
                }
                default:
                {
                    std::vector<HYEntityType *> types = {manager->typeMap[Js_Number] , manager->typeMap[Js_String]};
                    return var->name + jsStrComp[arc4random() % jsStrComp.size()] + decideTypeValue(block, fromMethod, manager->typeMap[Js_String], types, vars, var);
                    break;
                }
            }
            break;
        }
        default:
            break;
    }
    return "";
}

HYCodeBlock *CodeGenerator::genIfBlock(HYMethodInfo * method, std::vector<HYVarInfo *> &vars) {
    auto block = new HYCodeBlock();
    switch (method->methodType) {
        case Method_Lua_Local: case Method_Lua_Object:
        {
            block->start = string("if (") + decideConditionStr(block, method, vars) + ") then";
            block->body = "else";
            block->end = "end";
            break;
        }
        default:
        {
            block->start = string("if(") + decideConditionStr(block, method, vars) + ") {";
            block->body = "} else {";
            block->end = "}";
            break;
        }
    }
    return block;
}

HYCodeBlock *CodeGenerator::genForBlock(HYMethodInfo *method, std::vector<HYVarInfo *> &vars) {
    auto block = new HYCodeBlock();
    string itrName = genNameForCplus(CVarName, true);
    HYVarInfo * itr = new HYVarInfo(nullptr);
    itr->name = itrName;
    switch (method->methodType) {
        case Method_Lua_Local: case Method_Lua_Object:
        {
            itr->type = manager->getOrCreateType(Lua_Number);
            itr->val = manager->_genTypeValueByClass(Lua_Number);
            int s = arc4random() % 100;
            int e = s + arc4random() % 5;
            block->start = string("for ") + itr->name + " = " + to_string(s) + ", " + to_string(e) + " do";
            block->afterBody = getGapByOffset(1) + "do break end";
            block->end = "end";
            vars.push_back(itr);
            break;
        }
        case Method_Js_Local: case Method_Js_Object:
        {
            itr->type = manager->getOrCreateType(Js_Number);
            itr->val = manager->_genTypeValueByClass(Js_Number);
            auto s = decideTypeValue(block, method, manager->typeMap[Js_Number], vars);
            auto e = decideTypeValue(block, method, manager->typeMap[Js_Number], vars);
            itr->val = s;
            vars.push_back(itr);
            block->start = string("for(var " + itrName + " = ") + s + "; "+ itrName + " < " + e + "; " + itrName + "++) {";
            block->afterBody = getGapByOffset(1) + "if(rand() % 2 + 2 > 0) {\n";
            block->afterBody += getGapByOffset(2) + "break;\n";
            block->afterBody += getGapByOffset(1) + "}";
            block->end = "}";
            break;
        }
        default:
        {
            itr->type = manager->getOrCreateType(C_int);
            itr->val = manager->_genTypeValueByClass(C_int);
            auto s = decideTypeValue(block, method, manager->typeMap[C_int], vars);
            auto e = decideTypeValue(block, method, manager->typeMap[C_int], vars);
            itr->val = s;
            vars.push_back(itr);
            block->start = string("for(int " + itrName + " = ") + s + "; "+ itrName + " < " + e + "; " + itrName + "++) {";
            block->afterBody = getGapByOffset(1) + "if(rand() % 2 + 2 > 0) {\n";
            block->afterBody += getGapByOffset(2) + "break;\n";
            block->afterBody += getGapByOffset(1) + "}";
            block->end = "}";
            break;
        }
    }
    return block;
}

HYCodeBlock* CodeGenerator::genCreateEntityBlock(HYMethodInfo * method, std::vector<HYVarInfo *>& vars) {
    auto block = new HYCodeBlock();
    
    if(manager->classMap.size() > 0) {
        int classType = manager->getClassTypeByMethodType(method->methodType);
        int index = arc4random() % manager->classMap.size();
        auto itr = manager->classMap.begin();
        while(index > 0) {
            itr++;
            index--;
        }
        int count = 0;
        bool isFinded = false;
        while(count < manager->classMap.size()) {
            count++;
            if(itr->second && itr->second->classType == classType) {
                isFinded = true;
                break;
            }
            itr++;
        }
        if(isFinded) {
            manager->_genTypeValueByClass(manager->getEntityTypeByClassType(classType), itr->second);
        }
        
    }
    
    return block;
}

HYCodeBlock *CodeGenerator::genWhileBlock(HYMethodInfo *method, std::vector<HYVarInfo *> &vars)
{
    auto block = new HYCodeBlock();
    switch (method->methodType) {
        case Method_Lua_Local: case Method_Lua_Object:
        {
            block->start = "while (" + decideConditionStr(block, method, vars) + ") do";
            block->afterBody = getGapByOffset(1) + "do break end";
            block->end = "end";
            break;
        }
        default:
        {
            block->start = "while(" + decideConditionStr(block, method, vars) + ") {";
            block->afterBody = getGapByOffset(1) + "if(rand() % 2 + 2 > 0) {\n";
            block->afterBody += getGapByOffset(2) + "break;\n";
            block->afterBody += getGapByOffset(1) + "}";
            block->end = "}";
        }
    }
    return block;
}

HYCodeBlock *CodeGenerator::operatorVar(HYMethodInfo *method, HYVarInfo *var, std::vector<HYVarInfo *> &vars) {
    static std::vector<string> numOp = {
        "+", "-", "*" //, "/"
    };
    static std::vector<string> BoolOp = {
        "!", "&&", "||"
    };
    
    static std::vector<string> LuaNumOp = {
        "+", "-", "*", "/"
    };
    auto block = new HYCodeBlock();
    switch (var->type->typeKey) {
        case C_int: case C_float: case C_double: case Js_Number: case Lua_Number:
        {
            block->body = var->name + " = " + _genNumberOpStr(block, method, var->type, vars, arc4random() % 3) + ";";
            break;
        }
        case C_char:
        {
            block->body = var->name + " = (" + var->name + " + " + to_string((arc4random() % 25) + 1) + ") % 26;";
            break;
        }
        case C_char_ptr:
        {
            auto genVar = genVarDeclare(C_char, false);
            genVar->val = var->name + "[0]";
            vars.push_back(genVar);
            block->body = genVarDeclareStr(genVar);
            break;
        }
        case C_int_ptr: case C_float_ptr: case C_double_ptr:
        {
            HYEntityType* t = 0;
            if(var->type->typeKey == C_int_ptr) t = manager->typeMap[C_int];
            else if(var->type->typeKey == C_double_ptr) t = manager->typeMap[C_double];
            else if(var->type->typeKey == C_float_ptr) t = manager->typeMap[C_float];
            block->body = var->name + "[0] = " + _genNumberOpStr(block, method, t, vars, arc4random() % 3) + ";";
            break;
        }
        case Lua_String:
        {
            block->body = var->name + " = " + decideTypeValue(block, method, var->type, vars) + " .. " + decideTypeValue(block, method, var->type, vars) + ";";
            break;
        }
        case Lua_Table:
        case Class_Lua:
        {
            block->body = var->name + "." + genNameForCplus(CVarName, true) + " = " + manager->_genTypeValueByClass(arc4random() % 2 ? Lua_Number : Lua_String) + ";";
            break;
        }
        case Js_Object:
        case Class_Js:
        {
            block->body = var->name + "." + genNameForCplus(CVarName, true) + " = " + manager->_genTypeValueByClass(arc4random() % 2 ? Js_Number : Js_String) + ";";
            break;
        }
        case Js_String:
        {
            block->body = var->name + " = " + decideTypeValue(block, method, arc4random() % 2 ? manager->typeMap[Js_Number] : manager->typeMap[Js_String], vars) + " + " + decideTypeValue(block, method, arc4random() % 2 ? manager->typeMap[Js_Number] : manager->typeMap[Js_String], vars);
            break;
        }
        default:
            break;
    }
    
    return block;
}

HYMethodInfo *CodeGenerator::findMethodWithReturnType(bool hasToEntity, std::vector<HYMethodInfo *> &methods, HYEntityType* retType, HYMethodInfo * fromMethod) {
    if(methods.size() > 0) {
        int pos = arc4random() % methods.size();
        for(int i = 0; i < methods.size(); i++) {
            auto m = methods[pos];
            if(!retType){
                if(!fromMethod || (fromMethod != m
                                   && !checkFunctionIsConflict(hasToEntity, fromMethod, m))) {
                   if(m->parent && manager->curClass) {
                       manager->curClass->usedClass.insert(m->parent);
                   }
                    return m;
                } else {
                    continue;
                }
            }
            if(m->retType && m->retType->type->isEqual(retType) && (!fromMethod || (fromMethod != m && !checkFunctionIsConflict(hasToEntity, fromMethod, m)))) {
                if(m->parent && manager->curClass) {
                    manager->curClass->usedClass.insert(m->parent);
                }
                return m;
            }
            pos = (pos + 1) % methods.size();
        }
    }
    return nullptr;
}

std::string CodeGenerator::decideTypeValue(HYCodeBlock * block, HYMethodInfo* fromMethod, HYEntityType* type, std::vector<HYEntityType*>& types, std::vector<HYVarInfo *> vars, HYVarInfo * skipVar, bool useMethod) {
    if(fromMethod && arc4random() % 100 <= 30) {
        std::vector<HYEntityType*> sels;
        int ctype = manager->getClassTypeByMethodType(fromMethod->methodType);
        for(auto itr = manager->classMap.begin(); itr != manager->classMap.end(); itr++) {
            if(itr->second && itr->second->classType == ctype) {
                sels.push_back(new HYEntityType(manager->getEntityTypeByClassType(itr->second->classType), itr->second));
            }
        }
        if(sels.size() > 0)
        {
            auto obj = selectVar(vars, sels);
            if(obj) {
                auto classInfo = obj->type->cls;
                if(classInfo) {
                    auto method = findMethodWithReturnType(true, classInfo->methods, type, fromMethod);
                    if(method) {
                        for(int i = 0; i < sels.size(); i++) {
                            delete sels[i];
                        }
                        return genCallBody(block, fromMethod, method, vars, obj);
                    }
                }
            }
            for(int i = 0; i < sels.size(); i++) {
                delete sels[i];
            }
        }
    }
    auto select = selectVar(vars, types, false, skipVar);
    if(select) {
        return select->name;
    }
    if(block && (type->cls
                 || type->typeKey == Cplus_bool_ptr
                 || type->typeKey == C_int_ptr
                 || type->typeKey == C_double_ptr
                 || type->typeKey == C_float_ptr)) {
        HYVarInfo * var = new HYVarInfo(manager->getOrCreateType(type->typeKey, type->cls));
        var->name = genNameForCplus(CVarName, true);
        var->val = manager->_genTypeValueByType(type);
        vars.push_back(var);
        block->beforeStart += genVarDeclareStr(var) + "\n";
        return var->name;
    }
    return manager->_genTypeValueByType(type);
}

std::string CodeGenerator::decideTypeValue(HYCodeBlock * block, HYMethodInfo* fromMethod, HYEntityType* type, std::vector<HYVarInfo *> vars, HYVarInfo * skipVar, bool useMethod) {
    std::vector<HYEntityType*> types;
    if(type) {
        types.push_back(type);
    }
    return decideTypeValue(block, fromMethod, type, types, vars, skipVar, useMethod);
}

std::string CodeGenerator::_genNumberOpStr(HYCodeBlock * block, HYMethodInfo* fromMethod, HYEntityType* type, std::vector<HYEntityType*>& types, std::vector<HYVarInfo *> &vars, int deep) {
    static std::vector<string> numOp = {
        "+", "-", "*" //, "/"
    };
    if(deep <= 0) {
        return decideTypeValue(block, fromMethod, type, types, vars) + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, type, types, vars);
    }
    int rd = arc4random() % 5;
    switch (rd) {
        case 1:
            return decideTypeValue(block, fromMethod, type, types, vars) + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, type, types, vars)  + numOp[arc4random() % numOp.size()] + _genNumberOpStr(block, fromMethod, type, types, vars, deep - 1);
            break;
        case 2:
            return decideTypeValue(block, fromMethod, type, types, vars) + numOp[arc4random() % numOp.size()] + "(" + decideTypeValue(block, fromMethod, type, types, vars)  + numOp[arc4random() % numOp.size()] + _genNumberOpStr(block, fromMethod, type, types, vars, deep - 1) + ")";
            break;
        case 3:
            return string("(") + decideTypeValue(block, fromMethod, type, types, vars) + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, type, types, vars) + ")" + numOp[arc4random() % numOp.size()] + _genNumberOpStr(block, fromMethod, type, types, vars, deep - 1);
            break;
        case 4:
            return string("(") + decideTypeValue(block, fromMethod, type, types, vars) + numOp[arc4random() % numOp.size()] + _genNumberOpStr(block, fromMethod, type, types, vars, deep - 1) + ")" + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, type, types, vars);
            break;
        default:
            return string("(") + _genNumberOpStr(block, fromMethod, type, types, vars, deep - 1) + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, type, types, vars) + ")" + numOp[arc4random() % numOp.size()] + decideTypeValue(block, fromMethod, type, types, vars);
            break;
    }
}

std::string CodeGenerator::_genNumberOpStr(HYCodeBlock * block, HYMethodInfo* fromMethod, HYEntityType* type, std::vector<HYVarInfo *> &vars, int deep) {
    std::vector<HYEntityType*> types;
    if(type) {
        types.push_back(type);
    }
    return _genNumberOpStr(block, fromMethod, type, types, vars, deep);
}

std::string CodeGenerator::randomAddOCProperty()
{
    std::string ret = "";
    int count = arc4random() % 7;
    std::string types[] = {"int", "double", "float", "bool", "NSString * ", "NSNumber *", "NSMutableArray *", "NSMutableDictionary *",  "NSArray *", "NSDictionary *"};
    int isNeedStrong[] = {0, 0, 0, 0, 1, 1, 2, 2, 2, 2};
    int len = getArrSize(types);
    for(int i = 0; i < count; i++)
    {
        int rt = arc4random() % len;
        switch(isNeedStrong[rt])
        {
            case 0:
                ret += "@property (nonatomic, readwrite) " + types[rt] + " " + genNameForCplus(CVarName, true) + ";\n";
                break;
            case 1:
                ret += "@property (nonatomic, readwrite, copy) " + types[rt] + " " + genNameForCplus(CVarName, true) + ";\n";
                break;
            case 2:
                ret += "@property (nonatomic, strong) " + types[rt] + " " + genNameForCplus(CVarName, true) + ";\n";
                break;
            default:
                break;
        };
    }
    return ret;
}

HYCodeBlock *CodeGenerator::genClassDeclareBlock(HYClassInfo *cls) {
    HYCodeBlock * block = new HYCodeBlock();
    string space = getGapByOffset(1);
    switch (cls->classType) {
        case Class_OC:
            block->start = "@interface " + cls->name + ": NSObject";
            if(cls->members.size() > 0) {
                string membody = "{\n";
                for(int i = 0; i < cls->members.size(); i++) {
                    auto mem = cls->members[i];
                    membody += space + manager->getTypeName(mem) + " " + cls->members[i]->name + ";\n";
                }
                membody += "}\n";
                membody += randomAddOCProperty();
                block->body += membody;
            }
            
            block->end = "@end";
            break;
        case Class_Cplus:
            block->start += "class " + cls->name + " {";
            block->end = "};";
            break;
        default:
            block->start += "";
            block->end = "";
            break;
    }
    if(cls->methods.size() > 0) {
        string metbody = "";
        if(cls->classType == Class_Cplus)
        {
            {
                auto finds = selectMethodByMethodType(cls->methods, Method_Cplus_Public);
                if(finds.size() > 0 || cls->constructor) {
                    metbody += "public:\n";
                    metbody += space + cls->constructor->declare + decideBlockEnd(cls->constructor->declare);
                    for(int i = 0; i < finds.size(); i++) {
                        metbody += space + finds[i]->declare + decideBlockEnd(finds[i]->declare);
                    }
                }
            }
            {
                auto finds = selectMethodByMethodType(cls->methods, Method_Cplus_Static);
                if(finds.size() > 0) {
                    for(int i = 0; i < finds.size(); i++) {
                        metbody += space + finds[i]->declare + decideBlockEnd(finds[i]->declare);
                    }
                }
            }
            {
                auto finds = selectMethodByMethodType(cls->methods, Method_Cplus_Protected);
                if(finds.size() > 0) {
                    metbody += "protected:\n";
                    for(int i = 0; i < finds.size(); i++) {
                        metbody += space + finds[i]->declare + decideBlockEnd(finds[i]->declare);
                    }
                }
            }
            {
                auto finds = selectMethodByMethodType(cls->methods, Method_Cplus_Private);
                if(finds.size() > 0 || cls->members.size() > 0) {
                    metbody += "private:\n";
                    for(int i = 0; i < finds.size(); i++) {
                        metbody += space + finds[i]->declare + decideBlockEnd(finds[i]->declare);
                    }
                }
            }
            for(int i = 0; i < cls->members.size(); i++) {
                metbody += space + manager->getTypeName(cls->members[i]) + " " + cls->members[i]->name + ";\n";;
            }
        } else {
            for(int i = 0; i < cls->methods.size(); i++) {
                metbody += cls->methods[i]->declare + decideBlockEnd(cls->methods[i]->declare);
            }
        }
        block->body += metbody;
    }
    if(cls->classType == Class_OC || cls->classType == Class_Cplus) {
        string def = "__" + cls->name + "__h";
        string defStr = "#ifndef " + def + "\n";
        defStr += "#define " + def + "\n";
        block->start = defStr + getImportHeader(cls, false) + block->start;
        block->end += decideBlockEnd(block->end) + "#endif\n";
    }
    return block;
}

HYCodeBlock *CodeGenerator::genClassBlock(HYClassInfo *cls) {
    HYCodeBlock * block = new HYCodeBlock();
    switch (cls->classType) {
        case Class_OC:
        {
            block->start = "@implementation " + cls->name;
            block->end = "@end";
            break;
        }
        case Class_Lua:
        {
            block->start = "local " + cls->name + " = {}";
            block->end = "return " + cls->name;
            break;
        }
        case Class_Js:
        {
            block->start = "var " + cls->name + " = function() {};";
            block->end = "module.exports = export = " + cls->name + ";";
            break;
        }
        default:
            break;
    }
    block->body = "";
    
    for(int i = cls->methods.size(); i >= 0 ; i--) {
        HYCodeBlock* methodBlock = nullptr;
        if(i == cls->methods.size() ) {
            if(cls->constructor) {
                if(cls->constructor->body != "") {
                    block->body += cls->constructor->body + decideBlockEnd(cls->constructor->body);
                } else {
                    methodBlock = genMethodBlock(cls->constructor);
                }
            } else {
                continue;
            }
        } else {
            if(cls->methods[i]->body != "") {
                block->body += cls->methods[i]->body + decideBlockEnd(cls->methods[i]->body);
            } else {
                methodBlock = genMethodBlock(cls->methods[i]);
            }
        }
        if(methodBlock) {
            addBlockCode(0, block->body, methodBlock);
        }
    }
    block->start = getImportHeader(cls, true) + block->start;
    return block;
}

HYCodeBlock *CodeGenerator::genMethodDeclareBlock(HYMethodInfo *method, bool isInBody) {
    HYCodeBlock * block = new HYCodeBlock();
    switch (method->methodType) {
        case Method_Cplus_Private:
        case Method_Cplus_Public:
        case Method_Cplus_Static:
        case Method_Cplus_Protected:
        case Method_C:
        case Method_C_OC:
        {
            block->body = ((!isInBody && method->methodType == Method_Cplus_Static) || (isInBody && (method->methodType == Method_C || method->methodType == Method_C_OC))) ? "static " : "";
            if([UserConfig sharedInstance].skipOptimize) {
                block->body += "__attribute__((optnone)) ";
            }
            if(!isInBody && (method->methodType == Method_Cplus_Public || method->methodType == Method_Cplus_Protected )) {
                block->body += "virtual ";
            }
            block->body += manager->getTypeName(method->retType) + " ";
            if(isInBody && method->methodType != Method_C && method->methodType != Method_C_OC) {
                block->body += method->parent->name + "::";
            }
            block->body += method->name + "(";
            for(int i = 0; i < method->args.size(); i++) {
                block->body += string((i > 0) ? ", " : "") + manager->getTypeName(method->args[i]) + " " + method->args[i]->name;
            }
            block->body += ")";
            break;
        }
        case Method_OC_Object:
        case Method_OC_Static:
        {
            block->body = (method->methodType == Method_OC_Static) ? "+ " : "- ";
            block->body += "(" + manager->getTypeName(method->retType) + ") " + method->name;
            for(int i = 0; i < method->args.size(); i++) {
                if(i == 0) {
                    block->body += ":(" + manager->getTypeName(method->args[i]) + ")" + method->args[i]->name;
                } else {
                    block->body += " " + method->args[i]->name + ":(" + manager->getTypeName(method->args[i]) + ")" + method->args[i]->name;
                }
            }
            break;
        }
        case Method_OC_Constructor:
        {
            block->body = "- (id)init";
            break;
        }
        case Method_Cplus_Constructor:
        {
            if(isInBody)
            {
                block->body = method->parent->name + "::";
            } else {
                block->body = "";
            }
            block->body += method->parent->name + "()";
            break;
        }
        case Method_Lua_Local:
        case Method_Lua_Object:
        {
            // function XX:dd()
            block->body = "function ";
            if(method->methodType == Method_Lua_Object) {
                block->body += method->parent->name + ":";
            }
            block->body += method->name + "(";
            for(int i = 0; i < method->args.size(); i++) {
                block->body += string((i > 0) ? ", " : "") + method->args[i]->name;
            }
            block->body += ")";
            break;
        }
        case Method_Js_Local:
        case Method_Js_Object:
        {
            // obj.prototype.xxx = function(...
            block->body = "";
            if(method->methodType == Method_Js_Object) {
                block->body += method->parent->name + ".prototype." + method->name + " = function(";
            } else {
                block->body += "function " + method->name + "(";
            }
            for(int i = 0; i < method->args.size(); i++) {
                block->body += string((i > 0) ? ", " : "") + method->args[i]->name;
            }
            block->body += ")";
        }
        default:
            break;
    }
    return block;
}
    
HYCodeBlock *CodeGenerator::genMethodBlock(HYMethodInfo *method, int lines) {
    HYCodeBlock * block = new HYCodeBlock();
    auto declare = genMethodDeclareBlock(method, true);
    block->start = declare->body + " {";
    if(method->methodType == Method_OC_Constructor) {
        block->beforeBody = getGapByOffset(1) + "if ((self = [super init])) {";
        block->body = genMethodBodyStr(method, 2);
        block->afterBody =  getGapByOffset(1) + "}\n" + getGapByOffset(1) + "return self;";
        ;
    } else {
        block->body = genMethodBodyStr(method, 1, lines);
    }
    block->end = "}";
    return block;
}
std::vector<HYMethodInfo *> CodeGenerator::selectMethodByMethodType(std::vector<HYMethodInfo *>& methods, int methodType) {
    std::vector<HYMethodInfo *> vec;
    for(int i = 0; i < methods.size(); i++) {
        if(methods[i]->methodType == methodType) {
            vec.push_back(methods[i]);
        }
    }
    return vec;
}
std::string CodeGenerator::getImportHeader(HYClassInfo * cls, bool isInBody) {
    string ret = "";
    switch (cls->classType) {
        case Class_OC:
        {
            if(isInBody) {
                ret += "#include <stdlib.h>\n";
                ret += "#import \"" + cls->name + ".h\"\n";
                for(auto itr = cls->usedClass.begin(); itr != cls->usedClass.end(); itr++) {
                    HYClassInfo * uc = *itr;
                    if(uc != cls && !uc->isSystem) {
                        ret += "#import \"" + uc->name + ".h\"\n";
                    }
                }
                
            } else {
                ret += "#import <Foundation/Foundation.h>\n";
                ret += "#import <stdlib.h>\n";
                for(auto itr = cls->usedClass.begin(); itr != cls->usedClass.end(); itr++) {
                    HYClassInfo * uc = *itr;
                    if(uc != cls && !uc->isSystem) {
                         ret += "@class " + uc->name + ";\n";
                    }
                }
            }
            break;
        }
        case Class_Cplus:
        {
            if(isInBody) {
                ret += "#import <Foundation/Foundation.h>\n";
                ret += "#include <stdlib.h>\n";
                ret += "#include \"" + cls->name + ".h\"\n";
                for(auto itr = cls->usedClass.begin(); itr != cls->usedClass.end(); itr++) {
                    HYClassInfo * uc = *itr;
                    if(uc != cls && !uc->isSystem) {
                        ret += "#include \"" + uc->name + ".h\"\n";
                    }
                }
                return ret;
            } else {
                ret += "#import <Foundation/Foundation.h>\n";
                ret += "#include <stdlib.h>\n";
//                ret += "#include <string.h>\n";
                for(auto itr = cls->usedClass.begin(); itr != cls->usedClass.end(); itr++) {
                    HYClassInfo * uc = *itr;
                    if(uc != cls && !uc->isSystem) {
                        ret += "class " + uc->name + ";\n";
                    }
                }
                return ret;
            }
            break;
        }
        case Class_Js:
        {
            if(isInBody) {
                for(auto itr = cls->usedClass.begin(); itr != cls->usedClass.end(); itr++) {
                    HYClassInfo * uc = *itr;
                    if(uc != cls && !uc->isSystem) {
                        ret += "var " + uc->name + " = require(\"" + uc->name + "\");\n";
                    }
                }
                return ret;
            }
            break;
        }
        case Class_Lua:
        {
            if(isInBody) {
                for(auto itr = cls->usedClass.begin(); itr != cls->usedClass.end(); itr++) {
                    HYClassInfo * uc = *itr;
                    if(uc != cls && !uc->isSystem) {
                        ret += "local " + uc->name + " = require(\"" + uc->name + "\");\n";
                    }
                }
                return ret;
            }
            break;
        }
        default:
            break;
    }
    return ret;
}
std::string CodeGenerator::decideBlockEnd(string& str)
{
    if(str[str.size() - 1] != '\n') {
        return "\n";
    }
    return "";
}

void CodeGenerator::buildClassBody(HYClassInfo *cls) {
    auto dec_block = genClassDeclareBlock(cls);
    cls->declare = "";
    addBlockCode(0, cls->declare, dec_block);

    //-------------------------------------
    auto body_block = genClassBlock(cls);
    cls->body = "";
    addBlockCode(0, cls->body, body_block);
    delete dec_block;
    delete body_block;
}

void CodeGenerator::buildMethod(HYMethodInfo *method, int lines) {
    manager->curClass = method->parent;
    auto dec_block = genMethodDeclareBlock(method, false);
    method->declare = dec_block->body + ";";
    auto body_block = genMethodBlock(method, lines);
    method->body = "";
    addBlockCode(0, method->body, body_block);
    delete dec_block;
    delete body_block;
}

HYMethodInfo *CodeGenerator::genOneClassMethod(const char * className, int methodType, int deep) {
    HYClassInfo * classInfo = nullptr;
    int classType = manager->getClassTypeByMethodType(methodType);
    if(className) {
        classInfo = manager->genEmptyClass(classType, className);
        classInfo->isCanCreate = false;
    }
    manager->curClass = classInfo;
    auto method = genMethodDeclare(classInfo, methodType);
    method->deep = deep;
    if(classInfo && method->isObject) {
        classInfo->methods.push_back(method);
    } else {
        localMethods.push_back(method);
    }
    buildMethod(method, arc4random() % 5 + 10);
    return method;
}

std::vector<HYMethodInfo*> CodeGenerator::genCMethod(int num, bool isOC) {
    std::vector<HYMethodInfo*> methods;
    for(int i = 0 ; i < num; i++) {
        auto method = genMethodDeclare(nullptr, isOC ? Method_C_OC : Method_C);
        buildMethod(method);
        localMethods.push_back(method);
        methods.push_back(method);
    }
    return methods;
}

bool CodeGenerator::checkFunctionIsConflict(bool hasToEntity, HYMethodInfo * fromMethod, HYMethodInfo * toMethod) {
    if(fromMethod->deep < toMethod->deep) {
        return true;
    }
    std::set<HYMethodInfo *> called;
    reviewAllCalled(toMethod, called);
    if(called.count(fromMethod)) {
        return true;
    }
    
    if(fromMethod->parent == toMethod->parent) {
        if(fromMethod->methodType == Method_OC_Static && (toMethod->methodType != Method_OC_Static || toMethod->methodType != Method_C || toMethod->methodType != Method_C_OC)) {
            return true;
        }
        if(fromMethod->methodType == Method_Cplus_Static && (toMethod->methodType != Method_Cplus_Static || toMethod->methodType != Method_C || toMethod->methodType != Method_C_OC)) {
            return true;
        }
        if(fromMethod->methodType == Method_C || fromMethod->methodType == Method_C_OC) {
            if(toMethod->methodType != Method_C && toMethod->methodType != Method_C_OC){
                return true;
            }
        }
    } else {
        // toMethod有实例调用的时候，只要是公开的都可以调用
        if(hasToEntity) {
            if(!toMethod->isPublic) {
                return true;
            }
        } else {
            // 否则只能调用静态的函数
            if(toMethod->methodType != Method_C
               && toMethod->methodType != Method_C_OC
               && toMethod->methodType != Method_OC_Static
               && toMethod->methodType != Method_Cplus_Static)
            {
                return true;
            }
            if(fromMethod->methodType == Method_Js_Local && toMethod->methodType != Method_Js_Local) {
                return true;
            }
            if(fromMethod->methodType == Method_Lua_Local && toMethod->methodType != Method_Lua_Local) {
                return true;
            }
        }
    }
    return false;
}

void CodeGenerator::autoAppendCode(int offset, string & code, string append) {
    auto arr = split(append, "\n");
    for(int i = 0 ; i < arr.size(); i ++ ){
        if(arr[i] != "") {
            code += getGapByOffset(offset) + arr[i] + "\n";
        }
    }
}

void CodeGenerator::addBlockCode(int offset, std::string &ret, gen::HYCodeBlock *block) {
    if(block) {
        if(block->beforeStart != "") {
            autoAppendCode(offset, ret, block->beforeStart);
        }
        if(block->start != "") {
            autoAppendCode(offset, ret, block->start);
        }
        if(block->beforeBody != "") {
            autoAppendCode(offset, ret, block->beforeBody);
        }
        if(block->body != "") {
            autoAppendCode(offset, ret, block->body);
        }
        if(block->afterBody != "") {
            autoAppendCode(offset, ret, block->afterBody);
        }
        if(block->end != "") {
            autoAppendCode(offset, ret, block->end);
        }
    }
}

void CodeGenerator::clearGlobalMethod()
{
    for(auto itr = localMethods.begin(); itr!= localMethods.end(); itr ++) {
        if(*itr) {
            delete *itr;
        }
    }
    localMethods.clear();
}

CodeGenerator::~CodeGenerator() {
    for(auto itr = manager->classMap.begin(); itr != manager->classMap.end(); itr++) {
        if(itr->second){
            delete itr->second;
        }
    }
    for(auto itr = manager->typeMap.begin(); itr != manager->typeMap.end(); itr++) {
        if(itr->second && itr->second->isCache) {
            delete itr->second;
        }
    }
    clearGlobalMethod();
    manager->classMap.clear();
    manager->typeMap.clear();
    delete manager;
}


CodeGenerator::CodeGenerator()  {
    manager = new TypeManager();
}


std::string CodeGenerator::genCallMethodString(HYMethodInfo* fromMethod, gen::HYMethodInfo *method) {
    auto block = new HYCodeBlock();
    std::vector<HYVarInfo*> vars;
    block->body = genCallBody(block, fromMethod, method, vars) + ";";
    string ret;
    addBlockCode(1, ret, block);
    delete block;
    return ret;
}

std::string CodeGenerator::selectOneMethodToRun(bool isOC, bool isStatic, const char * className, std::vector<HYMethodInfo *>& methods, int deep) {
    if(methods.size() == 0) return "";
    HYClassInfo* cls = nullptr;
    if(className && manager->classMap.find(className) != manager->classMap.end()) {
        cls = manager->classMap[className];
    }
    int methodType = isOC ? Method_C_OC : Method_C;
    if(isOC && cls) {
        if(isStatic) {
            methodType = Method_OC_Static;
        } else {
            methodType = Method_OC_Object;
        }
    }
    HYMethodInfo * fromMethod = new HYMethodInfo(methodType);
    fromMethod->parent = cls;
    int pos = arc4random() % methods.size();
    HYMethodInfo * select = nullptr;
    for(int i = 0 ; i < methods.size(); i++) {
        auto method = methods[pos];
        if( method->deep <= deep && !checkFunctionIsConflict(false, fromMethod, method)) {
            select = method;
            break;
        }
        pos = (pos + 1) % methods.size();
    }
    std::string ret = "";
    if(select) {
        ret = genCallMethodString(fromMethod, select);
    }
    delete fromMethod;
    return ret;
}

HYMethodInfo* CodeGenerator::genCallAllMethod(std::vector<HYMethodInfo *>& methods) {
    std::vector<HYVarInfo *> vars;
    HYMethodInfo * retMethod = genMethodDeclare(nullptr, Method_C);
    auto dec_block = genMethodDeclareBlock(retMethod, true);
    retMethod->declare = dec_block->body + ";";
    retMethod->body = dec_block->body + " {\n";
    delete dec_block;
    HYMethodInfo * fromMethod = new HYMethodInfo(Method_C_OC);
    auto count = retMethod->args.size();
    for(int i = 0; i< count; i++) {
        vars.push_back(retMethod->args[i]->clone());
    }
//    retMethod->body += getGapByOffset(1) + "asm (\"\");\n";
    retMethod->body += getGapByOffset(1) + "int test = rand() % 1000;\n";
    retMethod->body += getGapByOffset(1) + "if(test % 2 + 2 == 0) {\n";
    for(int i = 0; i < methods.size(); i++) {
        auto m = methods[i];
        auto block = new HYCodeBlock();
//        // 调用函数地址防止优化
        retMethod->body += getGapByOffset(2) + "printf(\"%x\"," +  m->name + ");\n";
        block->body = genCallBody(block, fromMethod, m, vars) + ";";
        addBlockCode(2, retMethod->body, block);
        delete block;
    }
    retMethod->body += genMethodRetCode(2, retMethod, vars);
    retMethod->body += getGapByOffset(1) + "}\n";
    retMethod->body += genMethodRetCode(1, retMethod, vars);
    retMethod->body += "}\n";
    delete fromMethod;
    for(int i = 0; i < vars.size(); i++) {
        delete vars[i];
    }
    localMethods.push_back(retMethod);
    return retMethod;
}

gen::HYMethodInfo * CodeGenerator::genCallAllClass(std::vector<HYClassInfo *> &classes) {
    HYMethodInfo * retMethod = new HYMethodInfo(Method_C);
    retMethod->name = genNameForCplus(CFuncName, true);
    auto dec_block = genMethodDeclareBlock(retMethod, false);
    retMethod->declare = dec_block->body + ";";
    string import = "";
    
    import += "#include <stdlib.h>\n";
    import += "#import \"" + retMethod->name + ".h\"\n";
    for(auto itr = classes.begin(); itr != classes.end(); itr++) {
        HYClassInfo * uc = *itr;
        if(!uc->isSystem) {
            import += "#import \"" + uc->name + ".h\"\n";
        }
    }
    retMethod->body = import;
    retMethod->body += dec_block->body + " {\n";
    delete dec_block;
//    retMethod->body += getGapByOffset(1) + "asm (\"\");\n";
    HYMethodInfo * fromMethod = new HYMethodInfo(Method_C_OC);
    retMethod->body += getGapByOffset(1) + "int test = " + to_string(arc4random() % 1000) + ";\n";
    retMethod->body += getGapByOffset(1) + "if(test % 2 + 2 == 0) {\n";
    for(int i = 0; i < classes.size(); i++) {
        auto c = classes[i];
        auto typestruct = manager->getOrCreateType(manager->getEntityTypeByClassType(c->classType), c);
        HYVarInfo * genVar = new HYVarInfo(typestruct);
        genVar->name = genNameForCplus(CVarName, true);
        genVar->val = manager->_genTypeValueByType(typestruct);
        retMethod->body += getGapByOffset(2) + genVarDeclareStr(genVar) + "\n";
        delete genVar;
    }
    retMethod->body += getGapByOffset(1) + "}\n";
    retMethod->body += "}\n";
    delete fromMethod;
    string def = "__" + retMethod->name + "__h";
    string defStr = "#ifndef " + def + "\n";
    defStr += "#define " + def + "\n";
    defStr += "#ifdef __cplusplus\n";
    defStr += "extern \"C\" " + retMethod->declare + "\n";
    defStr += "#else\n";
    defStr += "extern " + retMethod->declare + "\n";
    defStr += "#endif\n";
    defStr += "#endif\n";
    retMethod->declare = defStr;
    
    localMethods.push_back(retMethod);
    return retMethod;
}

}
