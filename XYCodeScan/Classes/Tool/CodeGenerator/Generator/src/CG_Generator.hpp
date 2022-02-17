//
//  CG_Generator.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_Generator_hpp
#define CG_Generator_hpp

#include <stdio.h>
#include "CG_Base.hpp"
#include "CG_MethodInfo.hpp"
#include "CG_ClassInfo.hpp"
#include "CG_EntityType.hpp"
#include "CG_Block.hpp"
#include "CG_VarInfo.hpp"

namespace gen {
class TypeManager;

class CodeGenerator
{
private:
    std::vector<HYMethodInfo*> localMethods;
protected:
    void clearGlobalMethod();
    void autoAppendCode(int offset, std::string & code, std::string append);
//    virtual HYClassInfo * getCustomClassByID(int type);
    // 生成函数调用
    virtual std::string genCallBody(HYCodeBlock * block, HYMethodInfo* fromMethod, HYMethodInfo * method, std::vector<HYVarInfo *>& vars, HYVarInfo * var= nullptr);
    // 生成条件语句
    virtual std::string _genConditionStr(HYCodeBlock * block, HYMethodInfo * method, HYVarInfo * var, std::vector<HYVarInfo *>& vars);
    // if
    virtual HYCodeBlock* genIfBlock(HYMethodInfo * method, std::vector<HYVarInfo *>& vars);
    // while
    virtual HYCodeBlock* genWhileBlock(HYMethodInfo * method, std::vector<HYVarInfo *>& vars);
    // for
    virtual HYCodeBlock* genForBlock(HYMethodInfo * method, std::vector<HYVarInfo *>& vars);
    // createExistClass
    virtual HYCodeBlock* genCreateEntityBlock(HYMethodInfo * method, std::vector<HYVarInfo *>& vars);
    // 生成变量操作语句
    virtual HYCodeBlock* operatorVar(HYMethodInfo * method, HYVarInfo * var, std::vector<HYVarInfo *>& vars);
    //-----------------------------------------------------------
    virtual std::string genInitAllMembers(HYClassInfo *, int deep = 1);
    // 生成一个构造函数
    virtual HYMethodInfo* genConstructorMethod(HYClassInfo * c);
    virtual int getConstructorType(int classType);
    
    HYMethodInfo * findMethodWithReturnType(bool hasToEntity, std::vector<HYMethodInfo *> &methods, HYEntityType* retType, HYMethodInfo * fromMethod);
    
    bool checkFunctionIsConflict(bool hasEntity, HYMethodInfo * fromMethod, HYMethodInfo * toMethod);
    
    HYVarInfo * selectVar(std::vector<HYVarInfo *>& vars, std::vector<HYEntityType*>& types, bool mustSelect = true, HYVarInfo * skipVar = nullptr);
    HYVarInfo * selectVar(std::vector<HYVarInfo *>& vars, HYEntityType * type, bool mustSelect = true, HYVarInfo * skipVar = nullptr);
    
//    HYVarInfo * selectVar(std::vector<HYVarInfo *>& vars, int type, HYVarInfo * fromVar , bool mustSelect = true, bool needSkip = false);
    // 获得间距字符串
    virtual std::string getGapByOffset(int offset);
      
    virtual std::string decideTypeValue(HYCodeBlock * block, HYMethodInfo* fromMethod, HYEntityType* type, std::vector<HYVarInfo *> vars, HYVarInfo * skipVar = nullptr, bool useMethod = true);
    virtual std::string decideTypeValue(HYCodeBlock * block, HYMethodInfo* fromMethod, HYEntityType* type, std::vector<HYEntityType*>& types, std::vector<HYVarInfo *> vars, HYVarInfo * skipVar = nullptr, bool useMethod = true);
    // 根据逻辑类型生成代码
    virtual HYCodeBlock* genCodeByType(HYMethodInfo * method, std::vector<HYVarInfo *>& vars, int& lines, int type );
    // 生成一个逻辑块
    std::string genBlockCode(HYMethodInfo * method, int offset, std::vector<HYVarInfo *>& vars, int& lines);
    
    std::string genMethodRetCode(int deep, HYMethodInfo * method, std::vector<HYVarInfo *>& vars);
    
    std::string _genNumberOpStr(HYCodeBlock * block, HYMethodInfo * method, HYEntityType* type, std::vector<HYVarInfo *>& vars, int deep);
    std::string _genNumberOpStr(HYCodeBlock * block, HYMethodInfo * method, HYEntityType* type, std::vector<HYEntityType*>& types, std::vector<HYVarInfo *>& vars, int deep);

    HYVarInfo * genVarDeclare(int type, bool, int classType = Type_NULL);
    // 随机生成一个函数声明
    HYMethodInfo* genMethodDeclare(HYClassInfo * parent, int methodType);
    // 决定返回
//    std::string decideReturnValue(HYCodeBlock * block, HYMethodInfo * method, std::vector<HYVarInfo *>& vars);
    // 生成一个条件语句
    std::string decideConditionStr(HYCodeBlock * block, HYMethodInfo * fromMethod, std::vector<HYVarInfo *>& vars);
    std::vector<HYMethodInfo*> selectMethodByMethodType(std::vector<HYMethodInfo *>& methods, int methodType);
    // 生成函数体
    std::string genMethodBodyStr(HYMethodInfo* method, int deep = 1, int lines = 0);

    std::string getImportHeader(HYClassInfo * cls, bool isInBody);
    HYCodeBlock * genClassDeclareBlock(HYClassInfo * cls);
    HYCodeBlock * genClassBlock(HYClassInfo * cls);
    HYCodeBlock * genMethodDeclareBlock(HYMethodInfo * method, bool isInBody);
    HYCodeBlock * genMethodBlock(HYMethodInfo * method, int lines = 0);
    
    void buildMethod(HYMethodInfo * method, int lines = 0);
    void buildClassBody(HYClassInfo * cls);
    // 生成变量生成的语句
    virtual std::string genVarDeclareStr(HYVarInfo * var);
    // 设置变量生成的语句
    virtual std::string setVarValueStr(HYVarInfo * var);
    // 生成返回值
//    std::string genReturnStr(HYVarInfo *var, HYEntityType* type);
    std::string decideBlockEnd(std::string& str);
    void addBlockCode(int offset, std::string & str, HYCodeBlock * block);
public:
    TypeManager* manager;
    
    void removeMethod(HYMethodInfo * method);
    CodeGenerator();
    ~CodeGenerator();
    // 生成类
    std::string genCallMethodString(HYMethodInfo* fromMethod, HYMethodInfo * method);
    std::string randomAddOCProperty();
    HYMethodInfo* genCallAllMethod(std::vector<HYMethodInfo*>& methods);
    HYMethodInfo* genCallAllClass(std::vector<HYClassInfo*> & classes);
    HYClassInfo * genClass(int classType);
    void buildClass(HYClassInfo * classInfo);
    HYMethodInfo * genOneClassMethod(const char * className, int methodType, int deep);
    std::vector<HYMethodInfo*> genCMethod(int num, bool isOC);
    std::string selectOneMethodToRun(bool isOC, bool isStatic, const char * className, std::vector<HYMethodInfo *>& methods, int deep);
};
}
#endif /* CG_Generator_hpp */
