//
//  CG_TypeManager.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_TypeManager_hpp
#define CG_TypeManager_hpp
#include "CG_ClassInfo.hpp"

#include <stdio.h>

namespace gen {

class TypeManager {
public:
    HYClassInfo * curClass;
    TypeManager() :curClass(nullptr){
        buildDefaultTypes();
        buildDefaultClass();
    }
    std::map<std::string, HYClassInfo*> classMap;
    std::map<int, HYEntityType*> typeMap;
    HYClassInfo * genEmptyClass(int classType,const char *className);
    void buildDefaultTypes();
    void buildDefaultClass();
    HYEntityType *getOrCreateType(int type, HYClassInfo * cls = nullptr);
    HYClassInfo *findOneExistClass(int classType);
    int getEntityTypeByClassType(int classType);
    const std::vector<int> getTypes(int classType);
    const std::vector<int> getMethodTypes(int classType);
    // 获得所有支持的逻辑类型
    virtual const std::vector<int>& getLogicTypes();
    static std::string genRandomString(bool isFileName);
    // 生成类型值
    virtual std::string _genTypeValueByType(HYEntityType * type);
    virtual std::string _genTypeValueByClass(int type, HYClassInfo * cls = nullptr);
    virtual std::string _genTypeValueByName(int type, const char * className);
    
    std::string getTypeName(HYVarInfo * var);
    int getClassTypeByMethodType(int methodType);
};

}

#endif /* CG_TypeManager_hpp */
