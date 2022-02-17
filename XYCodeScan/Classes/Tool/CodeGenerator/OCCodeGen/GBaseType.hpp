//
//  BaseType.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef BaseType_hpp
#define BaseType_hpp

#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include "GVarInfo.hpp"

namespace ocgen {

#define IMPORT_ORDER -10000

using namespace std;

enum B_Type
{
    B_NONE,
    B_Class,
    B_Struct,
    B_Enum,
};

B_Type getBTypeByString(std::string & type);

class RuntimeContext;
class BaseType
{
public:
    std::map<std::string, bool> addedLib;
    std::string name;
    std::string libName;
    B_Type b_type;
    void addDep(RuntimeContext * context, std::string typeName);
    void removeDep(RuntimeContext * context, std::string clsName);
    virtual std::string genOneInstance(RuntimeContext * context) =0;
    virtual void objectCall(RuntimeContext * context, VarInfo * b) =0;
    virtual void initByOneLine(std::string& s) = 0;
    virtual std::string execABoolValue(RuntimeContext * context, VarInfo * var) = 0;
};

}
#endif /* BaseType_hpp */
