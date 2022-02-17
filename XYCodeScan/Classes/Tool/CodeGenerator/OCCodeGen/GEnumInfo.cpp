//
//  EnumInfo.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "GEnumInfo.hpp"
#include "GRuntimeContext.hpp"
#include "GCommanFunc.hpp"
#include "GLine.hpp"


namespace ocgen {

void EnumInfo::initByOneLine(std::string &s)
{
    std::vector<string> tokens;
    split(s,tokens, "##");
    std::vector<string> types;
    split(tokens[1], types, "#", 1);
    items.push_back(types[1]);
}

std::string EnumInfo::genOneInstance(RuntimeContext * context) {
    return items[arc4random() % items.size()];
}

void EnumInfo::objectCall(RuntimeContext * context, VarInfo * b) {
    auto line = new Line();
    auto item = items[arc4random() % items.size()];
    line->code = b->name + " = " + item + ";";
    line->order = context->curBlock->genAnOrder();
    context->curBlock->addLine(line);
}

std::string EnumInfo::execABoolValue(RuntimeContext * context, VarInfo * var) {
    return var->name + (arc4random() % 2 ? "==" : "!=") + genOneInstance(context);
}

}

