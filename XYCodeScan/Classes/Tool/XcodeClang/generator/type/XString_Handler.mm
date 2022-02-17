//
//  XString_Handler.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/4.
//

#include "XString_Handler.hpp"
#include "XCommanFunc.hpp"
#import "HYGenerateNameTool.h"
#import "UserConfig.h"
#include "XCodeLine.h"

using namespace hygen;

int String_Handler::supportMode() { 
    return CodeMode_C | CodeMode_CXX | CodeMode_OC;
}

void String_Handler::supportTypes(hygen::CodeMode cmode, bool isRun, std::vector<struct TypeWeight *> &vec) {
    auto item = new TypeWeight();
    item->typeName = "string";
    item->weight = 5;
    vec.push_back(item);
}

static std::string genRandomString(bool isFileName) {
    std::string ret;
    if(isFileName)
    {
        ret += [[HYGenerateNameTool generateByName:ResName from:nil cache:false] UTF8String];
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
            ret += [[HYGenerateNameTool generateByName:WordName from:nil cache:false] UTF8String];
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

std::string String_Handler::newInst(hygen::Context * context, std::string &typeName, float &maxValue, float &minValue, bool forceCreate) {
    std::string ret = "\"" + genRandomString(arc4random() % 100 < 20) + "\"";
    
    if(forceCreate) {
        std::string varname = randomAVarName();
        Var * var = new Var();
        var->order = context->curBlock->genAnOrder();
        var->varName = varname;
        var->typeName = "string";
        var->maxValue = maxValue;
        var->minValue = minValue;
        context->curBlock->addVar(var);
        auto line = new CodeLine();
        line->code = formatName(context, typeName) + " " + varname + "=" + ret + ";";
        line->order = var->order;
        context->curBlock->addLine(line);
        return varname;
    }
    return ret;
}

void String_Handler::onCall(hygen::Context * context, hygen::Var * var) {
    int index = arc4random() % 10;
    std::string ret;
    switch(index)
    {
        case 1:
        {
            float mx1 = -INT_MAX, mn1 = INT_MAX;
            ret = "strstr(" + var->varName + "," + context->curBlock->selectOrCreateVar("string", mx1, mn1) + ");";
            break;
        }
        case 2:
        {
            float mx1 = -INT_MAX, mn1 = INT_MAX;
            ret = "strcat(" + var->varName + "," + context->curBlock->selectOrCreateVar("string", mx1, mn1) + ");";
            break;
        }
        case 3:
        {
            ret = "memchr(" + var->varName + "," + char((arc4random() % 2 == 0 ? 'a' : 'A') + arc4random() % 26) + ", sizeof(" + var->varName + "));";
            break;
        }
        case 4:
        {
            ret = "strlen(" + var->varName + ");";
            break;
        }
        default:
        {
            ret = "sizeof(" + var->varName + ");";
            break;
        }
    }
}

std::string String_Handler::formatName(hygen::Context * context, std::string) {
    return "char *";
}

std::string String_Handler::getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue) {
    if(isTrue) {
        int t = arc4random() % 2;
        switch (t) {
            case 1: {
                return var->varName + "[0] != " + (arc4random() % 2 == 0 ? "'\\n'" : "'\\r'");
                break;
            }
            default:
                return "strlen(" + var->varName + ") > 0";
                break;
        }
    } else {
        int t = arc4random() % 2;
        switch (t) {
            case 1: {
                return var->varName + "[0] == " + (arc4random() % 2 == 0 ? "'\\n'" : "'\\r'");
                break;
            }
            default:
                return "strlen(" + var->varName + ") == 0";
                break;
        }
    }
}
