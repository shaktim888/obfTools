//
//  XCMethod.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/5.
//

#ifndef XCMethod_hpp
#define XCMethod_hpp

#include <stdio.h>
#include "XMethod.h"

namespace hygen {

class CMethod : public Method {
    
    std::string getDeclareString(Context *context) override;
    
    void onDeclare(Context *) override;
    
    void onBody(Context *) override;
    
    void onCall(Context *, Var *) override;
};

}
#endif /* XCMethod_hpp */
