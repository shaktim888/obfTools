//
//  GCPropInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GPropInfo_hpp
#define GPropInfo_hpp

#include <stdio.h>
#include <string>
namespace ocgen {

typedef struct PropInfo
{
    PropInfo():readonly(false),writeonly(false)
    {}
    std::string name;
    std::string ret;
    bool readonly;
    bool writeonly;
    PropInfo * copy() ;
} PropInfo;

}
#endif /* GCPropInfo_hpp */
