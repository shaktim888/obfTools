//
//  XOCMethod.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#include "XOCMethod.hpp"
#include "XCommanFunc.hpp"
#include "XContext.h"
#include "XTypeManager.h"
#include "XCodeLine.h"
#include "XVar.h"
#include "XCodeFactory.hpp"

using namespace hygen;

void OCMethod::onDeclare(hygen::Context *context) { 
    std::string dec = getDeclareString(context);
    auto line = new CodeLine();
    line->code = dec + ";";
    line->order = context->curBlock->getCurMaxOrder();
    context->curBlock->addLine(line);
}

void OCMethod::onBody(hygen::Context *context) {
    std::string dec = getDeclareString(context);
    context->enterBlock(dec + "{");
    // 1. 加self指针
    {
        Var * selfItr = new Var();
        selfItr->varName = "self";
        selfItr->typeName = cls->name;
        context->curBlock->addVar(selfItr);
    }
    // 2. 添加参数
    {
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            Var * var = new Var();
            var->varName = (*itr)->varName;
            var->typeName = (*itr)->typeName;
            var->maxValue = (*itr)->maxValue;
            var->minValue = (*itr)->minValue;
            context->curBlock->addVar(var);
        }
    }
    
    if(methodType == OCMethodType_Interface) {
        std::string supercall = "[super " + methodName;
        for (auto p = params.begin(); p != params.end(); p++) {
            if(p == params.begin()) {
                supercall = supercall + ":" + (*p)->varName;
            } else {
                supercall = supercall + " " + static_cast<OCParam*>(*p)->paramName + ":" + (*p)->varName;
            }
        }
        supercall += "];";
        auto line = new CodeLine();
        line->code = supercall;
        line->order = -1; // 最优先调用
        context->curBlock->addLine(line);
    }
    
    context->remainLine = arc4random() % 3 + 5;
    Var * retVar = nullptr;
    if(retType != "void") {
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        std::string ref = context->curBlock->createVar(retType, mx1, mn1, true);
        retVar = context->curBlock->getVarByName(ref);
    }
    int lastLineNum = context->curBlock->getLastLineOrder();
    while(context->remainLine > 0) {
        context->factory->genCode(arc4random() % 2 == 0, true);
    }
    if(retVar) {
        maxValue = retVar->maxValue;
        minValue = retVar->minValue;
        canCalc = true;
        auto line = new CodeLine();
        line->code = "return " + retVar->varName + ";";
        line->order = lastLineNum;
        context->curBlock->addLine(line);
    }
    
    context->exitBlock("}");
}


std::string OCMethod::getRealCall(Context * context, hygen::Var *var) {
    std::string callstr;
    if(call != ""){
        callstr = call;
        int index = 0;
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            float mx1 = -INT_MAX, mn1 = INT_MAX;
            std::string ref = context->curBlock->selectOrCreateVar((*itr)->typeName, mx1, mn1);
            replace_all_distinct(callstr, std::string("#") + to_string(index), ref);
            index++;
        }
    } else {
        callstr = methodName;
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            float mx1 = -INT_MAX, mn1 = INT_MAX;
            std::string ref = context->curBlock->selectOrCreateVar((*itr)->typeName, mx1, mn1);
            if(itr == params.begin()){
                callstr = callstr + ":" + ref;
            } else {
                callstr = callstr + " " + dynamic_cast<OCParam*>(*itr)->paramName + ":" + ref;
            }
        }
    }
    
    replace_all_distinct(callstr, "#this", methodName);
    replace_all_distinct(callstr, "#self", methodName);
    if(methodType == OCMethodType_Create) {
        if(!isconst && !(call.find("(") != string::npos && call.find(")") != string::npos)
           && !(call.find("[") == 0 && call.find("]") == call.length() - 1)) {
            callstr = string("[") + cls->name + " " + callstr + "]";
        }
    } else if(methodType == OCMethodType_Init) {
        if(!isconst && !(call.find("(") != string::npos && call.find(")") != string::npos)
           && !(call.find("[") == 0 && call.find("]") == call.length() - 1)) {
            callstr = string("[[") + cls->name + " alloc] " + callstr + "]";
        }
    } else if(methodType == OCMethodType_Method) {
        std::string varRef = var->varName;
//        if(var->typeName == cls->name) {
//            varRef = "self";
//        }
        if(!isconst && !(call.find("(") != string::npos && call.find(")") != string::npos)
           && !(call.find("[") == 0 && call.find("]") == call.length() - 1)) {
            callstr = string("[") + varRef + " " + callstr + "]";
        }
    }
    return callstr;
}

void OCMethod::onCall(hygen::Context *context, hygen::Var *var) {
    std::string _call = getRealCall(context, var);
    auto line = new CodeLine();
    line->code = _call;
    line->order = context->curBlock->getCurMaxOrder();
    context->curBlock->addLine(line);
}

std::string OCMethod::getDeclareString(Context * context) {
    if(declare == "") {
        declare = "- (" + context->manager->formatTypeName(context, retType) + ")" + methodName;
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            if(itr == params.begin()) {
                declare = declare + ":" + "(" + context->manager->formatTypeName(context, (*itr)->typeName) + ")" + (*itr)->varName;
            } else {
                declare = declare + " " + (dynamic_cast<OCParam*>(*itr))->paramName + ":" + "(" + context->manager->formatTypeName(context, (*itr)->typeName) + ")" + (*itr)->varName;
            }
        }
    }
    replace_all_distinct(declare, ";", "");
    return declare;
}
