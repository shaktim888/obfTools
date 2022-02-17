//
//  XCodeFactory.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#ifndef XCodeFactory_hpp
#define XCodeFactory_hpp
#include <stdio.h>
#include <string>
#include "XContext.h"
#include <map>
#include <stack>
#include "XCodeParser.hpp"

namespace hygen {

class CodeFactory : public CodeParserDelegate
{
    std::map<int, std::vector<std::string>> trueTpMap;
    std::map<int, std::vector<std::string>> falseTpMap;
    
    std::map<int, std::map<std::string, std::string>> trueOpTp;
    std::map<int, std::map<std::string, std::string>> falseOpTp;
    
    bool checkFunctionIsConflict(Method * fromMethod, Method * toMethod);
    void supportType(int type);
    void loadAllTpFile();
    void loadTpFolder(bool isTrue);
    
    bool randomABlock(bool isTrue);
    void execOp(bool isTrue, std::string typeName);
    
    Context * context;
    std::stack<CodeParser*> coro_stack;
    CodeParser * topParser;
    std::stack<int> codeDepthStack;
    int curNeedWait;
    TypeManager * typeManager;
    CodeFactory();
    bool onToken(CodeParser * parser, const std::string& token, std::string &code);
    void onParseFinish(CodeParser * parser, std::string& collect);
    
public:
    static CodeFactory * factory() {
        static CodeFactory * _instance = new CodeFactory();
        return _instance;
    }
    ~CodeFactory();
    bool isStart();
    void popCodeStack();
    void start(CodeMode m, bool isInsert);
    std::string finish();
    void storeCodeParserStack();
    
    void enterBlock(std::string code);
    void exitBlock(std::string code);
    
    void insertToBefore(std::string code);
    void appendToAfter(std::string code);
    void resetTopParser();
    void insertCode(std::string code, bool canWrap, bool insertCode = true);
    // 生成一行, 是否被中断了
    bool genCode(bool mustRun , bool canWrap, bool notParser = false);
    // 生成一个条件出来
    std::string genCondition(bool mustTrue);
};

}


#endif /* XCodeFactory_hpp */
