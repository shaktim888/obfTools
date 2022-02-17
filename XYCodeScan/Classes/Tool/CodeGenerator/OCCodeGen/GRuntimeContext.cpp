//
//  RuntimeContext.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/8.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "GRuntimeContext.hpp"
namespace ocgen {

void RuntimeContext::enterBlock() {
    Block * b = new Block();
    b->context = this;
    if(curBlock) {
        b->depth = curBlock->depth + 1;
        b->self_order = curBlock->getCurMaxOrder();
        b->pre = curBlock;
        curBlock->childs.push_back(b);
        curBlock = b;
    } else {
        rootBlock = b;
        curBlock = b;
    }
}

void RuntimeContext::exitBlock() {
    if(curBlock) {
        curBlock = curBlock->pre;
    }
}

}
