//
//  XContext.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XContext_h
#define XContext_h
#include "XClass.h"
#include "XMethod.h"
#include "XTypeManager.h"
#include "XBlock.h"

namespace hygen
{

enum CodeMode
{
    CodeMode_C = 1 << 0,
    CodeMode_CXX = 1 << 1,
    CodeMode_OC = 1 << 2,
};

class CodeFactory;

class Context
{
public:
    Context(CodeFactory * _f, CodeMode m, bool _insert):
    factory(_f),
    cmode(m),
    depth(0),
    cls(nullptr),
    curMethod(nullptr),
    manager(nullptr),
    curBlock(nullptr),
    isInsert(_insert),
    remainLine(0)
    {
        enterBlock("");
    }

public:
    CodeFactory * factory;
    std::map<std::string, bool> addedLib;
    CodeMode cmode;
    BaseClass * cls;
    Method * curMethod;
    TypeManager* manager;
    Block * curBlock; // 代码块
    Block * rootBlock;
    int remainLine;
    int depth;
    bool isInsert;
public:
    void addDep(std::string typeName);
    void removeDep(std::string typeName);
    void enterBlock(std::string str);
    void exitBlock(std::string str);
    void popToDepth(int d);
    void getFullCode(std::string&);

};

}

#endif /* XContext_h */
