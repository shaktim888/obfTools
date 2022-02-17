//
//  XTypeDelegate.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XTypeDelegate_h
#define XTypeDelegate_h
#include <string>
#include "XCallable.h"
#include "XVar.h"
#include "XContext.h"

namespace hygen
{

struct TypeWeight {
    std::string typeName;
    int weight;
};

class TypeDelegate : public ICallable
{
public:
    std::vector<std::string> _types;
    
    virtual ~TypeDelegate(){}
    
    virtual std::string getBooleanValue(Context* context, Var * var, bool isTrue) = 0;
    virtual std::string formatName(Context* ,std::string) = 0;
    virtual int supportMode() = 0;
    virtual void supportTypes(CodeMode cmode, bool isRun, std::vector<struct TypeWeight*>& vec) = 0;
    virtual std::string newInst(Context*, std::string& typeName, float &maxValue, float &minValue, bool forceCreate) = 0;
};

}
#endif /* XTypeDelegate_h */
