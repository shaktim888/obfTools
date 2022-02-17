//
//  XBool_Handler.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/3.
//

#include "XBool_Handler.hpp"
#include "XCommanFunc.hpp"
#include "XCodeLine.h"

using namespace hygen;

int Bool_Handler::supportMode() { 
    return CodeMode_OC | CodeMode_C | CodeMode_CXX;
}

void Bool_Handler::supportTypes(hygen::CodeMode cmode, bool isRun, std::vector<struct TypeWeight *> &vec) { 
    auto weight = new TypeWeight();
    weight->typeName = "bool";
    weight->weight = 5;
    vec.push_back(weight);
}

std::string Bool_Handler::newInst(hygen::Context * context, std::string &typeName, float &maxValue, float &minValue, bool forceCreate) {
    bool result = arc4random() % 2 == 0;
    std::string ret;
    if(context->cmode & CodeMode_C) {
        ret = result ? "1" : "0";
    } else if(context->cmode & CodeMode_OC) {
        ret = result ? "YES" : "NO";
    } else {
        ret = result ? "true" : "false";
    }
        
    
    if(forceCreate) {
        std::string varname = randomAVarName();
        Var * var = new Var();
        var->order = context->curBlock->genAnOrder();
        var->varName = varname;
        var->typeName = "bool";
        var->maxValue = result ? 1 : 0;
        var->minValue = result ? 1 : 0;
        context->curBlock->addVar(var);
        auto line = new CodeLine();
        line->code = formatName(context, typeName) + " " + varname + "=" + ret + ";";
        line->order = var->order;
        context->curBlock->addLine(line);
        return varname;
    }
    return ret;
}

static std::string _genBoolOpStr(Context * context, int deep, float &maxValue, float &minValue, string& typeName) {
    static std::vector<string> numOp = {
        "&&", "||",
    };
            
    float mx1 = -INT_MAX, mn1 = INT_MAX;
    bool isFirstDeep = arc4random() % 2 == 0;
    
    std::string ref1;
    if(deep <= 0 || !isFirstDeep) {
        ref1 = context->curBlock->selectOrCreateVar(typeName, mx1, mn1, 20);
    } else {
        ref1 = _genBoolOpStr(context, deep-1, mx1, mn1, typeName);
    }
    
    float mx2 = -INT_MAX, mn2 = INT_MAX;
    std::string ref2;
    if(deep <=0 || isFirstDeep) {
        ref2 = context->curBlock->selectOrCreateVar(typeName, mx2, mn2, 20);
    } else {
        ref2 = _genBoolOpStr(context, deep-1, mx2, mn2, typeName);
    }
    std::string op = numOp[arc4random() % numOp.size()];
    if(op == "&&")
    {
        if(mx1 == 1 && mx2 == 1) {
            maxValue = 1;
            minValue = 1;
        } else {
            maxValue = 0;
            minValue = 0;
        }
    }
    if(op == "||")
    {
        if(mx1 == 1 || mx2 == 1) {
            maxValue = 1;
            minValue = 1;
        } else {
            maxValue = 0;
            minValue = 0;
        }
    }
    
    if(deep <= 0) {
        return ref1 + op + ref2;
    } else {
        if(isFirstDeep) {
            return "(" + ref1 + ")" + op + ref2;
        } else {
            return ref1 + op + "(" + ref2 + ")";
        }
    }
    
}

void Bool_Handler::onCall(hygen::Context * context, hygen::Var * var) {
    auto line = new CodeLine();
    float mx1 = -INT_MAX, mn1 = INT_MAX;
    line->code = var->varName + "=" + _genBoolOpStr(context, arc4random() % 2 + 1, mx1, mn1, var->typeName) + ";";
    var->maxValue = mx1;
    var->minValue = mn1;
    line->order = context->curBlock->genAnOrder();
    context->curBlock->addLine(line);
}

std::string Bool_Handler::formatName(Context* context, std::string) {
    if(context->cmode & CodeMode_C) {
        return "short";
    } else if(context->cmode & CodeMode_OC) {
        return "BOOL";
    } else {
        return "bool";
    }
}

std::string Bool_Handler::getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue)
{
    if(isTrue) {
        if(var->minValue >= 1) {
            return var->varName;
        } else {
            return "!" + var->varName;
        }
    } else {
        if(var->minValue >= 1) {
            return "!" + var->varName;
        } else {
            return var->varName;
        }
    }
}
