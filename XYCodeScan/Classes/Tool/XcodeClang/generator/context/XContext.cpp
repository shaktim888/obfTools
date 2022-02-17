//
//  XContext.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#include <stdio.h>
#include "XContext.h"
#include "XCommanFunc.hpp"

using namespace hygen;

void Context::addDep(std::string clsName) {
    addedLib[clsName] = true;
}

void Context::removeDep(std::string clsName) {
    addedLib.erase(clsName);
}

void Context::enterBlock(std::string str) {
    depth++;
    Block * b = new Block(this);
    b->context = this;
    b->beforeCode += str;
    if(curBlock) {
        b->order = curBlock->getCurMaxOrder();
        b->pre = curBlock;
        curBlock->addLine(b, false);
        curBlock = b;
    } else {
        rootBlock = b;
        curBlock = b;
    }
}

void Context::exitBlock(std::string str) {
    if(curBlock) {
        depth--;
        curBlock->afterCode += str;
        curBlock = curBlock->pre;
    } else {
        rootBlock->afterCode += str;
    }
}

void Context::popToDepth(int d) {
    for(int i= depth; i > d; i--) {
        exitBlock("");
    }
}

void Context::getFullCode(std::string & code) {
    rootBlock->mergeCode(code);
}
