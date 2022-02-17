//
//  XCXXMethod.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/5.
//

#ifndef XCXXMethod_hpp
#define XCXXMethod_hpp

#include <stdio.h>
#include "XMethod.h"

namespace hygen {

class CXXMethod : public Method
{
public:
    std::string getDeclareString(Context * context) override;
    std::string getRealCall(Context *context, Var * var);
    void onDeclare(hygen::Context *) override;
    void onBody(hygen::Context *) override;
    void onCall(hygen::Context *, hygen::Var *) override;
};

}

#endif /* XCXXMethod_hpp */
