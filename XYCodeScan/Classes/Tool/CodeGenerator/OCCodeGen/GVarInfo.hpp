//
//  GCVarInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GVarInfo_hpp
#define GVarInfo_hpp

#include <stdio.h>
#include <string>

namespace ocgen {

typedef struct VarInfo
{
    VarInfo() : order(-1)
    {}
    std::string name;
    std::string type;
    int order; // 创建的变量所在代码块的级别
} VarInfo;

}

#endif /* GCVarInfo_hpp */
