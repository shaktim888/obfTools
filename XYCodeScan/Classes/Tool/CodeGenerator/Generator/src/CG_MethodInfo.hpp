//
//  CG_MethodInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_MethodInfo_hpp
#define CG_MethodInfo_hpp

#include <stdio.h>
#include "CG_Base.hpp"
#include "CG_VarInfo.hpp"

namespace gen {

struct HYClassInfo;

struct HYMethodInfo
{
    HYMethodInfo(int _methodType) : methodType(_methodType)
    , retType(nullptr), isPublic(true), isObject(true), parent(nullptr),deep(0)
    {
        if(methodType == Method_Cplus_Private || methodType == Method_Cplus_Protected) {
            isPublic = false;
        }
        if(methodType == Method_C_OC || methodType == Method_C) {
            isObject = false;
        }
        called.clear();
    }
    ~ HYMethodInfo()
    {
        while(args.size() > 0) {
            auto t = args.back();
            args.pop_back();
            delete t;
        }
    }
    HYClassInfo * parent;
    int methodType;
    int deep;
    std::string name;
    std::vector<HYVarInfo *> args; // 记录类型的参数
    HYVarInfo* retType; // 返回值类型
    std::string declare; // 声明
    std::string body; // 方法实体
    bool isPublic; // 是否公开
    bool isObject; // 是否属于对象
    std::set<HYMethodInfo *> called; // 仅仅记录调用过的函数,防止循环调用，无需管理内存
};

}

#endif /* CG_MethodInfo_hpp */
