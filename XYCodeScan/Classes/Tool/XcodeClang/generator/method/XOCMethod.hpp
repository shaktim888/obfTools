//
//  XOCMethod.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#ifndef XOCMethod_hpp
#define XOCMethod_hpp

#include <stdio.h>
#include "XMethod.h"

namespace hygen {

enum OCMethodType
{
    OCMethodType_NONE = 100,
    OCMethodType_Method,
    OCMethodType_Init,
    OCMethodType_Create,
    OCMethodType_Property,
    OCMethodType_Interface,
};

class OCParam : public Var
{
public:
    std::string paramName;
};


class OCMethod : public Method
{
public:
    OCMethod(BaseClass * c) : Method(c)
    {}
    bool isconst;
    std::string declare;
    std::string call;
    
    std::string getDeclareString(Context * context) override;
    void onDeclare(Context * context) override;
    
    void onBody(Context * context) override;
    
    std::string getRealCall(Context * context, Var *var);
    void onCall(Context * context, Var * var) override;
    
};

}


#endif /* XOCMethod_hpp */
