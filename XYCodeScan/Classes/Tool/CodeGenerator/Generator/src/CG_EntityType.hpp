//
//  CG_EntityType.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_EntityType_hpp
#define CG_EntityType_hpp

#include <stdio.h>
#include "CG_Base.hpp"

namespace gen {

class HYClassInfo;
        
typedef std::function<std::string(void)> GenEntityFunction;

struct HYEntityType {
    HYEntityType(int _type, HYClassInfo * _cls = nullptr) : typeKey(_type),
    cls(_cls),
    isCache(false),
    genEntity(nullptr) {
        
    }
    bool isEqual (const HYEntityType * other) const {
        return typeKey == other->typeKey && cls == other->cls;
    }
    int typeKey;
    std::string name;
    HYClassInfo * cls; // 记录类型
    GenEntityFunction genEntity;
    bool isCache;
};

}

#endif /* CG_EntityType_hpp */
