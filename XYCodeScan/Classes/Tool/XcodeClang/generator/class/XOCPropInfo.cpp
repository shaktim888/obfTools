//
//  XOCPropInfo.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/3.
//

#include "XOCPropInfo.hpp"
#include "XContext.h"
#include "XCommanFunc.hpp"
#include "XCodeLine.h"

using namespace hygen;

void PropInfo::onDeclare(hygen::Context * context) {
    std::string formatName = context->manager->formatTypeName(context, typeName);
    std::string ret;
    if(formatName.find("*") != std::string::npos) {
        ret = "@property (nonatomic, strong) " + formatName + " " + varName + ";";
    } else {
        ret = "@property (nonatomic, readwrite) " + formatName + " " + varName + ";";
    }
    auto line = new CodeLine();
    line->code = ret;
    line->order = context->curBlock->getLastLineOrder();
    context->curBlock->addLine(line);
}

void PropInfo::onBody(hygen::Context * context) {
    // nothing
}

void PropInfo::onCall(hygen::Context * context, hygen::Var * var) {
    if(writeonly || (!readonly && arc4random() % 100 < 50)) {
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        std::string str = context->curBlock->selectOrCreateVar(typeName, mx1, mn1);
        auto line = new CodeLine();
        line->code = var->varName + "." + varName + " = " + str + ";";
        line->order = context->curBlock->genAnOrder();
        context->curBlock->addLine(line);
    } else {
        bool needCreateVar = arc4random() % 100 < 30;
        auto line = new CodeLine();
        if(needCreateVar && context->manager->isCanOpType(context, typeName)) {
            Var * innerVar = new Var();
            innerVar->varName = randomAVarName();
            innerVar->order = context->curBlock->genAnOrder();
            innerVar->typeName = typeName;
            context->curBlock->addVar(innerVar);
            line->order = innerVar->order;
            line->code = context->manager->formatTypeName(context, typeName) + innerVar->varName + " = " + var->varName + "." + varName + ";";
        } else {
            line->code = "[" + var->varName + " " + varName + "];";
            line->order = context->curBlock->genAnOrder();
        }
        context->curBlock->addLine(line);
        
    }
}
