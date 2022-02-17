//
//  XTypeManager.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include <stdio.h>

#include "XTypeManager.h"
#include "XTypeDelegate.h"
#include "XNum_Handler.hpp"
#include "XClass_Handler.h"
#include "XCommanFunc.hpp"
#include "XBool_Handler.hpp"
#include "XString_Handler.hpp"

using namespace hygen;

TypeDelegate* TypeManager::getDelegate(std::string name) {
    for(auto itr = types.begin(); itr!=types.end(); itr++) {
        if(name.find(itr->first) == 0) {
            return itr->second;
        }
    }
    return nullptr;
}

std::string TypeManager::formatTypeName(Context * context, std::string &tname) {
    TypeDelegate * delegate = getDelegate(tname);
    if(!delegate) {
        delegate = types["cm"];
    }
    return delegate->formatName(context, tname);
}

TypeManager::~TypeManager() {
    for(auto itr = types.begin(); itr != types.end(); itr++ ) {
        delete(itr->second);
    }
    types.clear();
}

TypeManager::TypeManager() { 
    registerAllType();
}

void TypeManager::registerAllType() {
    types["cm"] = new Class_Handler();
    types["int"] = new Num_Handler("int");
    types["float"] = new Num_Handler("float");
    types["bool"] = new Bool_Handler();
    types["string"] = new String_Handler();
}

std::string TypeManager::randomAType(hygen::Context *context, bool isRun) {
    std::vector<struct TypeWeight *> arr;
    for(auto itr = types.begin(); itr != types.end(); itr++) {
        if(itr->second->supportMode() & context->cmode) {
            itr->second->supportTypes(context->cmode, isRun, arr);
        }
    }
    int totalWeight = 0;
    for(int i = 0; i < arr.size(); i++) {
        totalWeight += arr[i]->weight;
    }
    if(totalWeight > 0) {
        int w = arc4random() % totalWeight;
        for(int i = 0; i < arr.size(); i++) {
            if(w < arr[i]->weight) {
                return arr[i]->typeName;
            }
            w -= arr[i]->weight;
        }
    }
    for(int i = 0; i < arr.size(); i++) {
        delete(arr[i]);
    }
    
    return "";
}


std::string TypeManager::createNewValue(hygen::Context *context, std::string& typeName, float &maxValue, float &minValue, bool forceCreate) {
    TypeDelegate * delegate = getDelegate(typeName);
    if(!delegate) {
        delegate = types["cm"];
    }
    return delegate->newInst(context, typeName, maxValue, minValue, forceCreate);
}

void TypeManager::call(hygen::Context *context, hygen::Var *var) {
    TypeDelegate * delegate = getDelegate(var->typeName);
    if(!delegate) {
        delegate = types["cm"];
    }
    return delegate->onCall(context, var);
}

bool TypeManager::isCanOpType(hygen::Context *context, std::string name) {
    return formatTypeName(context, name) != "";
}

std::string TypeManager::getBooleanValue(Context *context, Var *var, bool isTrue) {
    TypeDelegate * delegate = getDelegate(var->typeName);
    if(!delegate) {
        delegate = types["cm"];
    }
    std::string ret = delegate->getBooleanValue(context, var, isTrue);
    if(ret == "") {
        if(isTrue) {
            int num = arc4random() % 100 + 10;
            if(arc4random() % 2 == 0) {
                return "rand() % " + to_string(num) + " + 1 < " + to_string(num + 1);
            } else {
                return "rand() % " + to_string(num) + " + 1 > 0";
            }
        } else {
            int num = arc4random() % 100 + 10;
            return "rand() % " + to_string(num) + " + 1 > " + to_string(num + 1);
        }
    }
    return ret;
}

void TypeManager::clearAllCustomType() {
    Class_Handler * delegate = static_cast<Class_Handler*>(types["cm"]);
    delegate->removeAllCustomCls();
}

void TypeManager::addCustomType(BaseClass * cls) {
    Class_Handler * delegate = static_cast<Class_Handler*>(types["cm"]);
    delegate->addCls(cls);
}
