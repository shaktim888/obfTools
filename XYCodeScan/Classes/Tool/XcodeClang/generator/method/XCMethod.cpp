//
//  XCMethod.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/5.
//

#include "XCMethod.hpp"
#include "XContext.h"
#include "XTypeManager.h"
#include "XCodeLine.h"
#include "XCodeFactory.hpp"

using namespace hygen;

std::string CMethod::getDeclareString(hygen::Context *context) {
    std::string declare = context->manager->formatTypeName(context, retType) + " " + methodName + "(";
    for(auto itr = params.begin(); itr != params.end(); itr++) {
        if(itr == params.begin()) {
            declare = declare + context->manager->formatTypeName(context, (*itr)->typeName) + " " + (*itr)->varName;
        } else {
            declare = declare + "," + context->manager->formatTypeName(context, (*itr)->typeName) + " " + (*itr)->varName;
        }
    }
    return declare;
}

void CMethod::onDeclare(Context * context) {
    std::string dec = getDeclareString(context);
    auto line = new CodeLine();
    line->code = dec + ";";
    line->order = context->curBlock->getCurMaxOrder();
    context->curBlock->addLine(line);
}

void CMethod::onBody(hygen::Context * context) {
    std::string dec = getDeclareString(context);
    context->enterBlock(dec + "{");
    // 1. 加self指针
    {
        Var * selfItr = new Var();
        selfItr->varName = "this";
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

void CMethod::onCall(hygen::Context * context, hygen::Var * var) {
    std::string callstr = methodName + "(";
    for(auto itr = params.begin(); itr != params.end(); itr++) {
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        std::string ref = context->curBlock->selectOrCreateVar((*itr)->typeName, mx1, mn1);
        if(itr == params.begin()){
            callstr = callstr + ref;
        } else {
            callstr = callstr + "," + ref;
        }
    }
    callstr += ");";
    auto line = new CodeLine();
    line->code = callstr;
    line->order = context->curBlock->genAnOrder();
    context->curBlock->addLine(line);
}
