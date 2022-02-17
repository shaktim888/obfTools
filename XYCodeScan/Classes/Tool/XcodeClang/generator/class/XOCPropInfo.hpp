//
//  XOCPropInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/3.
//

#ifndef XOCPropInfo_hpp
#define XOCPropInfo_hpp

#include <stdio.h>
#include <string>
#include "XVar.h"
#include "XCallable.h"

namespace hygen {

typedef struct PropInfo : public Var, public ICallable
{
    PropInfo():Var(),readonly(false),writeonly(false)
    {}
    bool readonly;
    bool writeonly;
    PropInfo * copy() override {
        auto p = new PropInfo();
        p->maxValue = maxValue;
        p->minValue = minValue;
        p->canCalc = canCalc;
        p->varName = varName;
        p->typeName = typeName;
        p->readonly = readonly;
        p->writeonly = writeonly;
        return p;
    }
    
    void onDeclare(Context*);
    virtual void onBody(Context*);
    
    void onCall(hygen::Context *, hygen::Var *) override;
    
} PropInfo;

}

#endif /* XOCPropInfo_hpp */
