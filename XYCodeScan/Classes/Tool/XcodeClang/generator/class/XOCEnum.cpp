//
//  XOCEnum.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#include "XOCEnum.hpp"
#include "XCodeLine.h"
#include "XContext.h"

using namespace hygen;

//----------------EnumInfo
std::string EnumInfo::onCreate(Context* context) {
    return items[arc4random() % items.size()];
}

void EnumInfo::onDeclare(Context *context) {
    // nothing
}

void EnumInfo::onBody(Context *context) {
    // nothing
}

void EnumInfo::onCall(Context *context, Var* var) {
    auto line = new CodeLine();
    line->code = var->varName + " = " + items[arc4random() % items.size()] + ";";
    line->code = context->curBlock->genAnOrder();
    context->curBlock->addLine(line);
}

std::string EnumInfo::genBool(hygen::Context *context, hygen::Var *var, bool isTrue) {
    if(isTrue) {
        return var->varName + " >= 0";
    } else {
        return var->varName + " < 0";
    }
    
}
