//
//  AllTypeManager.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef AllTypeManager_hpp
#define AllTypeManager_hpp

#include "GBaseType.hpp"
#include "GOCClassInfo.hpp"
#include "GInterfaceType.hpp"
#include <map>
#include <vector>

namespace ocgen {
using namespace std;

class AllTypeManager
{
    AllTypeManager();
    map<std::string, BaseType *> classMap;
    vector<InterfaceType *> interfaceArr;
    vector<OCClassInfo *> allCls;
    vector<OCClassInfo *> customCls;
    void loadAllType();
    void loadAllInterface();
    int interfaceTotalWeight;
    
public:
    static AllTypeManager* getInstance();
    void clearAllCustomType();
    std::string& randomAType(RuntimeContext * context, int commonWeight = 0);
    InterfaceType * randomAInterface();
    void addCustomType(BaseType * cls);
    BaseType * getType(std::string tname);
    bool isCanOpType(std::string& type);
    bool isNumType(std::string& type);
    std::string formatType(std::string& t);
};

}
#endif /* AllTypeManager_hpp */
