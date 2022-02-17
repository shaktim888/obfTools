//
//  ClassInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef ClassInfo_hpp
#define ClassInfo_hpp

#include "GBaseType.hpp"
#include "GMethodInfo.hpp"


namespace ocgen {

class OCClassInfo : public BaseType
{
    void initByOneLine(std::string &s) override;
public:
    
    std::vector<struct MethodInfo*> createMethods;
    std::vector<struct MethodInfo*> initMethods;
    std::vector<struct MethodInfo*> publicMethods;
    std::vector<struct MethodInfo*> customMethods;
    std::vector<struct MethodInfo*> interfaceMethods;
    std::vector<struct PropInfo*> props;
    std::string superclass;
    std::string genOneInstance(RuntimeContext * context) override;
    void objectCall(RuntimeContext * context, VarInfo * b) override;
    std::string execABoolValue(RuntimeContext * context, VarInfo * var) override;
    
    ~OCClassInfo();
};


}

#endif /* ClassInfo_hpp */
