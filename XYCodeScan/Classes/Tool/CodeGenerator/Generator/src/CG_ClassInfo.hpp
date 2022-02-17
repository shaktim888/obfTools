//
//  CG_ClassInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_ClassInfo_hpp
#define CG_ClassInfo_hpp

#include <stdio.h>
#include "CG_Base.hpp"
#include "CG_VarInfo.hpp"
#include "CG_MethodInfo.hpp"

namespace gen {

struct HYClassInfo {
    HYClassInfo(int _type, std::string _name):classType(_type),
    constructor(nullptr),
    name(_name),
    genEntity(nullptr),
    isSystem(false),
    weight(1),
    isCanCreate(true)
    {
        
    }
    ~ HYClassInfo()
    {
        if(constructor)
        {
            delete constructor;
            constructor = nullptr;
        }
        while(methods.size() > 0) {
            auto t = methods.back();
            methods.pop_back();
            delete t;
        }
        while(members.size() > 0) {
            auto t = members.back();
            members.pop_back();
            delete t;
        }
    }
    std::string name;
    int classType;
    bool isSystem;
    bool isCanCreate;
    GenEntityFunction genEntity;
    HYMethodInfo * constructor;
    std::set<HYClassInfo *> usedClass;
    std::vector<HYMethodInfo *> methods;
    std::vector<HYVarInfo *> members;
    std::string declare;
    std::string body;
    int weight;
};

}

#endif /* CG_ClassInfo_hpp */
