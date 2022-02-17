//
//  GCInterfaceInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GInterfaceInfo_hpp
#define GInterfaceInfo_hpp

#include <stdio.h>
#include <string>
#include <vector>

namespace ocgen {

class MethodInfo;

class InterfaceType
{
public:
    int weight;
    std::string name;
    std::string libName;
    std::vector<MethodInfo*> methods;
};

}
#endif /* GInterfaceInfo_hpp */
