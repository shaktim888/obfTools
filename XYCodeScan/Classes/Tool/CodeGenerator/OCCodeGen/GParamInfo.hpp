//
//  OCParamInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef OParamInfo_hpp
#define OParamInfo_hpp

#include <stdio.h>
#include <string>
using namespace std;

namespace ocgen {

typedef struct ParamInfo
{
    string type;
    string name;
    string var;
    
    ParamInfo* copy();
} ParamInfo;

}
#endif /* OCParamInfo_hpp */
