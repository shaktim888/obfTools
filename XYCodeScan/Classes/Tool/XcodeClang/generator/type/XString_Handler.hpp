//
//  XString_Handler.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/4.
//

#ifndef XString_Handler_hpp
#define XString_Handler_hpp
#include "XTypeDelegate.h"

#include <stdio.h>
namespace hygen {

class String_Handler : public TypeDelegate
{
public:
    
    int supportMode() override;
    
    void supportTypes(hygen::CodeMode cmode, bool isRun, std::vector<struct TypeWeight*> &vec) override;
    
    std::string newInst(hygen::Context *, std::string &typeName, float &maxValue, float &minValue, bool forceCreate) override;
    
    void onCall(hygen::Context *, hygen::Var *) override;
    
    std::string formatName(Context*, std::string) override;
    
    std::string getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue) override ;
    
};

}
#endif /* XString_Handler_hpp */
