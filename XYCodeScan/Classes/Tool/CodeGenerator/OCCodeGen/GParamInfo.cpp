//
//  OCParamInfo.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "GParamInfo.hpp"
namespace ocgen {

ParamInfo * ParamInfo::copy() {
    auto p = new ParamInfo();
    p->name = name;
    p->type = type;
    p->var = var;
    return p;
}

}
