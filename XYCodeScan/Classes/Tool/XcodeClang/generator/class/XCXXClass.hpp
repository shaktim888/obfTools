//
//  XCXXClass.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/6.
//

#ifndef XCXXClass_hpp
#define XCXXClass_hpp

#include <stdio.h>
#include <vector>
#include "XClass.h"
#include "XCXXMethod.hpp"

namespace hygen {

class CXXClass : public BaseClass {

    void createCtorMethod(Context * context);
    
public:
    std::vector<CXXMethod* > methods;
    std::vector<Var *> fields;
    
    std::string onCreate(hygen::Context *) override;
    
    void onDeclare(hygen::Context *) override;
    
    void onBody(hygen::Context *) override;
    
    std::string genBool(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
    void onCall(hygen::Context *, hygen::Var *) override;
    
};

}

#endif /* XCXXClass_hpp */
