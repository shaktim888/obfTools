//
//  XMethod.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XMethod_h
#define XMethod_h

#include <vector>
#include <string>
#include "XCallable.h"
#include "XVar.h"
#include <set>

namespace hygen
{

class Context;
class BaseClass;

class Method : public ICallable
{
public:
    BaseClass * cls;
    std::string methodName;
    std::vector<Var*> params;
    std::string retType;
    int methodType;
    std::set<Method *> called;
    float minValue;
    float maxValue;
    bool canCalc; // 是否可计算结果
    
public:
    Method(BaseClass * c):minValue(0),maxValue(0),canCalc(false),cls(c)
    {}
    
    virtual std::string getDeclareString(Context * context) = 0;
    
    virtual ~Method() {}
    virtual void onDeclare(Context*) = 0;
    virtual void onBody(Context*) = 0;
    
};

}

#endif /* XMethod_h */
