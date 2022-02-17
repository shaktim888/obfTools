//
//  RuntimeContext.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/8.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef RuntimeContext_hpp
#define RuntimeContext_hpp

#include <stdio.h>
#include "GOCClassInfo.hpp"
#include "GAllTypeManager.hpp"
#include "GMethodInfo.hpp"
#include "GBlock.hpp"

namespace ocgen {

class RuntimeContext
{
public:
    RuntimeContext()
    :cls(nullptr) ,curMethod(nullptr) ,manager(nullptr)
    ,curBlock(nullptr) ,remainLine(0)
    {}
    OCClassInfo * cls;
    MethodInfo * curMethod;
    AllTypeManager* manager;
    Block * curBlock; // 代码块
    Block * rootBlock;
    int remainLine;
    
    void resetOrder();
    
    void enterBlock();
    
    void exitBlock();
};

}

#endif /* RuntimeContext_hpp */
