//
//  XTypeManager.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XTypeManager_h
#define XTypeManager_h

#include <map>
#include <string>
#include "XVar.h"
#include "XClass.h"

namespace hygen
{
class TypeDelegate;
class Context;

class TypeManager
{
    void registerAllType();
    std::map<std::string, TypeDelegate*> types;
    TypeDelegate* getDelegate(std::string name);
    std::map<int, std::vector<struct TypeWeight*>> typeWeights;
public:
    TypeManager();
    ~TypeManager();
    bool isCanOpType(Context * context, std::string name);
    std::string formatTypeName(Context * context, std::string& tname);
    std::string randomAType(Context* context, bool isRun);
    std::string createNewValue(Context * context, std::string& typeName, float &maxValue, float &minValue, bool forceCreate);
    void call(Context * context, Var * var);
    std::string getBooleanValue(Context *context, Var *var, bool isTrue);
    
    void clearAllCustomType();
    void addCustomType(BaseClass * cls);
};

}
#endif /* XTypeManager_h */
