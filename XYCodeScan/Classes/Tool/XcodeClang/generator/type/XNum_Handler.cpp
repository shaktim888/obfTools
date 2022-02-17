//
//  XInt_Handler.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/1.
//

#include "XNum_Handler.hpp"
#include "XCommanFunc.hpp"
#include "XVar.h"
#include "XCodeLine.h"

using namespace hygen;

int Num_Handler::supportMode() { 
    return CodeMode_OC | CodeMode_C | CodeMode_CXX;
}

void Num_Handler::supportTypes(hygen::CodeMode cmode, bool isRun, std::vector<struct TypeWeight*> &vec) {
    auto item = new TypeWeight();
    item->typeName = typeName;
    if(typeName == "int"){
        item->weight = 10;
    } else {
        item->weight = 5;
    }
    vec.push_back(item);
}

std::string Num_Handler::formatName(Context* context, std::string typeName) {
    vector<std::string> words;
    split(typeName, words, "-");
    return words[0];
}

std::string Num_Handler::newInst(hygen::Context *context, std::string &typeName, float &maxValue, float &minValue, bool forceCreate) {
    
    vector<std::string> words;
    split(typeName, words, "-");
    std::string ret;
    std::string tp;
    if(words[0].find("int") == 0) {
        tp = "int";
        int v;
        int max = context->curBlock->maxValue, min = context->curBlock->minValue;
        if(words.size() > 0) {
            if(words.size() == 2) {
                max = atoi(words[1].c_str());
            }
            if(words.size() > 2) {
                min = atoi(words[1].c_str());
                max = atoi(words[2].c_str());
            }
        }
        if(max == min) {
            v = min;
        } else {
            v = arc4random() % (max - min);
        }
        maxValue = maxValue < max ? max : maxValue;
        minValue = minValue > min ? min : maxValue;
        ret = to_string(v);
    }
    else if(words[0].find("float") == 0 || words[0].find("CGFloat") == 0) {
        tp = "float";
        float v;
        float max = context->curBlock->maxValue, min = context->curBlock->minValue;
        if(words.size() > 1) {
            if(words.size() == 2) {
                max = atof(words[1].c_str());
            }
            if(words.size() > 2) {
                min = atof(words[1].c_str());
                max = atof(words[2].c_str());
            }
        }
        if(max == min)
            v = min;
        else
            v = float(min) + float(arc4random() % int((max - min) * 1000)) / 1000.0;
        
        maxValue = maxValue < max ? max : maxValue;
        minValue = minValue > min ? min : maxValue;
        
        ret = to_string(v);
    }
    
    if(forceCreate) {
        std::string varname = randomAVarName();
        Var * var = new Var();
        var->order = context->curBlock->genAnOrder();
        var->varName = varname;
        var->typeName = typeName;
        var->maxValue = maxValue;
        var->minValue = minValue;
        var->canCalc = true;
        context->curBlock->addVar(var);
        auto line = new CodeLine();
        line->code = typeName + " " + varname + "=" + ret + ";";
        line->order = var->order;
        context->curBlock->addLine(line);
        return varname;
    } else {
        return ret;
    }
}

static std::string _genNumberOpStr(Context * context, int deep, float &maxValue, float &minValue, string& typeName) {
    static std::vector<string> numOp = {
        "+", "-", "*" //, "/"
    };
            
    float mx1 = -INT_MAX, mn1 = INT_MAX;
    bool isFirstDeep = arc4random() % 2 == 0;
    
    std::string ref1;
    if(deep <= 0 || !isFirstDeep) {
        ref1 = context->curBlock->selectOrCreateVar(typeName, mx1, mn1, 20);
    } else {
        ref1 = _genNumberOpStr(context, deep-1, mx1, mn1, typeName);
    }
    
    float mx2 = -INT_MAX, mn2 = INT_MAX;
    std::string ref2;
    if(deep <=0 || isFirstDeep) {
        ref2 = context->curBlock->selectOrCreateVar(typeName, mx2, mn2, 20);
    } else {
        ref2 = _genNumberOpStr(context, deep-1, mx2, mn2, typeName);
    }
    std::string op = numOp[arc4random() % numOp.size()];
    if(op == "+")
    {
        if(mx1 + mx2 > maxValue) {
            maxValue = mx1 + mx2;
        }
        if(mn1 + mn2 < minValue) {
            minValue = mn1 + mn2;
        }
    }
    if(op == "-")
    {
        if(mx1 - mn2 > maxValue) {
            maxValue = mx1 - mn2;
        }
        if(mn1 - mx2 < minValue) {
            minValue = mn1 - mx2;
        }
    }
    if(op == "*")
    {
        float m = mx1*mx2;
        float n = mn1*mn2;
        float x = mx1*mn2;
        float y = mn1*mx2;
        
        if(m > maxValue) { maxValue = m; }
        if(n > maxValue) { maxValue = n; }
        if(x > maxValue) { maxValue = x; }
        if(y > maxValue) { maxValue = y; }
        
        if(m < minValue) { minValue = m; }
        if(n < minValue) { minValue = n; }
        if(x < minValue) { minValue = x; }
        if(y < minValue) { minValue = y; }
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

void Num_Handler::onCall(hygen::Context * context, hygen::Var * var) {
    auto line = new CodeLine();
    float mx1 = -INT_MAX, mn1 = INT_MAX;
    line->code = var->varName + "=" + _genNumberOpStr(context, arc4random() % 2 + 1, mx1, mn1, var->typeName) + ";";
    var->maxValue = mx1;
    var->minValue = mn1;
    var->canCalc = true;
    line->order = context->curBlock->genAnOrder();
    context->curBlock->addLine(line);
}

std::string Num_Handler::getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue){
    if(isTrue) {
        if(var->maxValue == var->minValue) {
            return var->varName + (arc4random() % 2 == 0 ? ">=" : "<=") + to_string(var->minValue);
        }
        int t = arc4random() % 2;
        switch (t) {
            case 0:
                return var->varName + ">=" + to_string(var->minValue - arc4random() % 100);
                break;
            default:
                return var->varName + "<=" + to_string(var->maxValue + arc4random() % 100);
                break;
        }
    } else {
        int t = arc4random() % 2;
        switch (t) {
            case 0:
                return var->varName + "<" + to_string(var->minValue - arc4random() % 100);
                break;
            default:
                return var->varName + ">" + to_string(var->maxValue + arc4random() % 100);
                break;
        }
    }
}
