//
//  CG_VarInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_VarInfo_hpp
#define CG_VarInfo_hpp

#include <stdio.h>
#include "CG_EntityType.hpp"

namespace gen {

typedef struct HYVarInfo {
    HYVarInfo(HYEntityType* _type): type(_type)
    {
    }
    ~HYVarInfo() {
        if(!type->isCache) {
            delete type;
        }
    }
    HYVarInfo * clone() {
        HYVarInfo * c = nullptr;
        if(type->isCache) {
            c = new HYVarInfo(type);
        } else {
            c = new HYVarInfo(new HYEntityType(type->typeKey, type->cls));
        }
        c->name = name;
        c->val = val;
        return c;
    }
    HYEntityType * type;
    std::string name;
    std::string val;
} HYVarInfo;


}
#endif /* CG_VarInfo_hpp */
