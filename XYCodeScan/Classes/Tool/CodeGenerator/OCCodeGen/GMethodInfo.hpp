//
//  GCMethodInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GMethodInfo_hpp
#define GMethodInfo_hpp

#include <stdio.h>
#include <string>
#include <vector>
namespace ocgen {

enum B_EMethod
{
    B_EMethod_NONE,
    B_Method,
    B_Init,
    B_Create,
    B_Property,
    B_Interface,
};

B_EMethod getEMethodByString(std::string & type);

class RuntimeContext;
class ParamInfo;
typedef struct MethodInfo
{
    MethodInfo():isconst(false)
    {}
    std::string call;
    std::string declare;
    B_EMethod methodType;
    bool isconst;
    std::string retType;
    std::string name;
    std::vector<ParamInfo*> params;
    std::string& getDeclareString(RuntimeContext * context);
    void genDeclare(RuntimeContext * context);
    std::string getRealCall(RuntimeContext * context);
    
    
    MethodInfo * copy();
    
} MethodInfo;

}
#endif /* GCMethodInfo_hpp */
