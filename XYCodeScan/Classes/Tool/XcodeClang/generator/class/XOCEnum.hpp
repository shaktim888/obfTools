//
//  XOCEnum.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#ifndef XOCEnum_hpp
#define XOCEnum_hpp

#include <stdio.h>
#include "XClass.h"
#include "XOCMethod.hpp"

namespace hygen {

class EnumInfo : public BaseClass
{
public:
    std::vector<std::string> items;
    
    std::string onCreate(Context*) override;
    void onDeclare(Context * context) override;
    void onBody(Context * context) override;
    void onCall(Context * context, Var*) override;
    
    std::string genBool(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
};

}

#endif /* XOCEnum_hpp */
