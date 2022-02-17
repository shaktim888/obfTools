//
//  SC_ObfTools.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/16.
//

#ifndef SC_ObfTools_hpp
#define SC_ObfTools_hpp

#include <stdio.h>
#include "SC_TokenContext.hpp"
#include "CG_Generator.hpp"

namespace scan {

class ObfTools {
    gen::CodeGenerator * generator;
    std::vector<gen::HYMethodInfo*> declareMethods;
    std::string obfStringMethodName;
    
    gen::HYMethodInfo * callAllMethod;
    
    // 还没实现，返回值问题还没想到解决方案
    std::string genTrueCondition(); // 生成真条件
    std::string genFalseCondition(); // 生成假条件
    void genRunCode(TokenParser* context, CodeBlock * block, std::vector<Line*>& lines);   // 生成可执行的代码
    void genNotRunCode(TokenParser* context,CodeBlock * block, std::vector<Line*>& lines); // 生成不可执行的代码
    void genProp(CodeBlock * block);
    
    // 预处理
    void preprocess(TokenParser * context);
    
    void addHead(TokenParser * context);
    void addFunctions(TokenParser * context);
    void genStringObfMethod(TokenParser * context);
    
    void obfBlock(TokenParser* context, CodeBlock * block);
    void genOneFullFunction(CodeBlock*);
    void callStringXorMethod(CodeBlock * block);
    
    void combineBlock(CodeBlock * block, std::string& code);
    CodeBlock * findAMethodBlock(CodeBlock * block);
public:
    ObfTools();
    void start(TokenParser * context, std::string& code);
    void insert(TokenParser * context, std::string& code, const char * import, const char * insertcode);
    
};

}

#endif /* SC_ObfTools_hpp */
