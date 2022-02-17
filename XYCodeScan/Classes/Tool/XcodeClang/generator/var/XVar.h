//
//  XVar.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XVar_h
#define XVar_h

#include <string>

namespace hygen
{

class Var
{
public:
    Var(): minValue(0),maxValue(0),canCalc(false)
    {}
    virtual ~Var(){}
    
    std::string varName;
    std::string typeName;
    float minValue;
    float maxValue;
    bool canCalc;
    int order;
    
    virtual Var * copy() {
        auto itm = new Var();
        itm->canCalc = canCalc;
        itm->maxValue = maxValue;
        itm->minValue = minValue;
        itm->varName = varName;
        return itm;
    }
};

}
#endif /* XVar_h */
