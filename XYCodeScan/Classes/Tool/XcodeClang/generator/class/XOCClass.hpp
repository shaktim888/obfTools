//
//  XOCClass.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#ifndef XOCClass_hpp
#define XOCClass_hpp

#include <stdio.h>
#include "XClass.h"
#include "XOCMethod.hpp"
#include "XOCPropInfo.hpp"

namespace hygen {

enum OCClassType
{
    OCClassType_NONE,
    OCClassType_Class,
    OCClassType_Struct,
    OCClassType_Enum,
};


class OCClass : public BaseClass
{
    std::string getRealCall(Context * context);
    std::string superclass;
    
    void createCtorMethod(Context * context);
    
public:
    std::vector<struct OCMethod*> createMethods;
    std::vector<struct OCMethod*> initMethods;
    std::vector<struct OCMethod*> publicMethods;
    std::vector<struct OCMethod*> customMethods;
    std::vector<struct OCMethod*> interfaceMethods;
    std::vector<struct PropInfo*> props;
    
    std::string onCreate(Context*) override;
    void onDeclare(Context *) override;
    void onBody(Context *) override;
    
    std::string genBool(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
    void onCall(Context *, Var*) override;
    
};

}
#endif /* XOCClass_hpp */
