//
//  XClass.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XClass_h
#define XClass_h

#include <map>
#include <vector>
#include "XMethod.h"
#include "XCallable.h"

namespace hygen
{

class Context;

class BaseClass : public ICallable
{
public:
    std::string name;
    std::string libName;
    int classType;
    
    virtual ~BaseClass(){}
    
    virtual std::string onCreate(Context*) =0;
    virtual void onDeclare(Context*) = 0;
    virtual void onBody(Context*) = 0;
    virtual std::string genBool(Context* context, Var* var, bool isTrue) = 0;
};

}

#endif /* XClass_h */
