//
//  CG_Base.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_Base_hpp
#define CG_Base_hpp

#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include <map>
#include <functional>
#include <algorithm>
#include <map>
#include "iostream"

namespace gen{

using namespace std;
    
template <class T>
int getArrSize(T& arr){
    return sizeof(arr) / sizeof(arr[0]);
}

vector<string> split(const string& str, const string& delim);
// hui
enum HYEnumMethodType
{
    Method_None,
    Method_C,
    Method_C_OC,
    Method_OC_Constructor,
    Method_Cplus_Constructor,
    
    Method_OC_Static,
    Method_OC_Object,
    Method_Cplus_Public,
    Method_Cplus_Static,
    Method_Cplus_Protected,
    Method_Cplus_Private,
    
    Method_Lua_Local,
    Method_Lua_Object,
    
    Method_Js_Local,
    Method_Js_Object,
};


enum HYEnumLogicType {
    Logic_None,
    Logic_VarOperation = Logic_None + 3,
    Logic_CreateVar = Logic_VarOperation + 1,
    Logic_CallExistFunc = Logic_CreateVar + 3,
    Logic_IF = Logic_CallExistFunc + 2,
    Logic_While = Logic_IF + 1,
    Logic_For = Logic_While + 1,
    
    Logic_Lua_Func_Create,
//    Logic_RETURN,
};

enum HYEnumTypes
{
    Type_NULL,
    Class_OC,
    Class_Cplus,
    Class_Lua,
    Class_Js,
//    OC_NSString,
//    OC_NSArray,
//    OC_NSDictionary,
//    OC_NSMutableArray,
//    OC_NSMutableDictionary,
//    OC_NSMutableSet,
//    OC_NSNumber,
    C_int,
    C_float,
    C_double,
    C_char,
    C_int_ptr,
    C_float_ptr,
    C_double_ptr,
    C_char_ptr,
    C_void,
    
    Cplus_bool,
    Cplus_bool_ptr,
    
    Lua_Number,
    Lua_String,
    Lua_Table,
//    Lua_Func
    
    Js_Number,
    Js_String,
    Js_Object
};


}

#endif /* CG_Base_hpp */
