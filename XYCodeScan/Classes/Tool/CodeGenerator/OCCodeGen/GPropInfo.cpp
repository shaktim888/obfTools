//
//  GCPropInfo.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "GPropInfo.hpp"
namespace ocgen {

PropInfo * PropInfo::copy() {
    auto p = new PropInfo();
    p->name = name;
    p->ret = ret;
    p->readonly = readonly;
    p->writeonly = writeonly;
    return p;
}

}
