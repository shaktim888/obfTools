#ifndef CodeGenerator_h
#define CodeGenerator_h

#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif

enum EnumGeneratorType
{
    Gen_None,
    Gen_OC,
    Gen_Cplus,
    Gen_Lua,
    Gen_Js
};

struct GenClass
{
    char * className;
    char * declare;
    char * body;
};

struct GenMethod
{
    char * methodName; // 生成函数名
    char * declare; // 函数声明
    char * body; // 函数体
    char * callBody; // 函数被调用
};

enum EnumGenMethodType
{
    Gen_Method_None,
    Gen_Method_C,
    Gen_Method_OC_Constructor,
    Gen_Method_Cplus_Constructor,
    
    Gen_Method_OC_Static,
    Gen_Method_OC_Object,
    Gen_Method_Cplus_Public,
    Gen_Method_Cplus_Static,
    Gen_Method_Cplus_Protected,
    Gen_Method_Cplus_Private,
    
    Gen_Method_Lua_Local,
    Gen_Method_Lua_Object,
};

FOUNDATION_EXPORT char * genClassToFolder(int type, int num, const char * saveFolder);
FOUNDATION_EXPORT struct GenClass * genOneClass(int type);
FOUNDATION_EXPORT struct GenMethod * genClassMemberMethod(int type, char * ClassName);
FOUNDATION_EXPORT char * genRandomOCProperty(void);

FOUNDATION_EXPORT char * genRandomString(int isFileName);
#endif
