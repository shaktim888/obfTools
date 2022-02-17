//
//  GCMethodInfo.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "GMethodInfo.hpp"
#include "GParamInfo.hpp"
#include "GRuntimeContext.hpp"
#include "GCommanFunc.hpp"

namespace ocgen {

B_EMethod getEMethodByString(std::string & type)
{
    if(type.find("m1") == 0) {
        return B_EMethod::B_Init;
    }
    if(type.find("m2") == 0) {
        return B_EMethod::B_Create;
    }
    if(type.find("m") == 0) {
        return B_EMethod::B_Method;
    }
    if(type.find("p") == 0) {
        return B_EMethod::B_Property;
    }
    return B_EMethod::B_EMethod_NONE;
}

MethodInfo * MethodInfo::copy()  {
   auto p = new MethodInfo();
   p->call = call;
   p->declare = declare;
   p->methodType = methodType;
   p->isconst = isconst;
   p->retType = retType;
   p->name = name;
   for(auto itr = params.begin(); itr != params.end(); itr++) {
       p->params.push_back((*itr)->copy());
   }
   return p;
}

std::string& MethodInfo::getDeclareString(RuntimeContext * context) {
    if(declare == "") {
        declare = "- (" + context->manager->formatType(retType) + ")" + name;
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            if(itr == params.begin()) {
                declare = declare + ":" + "(" + context->manager->formatType((*itr)->type) + ")" + (*itr)->var;
            } else {
                declare = declare + " " + (*itr)->name + ":" + "(" + context->manager->formatType((*itr)->type) + ")" + (*itr)->var;
            }
        }
    }
    replace_all_distinct(declare, ";", "");
    return declare;
}

void MethodInfo::genDeclare(RuntimeContext * context) {
    getDeclareString(context);
    auto fb = new Line();
    fb->code = declare + "{";
    fb->order = -999;
    context->curBlock->addLine(fb, false, true);
    
    auto fe = new Line();
    fe->code = "}";
    fe->order = context->curBlock->getLastLineOrder();
    context->curBlock->addLine(fe, false, true);
}

std::string MethodInfo::getRealCall(RuntimeContext * context) {
    if(call != ""){
        std::string callstr = call;
        int index = 0;
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            std::string ref = context->curBlock->selectOrCreateVar(context, (*itr)->type);
            replace_all_distinct(callstr, std::string("#") + to_string(index), ref);
            index++;
        }
        return callstr;
    } else {
        std::string callstr = name;
        for(auto itr = params.begin(); itr != params.end(); itr++) {
            std::string ref = context->curBlock->selectOrCreateVar(context, (*itr)->type);
            if(itr == params.begin()){
                callstr = callstr + ":" + ref;
            } else {
                callstr = callstr + " " + (*itr)->name + ":" + ref;
            }
        }
        return callstr;
    }
}
}
