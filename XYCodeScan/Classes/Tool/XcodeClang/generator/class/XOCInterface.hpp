//
//  XOCInterface.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#ifndef XOCInterface_hpp
#define XOCInterface_hpp

#include <stdio.h>
#include "XClass.h"
#include "XOCMethod.hpp"

namespace hygen {

class OCInterface : public BaseClass
{
public:
    int weight;
    std::vector<OCMethod*> methods;
    
    std::string onCreate(Context*) override;
    void onDeclare(Context *) override;
    void onBody(Context *) override;
    void onCall(Context*, Var*) override;
    
    std::string genBool(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
    
};

}
#endif /* XOCInterface_hpp */
