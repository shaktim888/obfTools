//
//  XBlock.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "XBlock.h"
#include "XTypeManager.h"
#include "XContext.h"
#include "XTypeManager.h"
#include "XCommanFunc.hpp"
#include "XCodeLine.h"

namespace hygen
{

std::string Block::createVar(std::string varType, float &maxValue, float &minValue, bool forceCreate) {
    return context->manager->createNewValue(context, varType, maxValue, minValue, forceCreate);
}

int Block::getCurMaxOrder() {
    maxOrder = minOrder > maxOrder ? minOrder : maxOrder;
    return maxOrder++;
}

int Block::genAnOrder(){
    if(context->isInsert) {
        return getCurMaxOrder();
    }
    int order = minOrder;
    if(minOrder < maxOrder) {
        order = arc4random() % (maxOrder - minOrder) + minOrder;
    }
    minOrder = order + 1;
    maxOrder = minOrder > maxOrder ? minOrder : maxOrder;
    return order;
}

void Block::resetOrder() {
    minOrder = 0;
}

void Block::addVar(Var* var) {
    vars.push_back(var);
    if(var->order < 0) {
        var->order = genAnOrder();
    }
    
    adapterOrder(var->order);
}

static bool cmpLine(Line* x,Line* y) ///cmp函数传参的类型不是vector<int>型，是vector中元素类型,即int型
{
    return x->order < y->order;
}


std::string Block::selectOrCreateVar(std::string varType, float &maxValue, float &minValue, int noSelectWeight) {
    Var * var = selectVar(varType, noSelectWeight);
    if(!var) {
        return createVar(varType, maxValue, minValue);
    }
    if(var->maxValue > maxValue) maxValue = var->maxValue;
    if(var->minValue < minValue) minValue = var->minValue;
    return var->varName;
}

void Block::addLine(Line* line, bool incNum) {
//    if(dynamic_cast<CodeLine*>(line)){
//        printf("%s\n", dynamic_cast<CodeLine*>(line)->code.c_str());
//    }
    lines.push_back(line);
    if(incNum) {
        context->remainLine--;
    }
}


Var* Block::selectVar(std::string varType, int noSelectWeight) {
    if(arc4random() % 100 < noSelectWeight) { // 小概率不去池子里拿
        return nullptr;
    }
    std::string formatVarType = varType;
    replace_all_distinct(formatVarType, " ", "");
    int varNum = 0;
    Block * itr = this;
    std::vector<Var*> collectVar;
    while(itr) {
        if(varType == "") {
            varNum += itr->vars.size();
            for(auto b = itr->vars.begin(); b != itr->vars.end(); b++) {
                collectVar.push_back(*b);
            }
        } else {
            for(auto b = itr->vars.begin(); b != itr->vars.end(); b++) {
                if((*b)->typeName == varType) {
                    varNum++;
                    collectVar.push_back(*b);
                }
            }
        }
        itr = itr->pre;
    }
    Var * var = nullptr;
    if(varNum > 0) {
        int index = arc4random() % varNum;
        var = collectVar[index];
    }
    if(var) {
        adapterOrder(var->order);
        return var;
    }
    return nullptr;
}

void Block::adapterOrder(int dep_order) {
    minOrder = (minOrder < dep_order + 1) ? dep_order + 1 : minOrder;
    maxOrder = minOrder > maxOrder ? minOrder : maxOrder;
}

Block::~Block() {
   for(auto itr = lines.begin(); itr != lines.end(); itr++) {
       delete(*itr);
   }
}

Method * Block::randomAGlobalMethod() {
    std::vector<Method*> collectVar;
    Block * itr = this;
    int methodNum = 0;
    while(itr) {
        methodNum += itr->methods.size();
        itr = itr->pre;
    }
    if(methodNum > 0) {
        int index = arc4random() % methodNum;
        itr = this;
        while(itr) {
            if(index < itr->methods.size()) {
                return itr->methods[methodNum];
            }
            index -= itr->methods.size();
            itr = itr->pre;
        }
    }
    return nullptr;
}

void Block::addGlobalMethod(Method* m) {
    methods.push_back(m);
}

int Block::getLastLineOrder() {
    return __ORDER_MAX__--;
}

Var * Block::getVarByName(std::string ref)
{
    for(int i = vars.size() - 1; i >= 0; i-- ) {
        Var * var = vars[i];
        if(var->varName == ref) {
            return var;
        }
    }
    return nullptr;
}

void Block::addToBefore(std::string code) {
    beforeCode += code;
}

void Block::addToAfter(std::string code) {
    afterCode += code;
}

void Block::mergeCode(std::string & code) {
    sort(lines.begin(), lines.end(), cmpLine);
    if(beforeCode.length() > 0) {
        code += beforeCode;
    }
    for(int i = 0; i < lines.size(); i++) {
        auto bl = dynamic_cast<Block*>(lines[i]);
        if(bl) {
            bl->mergeCode(code);
        } else {
            auto ln = dynamic_cast<CodeLine*>(lines[i]);
            if(ln) {
                code += (ln ->noLn ? "" : "\n") + ln->code;
            }
        }
    }
    code += afterCode;
}

}
