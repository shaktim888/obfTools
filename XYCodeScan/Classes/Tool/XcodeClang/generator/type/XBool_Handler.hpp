//
//  XBool_Handler.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/3.
//

#ifndef XBool_Handler_hpp
#define XBool_Handler_hpp

#include <stdio.h>
#include "XTypeDelegate.h"

namespace hygen {

class Bool_Handler : public TypeDelegate
{
public:
    
    int supportMode() override;
    
    void supportTypes(hygen::CodeMode cmode, bool isRun, std::vector<struct TypeWeight*> &vec) override;
    
    std::string newInst(hygen::Context *, std::string &typeName, float &maxValue, float &minValue, bool forceCreate) override;
    
    void onCall(hygen::Context *, hygen::Var *) override;
    
    std::string formatName(Context*, std::string) override;
    
    std::string getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
};

}
#endif /* XBool_Handler_hpp */
