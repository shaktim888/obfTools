//
//  XInt_Handler.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/1.
//

#ifndef XInt_Handler_hpp
#define XInt_Handler_hpp
#include "XTypeDelegate.h"

#include <stdio.h>

namespace hygen {

class Num_Handler : public TypeDelegate
{
private:
    std::string typeName;
    
public:
    Num_Handler(const char * _name) : typeName(_name) {
        
    }
    
    int supportMode() override;
    
    void supportTypes(hygen::CodeMode cmode, bool isRun, std::vector<struct TypeWeight*> &vec) override;
    
    std::string newInst(hygen::Context *, std::string &typeName, float &maxValue, float &minValue, bool forceCreate) override;
    
    void onCall(hygen::Context *, hygen::Var *) override;
    
    std::string formatName(Context*, std::string) override;
    
    std::string getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
};

}

#endif /* XInt_Handler_hpp */
