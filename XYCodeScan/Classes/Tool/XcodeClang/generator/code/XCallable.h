//
//  XCallable.h
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#ifndef XCallable_h
#define XCallable_h

namespace hygen {

class Var;
class Context;

class ICallable
{
public:
    virtual void onCall(Context*,Var*) = 0;
};

}

#endif /* XCallable_h */
