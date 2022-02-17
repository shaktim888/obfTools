//
//  CG_NewGenerator.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/27.
//

#ifndef CG_NewGenerator_hpp
#define CG_NewGenerator_hpp
#include "CG_Context.hpp"

#include <stdio.h>

namespace gen {
class CodeMgr
{
public:
    RuntimeContext* createContext();
    void getOneCode(RuntimeContext * context);
    void genTrueCond(RuntimeContext * context);
    void genFalseCond(RuntimeContext * context);
    void enterBlock(RuntimeContext * context);
    void exitBlock(RuntimeContext * context);
};
}

#endif /* CG_NewGenerator_hpp */
