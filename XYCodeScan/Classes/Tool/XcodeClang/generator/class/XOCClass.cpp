//
//  XOCClass.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#include "XOCClass.hpp"
#include "XCodeLine.h"
#include "XContext.h"

using namespace hygen;

//----------------OCClass
std::string OCClass::onCreate(Context* context) {
    size_t total = createMethods.size() + initMethods.size();
    if(total > 0) {
        int index = arc4random() % total;
        if(index < createMethods.size()) {
            OCMethod* m = createMethods[index];
            std::string _call = m->getRealCall(context, nullptr);
            return _call;
        } else {
            OCMethod* m = initMethods[index - createMethods.size()];
            std::string _call = m->getRealCall(context, nullptr);
            return _call;
        }
    } else {
        return "[[" + name + " alloc] init]";
    }
}

void OCClass::onDeclare(Context * context) {
    context->enterBlock("@interface " + name + ": " + superclass);
    for(auto itr = interfaceMethods.begin(); itr != interfaceMethods.end(); itr++ ) {
        (*itr)->onDeclare(context);
    }
    for(auto itr = customMethods.begin(); itr != customMethods.end(); itr++ ) {
        (*itr)->onDeclare(context);
    }
    context->exitBlock("@end");
}

void OCClass::onBody(Context * context) {
    createCtorMethod(context);
    context->enterBlock("@implementation " + name);
    for(auto itr = interfaceMethods.begin(); itr != interfaceMethods.end(); itr++ ) {
        (*itr)->onBody(context);
    }
    for(auto itr = customMethods.begin(); itr != customMethods.end(); itr++ ) {
        (*itr)->onBody(context);
    }
    context->exitBlock("@end");
}

void OCClass::createCtorMethod(Context * context) {
    context->enterBlock("- (instancetype)init {");
    {
        auto line = new CodeLine();
        line->code = "self = [super init];";
        line->order = context->curBlock->getCurMaxOrder();
        context->curBlock->addLine(line);
    }
    {
        auto line = new CodeLine();
        line->code = "if (self) {";
        line->order = context->curBlock->getCurMaxOrder();
        context->curBlock->addLine(line);
    }
    for(auto itr = props.begin(); itr != props.end(); itr ++) {
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        auto line = new CodeLine();
        line->code = "self." + (*itr)->varName + " = " + context->curBlock->selectOrCreateVar((*itr)->typeName, mx1, mn1);
        line->order = context->curBlock->getCurMaxOrder();
        context->curBlock->addLine(line);
        (*itr)->maxValue = mx1;
        (*itr)->minValue = mn1;
    }
    {
        auto line = new CodeLine();
        line->code = "}";
        line->order = context->curBlock->getCurMaxOrder();
        context->curBlock->addLine(line);
    }
    {
        auto line = new CodeLine();
        line->code = "return self;";
        line->order = context->curBlock->getCurMaxOrder();
        context->curBlock->addLine(line);
    }
    context->exitBlock("}");
}

void OCClass::onCall(Context * context, Var* var) {
    int cnt = 0;
    cnt += props.size();
    cnt += publicMethods.size();
    cnt += customMethods.size();
    if(cnt > 0) {
        cnt = arc4random() % cnt;
        if(cnt < props.size()){
            PropInfo * p = props[cnt];
            p->onCall(context, var);
        } else {
            OCMethod * m = cnt < props.size() + publicMethods.size() ? publicMethods[cnt - props.size()] : customMethods[cnt - props.size() - publicMethods.size()];
            m->onCall(context, var);
        }
    }
}

std::string OCClass::genBool(hygen::Context *context, hygen::Var *var, bool isTrue) {
    std::vector<struct OCMethod*> vec;
    for(auto itr = publicMethods.begin(); itr != publicMethods.end(); itr++) {
        if((*itr)->canCalc) {
            vec.push_back(*itr);
        }
    }
    for(auto itr = customMethods.begin(); itr != customMethods.end(); itr++) {
        if((*itr)->canCalc) {
            vec.push_back(*itr);
        }
    }
    
    if(vec.size() > 0) {
        OCMethod * m = vec[arc4random() % vec.size()];
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
