//
//  XCXXClass.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/6.
//

#include "XCXXClass.hpp"
#include "XCodeLine.h"
#include "XContext.h"
#include "XCXXMethod.hpp"

using namespace hygen;

std::string CXXClass::onCreate(hygen::Context *) { 
    return "new " + name + "()";
}

void CXXClass::onDeclare(hygen::Context * context) {
    /*
     class name {
     public:
     body
     };
     */
    context->enterBlock(("class " + name + " {").c_str());
    {
        auto line = new CodeLine();
        line->code = "public:";
        line->order = -98;
        context->curBlock->addLine(line);
    }
    {
        auto line = new CodeLine();
        line->code = name +"();";
        line->order = context->curBlock->genAnOrder();
        context->curBlock->addLine(line);
    }
    for(auto itr = methods.begin(); itr != methods.end(); itr++) {
        (*itr)->onDeclare(context);
    }
    
    context->exitBlock("}");
}

void CXXClass::createCtorMethod(hygen::Context * context) {
    context->enterBlock(name + "::" + name + "{");
    for(auto itr = fields.begin(); itr != fields.end(); itr++ ){
        auto line = new CodeLine();
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        line->code = (*itr)->varName + " = " + context->curBlock->createVar((*itr)->typeName, mx1, mn1) + ";";
        (*itr)->maxValue = mx1;
        (*itr)->minValue = mn1;
        line->order = context->curBlock->genAnOrder();
        context->curBlock->addLine(line);
    }
    context->exitBlock("}");
}

void CXXClass::onBody(hygen::Context * context) {
    // 创建一个构造函数
    createCtorMethod(context);
    
    for(auto itr = fields.begin(); itr != fields.end(); itr++) {
        auto var = (*itr)->copy();
        var->order = 0;
        context->curBlock->addVar(var);
    }
    
    for(auto itr = methods.begin(); itr != methods.end(); itr++) {
        (*itr)->onBody(context);
    }
}

std::string CXXClass::genBool(hygen::Context *context, hygen::Var *var, bool isTrue) { 
    std::vector<CXXMethod*> vec;
    for(auto itr = methods.begin(); itr != methods.end(); itr++) {
        if((*itr)->canCalc) {
            vec.push_back(*itr);
        }
    }
    if(vec.size() > 0) {
        CXXMethod* m = vec[arc4random() % vec.size()];
        Var tmp;
        tmp.varName = m->getRealCall(context, var);
        tmp.typeName = m->retType;
        tmp.maxValue = m->maxValue;
        tmp.minValue = m->minValue;
        tmp.canCalc = true;
        return context->manager->getBooleanValue(context, &tmp, isTrue);
    }
    if(isTrue) {
        return var->varName;
    } else {
        return "!" + var->varName;
    }
}

void CXXClass::onCall(hygen::Context * context, hygen::Var * var) {
    int cnt = fields.size();
    cnt += methods.size();
    int index =arc4random() % cnt;
    if(index < fields.size()) {
        Var * field = fields[index];
        auto line = new CodeLine();
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        line->code = var->varName + "->" + field->varName + " = " + context->curBlock->createVar(field->typeName, mx1, mn1) + ";";
        field->maxValue = mx1;
        field->minValue = mn1;
        line->order = context->curBlock->genAnOrder();
        context->curBlock->addLine(line);
    } else {
        CXXMethod* mm = methods[index - fields.size()];
        mm->onCall(context, var);
    }
}
