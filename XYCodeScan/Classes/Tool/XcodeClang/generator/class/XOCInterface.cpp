//
//  XOCInterface.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#include "XOCInterface.hpp"

using namespace hygen;

//----------------OCInterface
std::string OCInterface::onCreate(Context* context) {
    return "";
}

void OCInterface::onDeclare(Context * context) {
    
}

void OCInterface::onBody(Context * context) {
    
}

void OCInterface::onCall(Context *context, Var* var) {
    
}

std::string OCInterface::genBool(hygen::Context *context, hygen::Var *var, bool isTrue) {
    return "";
}
