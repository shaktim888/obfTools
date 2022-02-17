//
//  SC_ObfTools.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/16.
//

#include "SC_ObfTools.hpp"
#include "GAllTypeManager.hpp"
#import "UserConfig.h"
#include "NameGeneratorExtern.h"

namespace scan {

template <class T>
static int getArrSize(T& arr){
    return sizeof(arr) / sizeof(arr[0]);
}

ObfTools::ObfTools()
{
    generator = new gen::CodeGenerator();
}

void ObfTools::addFunctions(TokenParser * context) {
    int num = [UserConfig sharedInstance].addMethodNum;
    std::string ret = "";
    auto vec = generator->genCMethod(num, context->curFileExt == "m" || context->curFileExt == "mm");
    for(int i = 0; i < vec.size(); i++) {
        ret += vec[i]->body + "\n";
        declareMethods.push_back(vec[i]);
    }
    callAllMethod = generator->genCallAllMethod(declareMethods);
    declareMethods.push_back(callAllMethod);
    ret += callAllMethod->body + "\n";
    context->rootBlock->before += ret;
}

std::string ObfTools::genTrueCondition() // 生成真条件
{
    return "true";
}

std::string ObfTools::genFalseCondition() // 生成假条件
{
    return "false";
}

void ObfTools::genRunCode(TokenParser* context, CodeBlock * block, std::vector<Line*>& lines)  // 生成可执行的代码
{
    if(!context->isAddCode || arc4random() % 100 >= context->prop)
        return;
    bool isOC = block->isOC();
    bool isStaticFunc = block->blockType == BLOCK_OC_METHOD_STATIC;
    auto line = new CodeLine();
    line->code = "\n" + generator->selectOneMethodToRun(isOC, isOC ? isStaticFunc : false, isOC ? block->className.c_str() : nullptr, declareMethods, block->funcDepth);
    block->allLine.push_back(line);
}

void ObfTools::genNotRunCode(TokenParser* context, CodeBlock * block, std::vector<Line*>& lines) // 生成不可执行的代码
{
    
}

void ObfTools::genOneFullFunction(CodeBlock* block)
{
    if(!block->isMethod()) {
        return;
    }
    const char * name = nullptr;
    int methodType = gen::Method_None;
    if(block->isOC()){
        name = block->className.c_str();
        methodType = arc4random() % 2 ? gen::Method_OC_Object : gen::Method_OC_Static;
    } else {
        methodType = gen::Method_C;
    }
    auto method = generator->genOneClassMethod(name, methodType, block->funcDepth);
    printf("addMethod:%s, %d\n" , method->name.c_str(), method->deep);
    declareMethods.push_back(method);
    
    block->after += "\n" + method->body;
}

void ObfTools::addHead(TokenParser * context) {
    // 1. 加载假的类型数据进来
        // 如果是oc文件 引入oc manager去拿类型（假代码）
        // 如果是c++、c代码
    std::string code = "\n";
    if(context->curFileExt == "m" || context->curFileExt == "mm") {
        code += "#import <Foundation/Foundation.h>\n";
        code += "#import <stdlib.h>\n";
    } else {
        code += "#include <stdlib.h>\n";
        code += "#include <stdio.h>\n";
    }
    context->rootBlock->before += code;
}

// 字符串加解密 方案之 静态变量控制法
void ObfTools::genStringObfMethod(TokenParser * context) {
    std::string boolVarName = string("_string_flag_") + genNameForCplus(CVarName, false);
    std::string methodName = string("_string_method_") + genNameForCplus(CFuncName, false);
    obfStringMethodName = methodName;
    std::string methodCode = "static void " + methodName + "() {\n";
    methodCode += "static unsigned char " + boolVarName + " = 0;\n";
    methodCode += "if(!" + boolVarName + "){\n";
    methodCode += boolVarName + " = 1;\n";
    std::string staticCode = "";

    for(int i = 0; i < context->cachedStr.size(); i++) {
        std::string str = context->cachedStr[i];
        bool isOCStr = str[0] == '@';
        std::string strVarName = context->getStringName(i);
        size_t p = str.find_first_of('"');
        std::string obf_v = "{";
        int c = 0;
        for(size_t j = p + 1; j <= str.length() - 1; j++) {
            char v = str[j];
            if(j == str.length() - 1) {
                v = 0;
            }
            int rv = arc4random() % 256;
            if(c == 0) {
                obf_v += to_string(int(char(v ^ rv)));
            } else {
                obf_v += "," + to_string(int(char(v ^ rv)));
            }
            if(isOCStr) {
                methodCode += "oc_" + strVarName + "[" + to_string(c) + "] ^=" + to_string(rv) + ";\n";
            } else {
                methodCode += strVarName + "[" + to_string(c) + "] ^=" + to_string(rv) + ";\n";
            }
            c++;
        }

        obf_v += "}";
        if(isOCStr) {
            methodCode += strVarName + "= [NSString stringWithUTF8String:oc_" + strVarName + "];\n";
            staticCode += "static char oc_" + strVarName + "[] = " + obf_v + ";\n";
            staticCode += "static NSString * " + strVarName + ";\n";
        } else {
            staticCode += "static char " + strVarName + "[] = " + obf_v + ";\n";
        }
    }
    
    methodCode += "}\n";
    methodCode += "}\n";
    
    context->rootBlock->before += staticCode;
    context->rootBlock->before += methodCode;
}

void ObfTools::obfBlock(TokenParser* context, CodeBlock * block) {
    int recordNum = declareMethods.size();
    if((context->isNSStrObf || context->isCStrObf) && block->isMethod() && block->isHasString) {
        callStringXorMethod(block);
    }
    if(context->isInsertOcProp && block->blockType == BLOCK_OC_Interface) {
        genProp(block);
    }
    
    bool needObf = context->isAddCode;
    if(block->blockName == "switch") {
        needObf = false;
    }
    
    CodeBlock* pre_Block = nullptr;
    std::vector<Line*> cacheLines = block->allLine;
    block->allLine.clear();
    for(int i = 0; i < cacheLines.size(); i++) {
        auto cblock = dynamic_cast<CodeBlock*>(cacheLines[i]);
        if(cblock) {
            //1. 如果前一个不是block，那么可以插入代码
            if(block->isInLogic && !pre_Block && needObf) {
                genRunCode(context, block, cacheLines);
            }
            block->allLine.push_back(cblock);
            obfBlock(context, cblock);
            pre_Block = cblock;
        } else {
            if(block->isInLogic && needObf && !pre_Block) {
                genRunCode(context, block, cacheLines);
            }
            auto line = dynamic_cast<CodeLine*>(cacheLines[i]);
            if(line) {
                block->allLine.push_back(line);
            }
            pre_Block = nullptr;
        }
    }
    
    while(declareMethods.size() > recordNum) {
        auto method = declareMethods.back();
        generator->removeMethod(method);
        declareMethods.pop_back();
    }
    // 因为是加在后面。所以处理完成后再加函数。
    if(context->isAddFunc) {
        genOneFullFunction(block);
    }
    
}


void ObfTools::callStringXorMethod(CodeBlock * block) {
    if(obfStringMethodName != "") {
        block->before += "\n" + obfStringMethodName + "();\n";
    }
}

void ObfTools::combineBlock(CodeBlock * block, std::string& code) {
    code += block->before;
    for(auto itr = block->allLine.begin(); itr != block->allLine.end(); itr++) {
        auto line = dynamic_cast<CodeLine*>(*itr);
        if(line) {
            code += line->code;
        } else {
            auto cblock = dynamic_cast<CodeBlock*>(*itr);
            if(cblock) {
                combineBlock(cblock, code);
            }
        }
    }
    code += block->after;
}

void ObfTools::genProp(CodeBlock * block) {
    if(block->blockType == BLOCK_OC_Interface) {
        std::string ret = "";
        int count = arc4random() % 7;
        std::string types[] = {"int", "double", "float", "bool", "NSString * ", "NSMutableArray *", "NSMutableDictionary *"};
        int isNeedStrong[] = {0, 0, 0, 0, 1, 2, 2};
        int len = getArrSize(types);
        for(int i = 0; i < count; i++)
        {
            int rt = arc4random() % len;
            switch(isNeedStrong[rt])
            {
                case 0:
                    ret += "@property (nonatomic, readwrite) " + types[rt] + " " + genNameForCplus(CVarName, false) + ";\n";
                    break;
                case 1:
                    ret += "@property (nonatomic, readwrite, copy) " + types[rt] + " " + genNameForCplus(CVarName, false) + ";\n";
                    break;
                case 2:
                    ret += "@property (nonatomic, strong) " + types[rt] + " " + genNameForCplus(CVarName, false) + ";\n";
                    break;
                default:
                    break;
            };
        }
        block->after = ret + block->after;
    }
}


void ObfTools::preprocess(TokenParser * context) {
    // 提前添加垃圾函数
    if(context->isAddFunc) {
        // 添加头文件
        addHead(context);
        addFunctions(context);
    }
    // 字符串混淆预处理
    if(context->isCStrObf || context->isNSStrObf) {
        genStringObfMethod(context);
    }
}

void ObfTools::start(TokenParser * context, std::string& code)
{
    preprocess(context);
    obfBlock(context, context->rootBlock);
    combineBlock(context->rootBlock, code);
}

CodeBlock * ObfTools::findAMethodBlock(CodeBlock * block) {
    if(block->isMethod()) {
        return block;
    }
    int index = arc4random() % block->allLine.size();
    for(int i = -1; i != index; index = (index + 1) % block->allLine.size()) {
        if(i == -1) i = index;
        auto cblock = dynamic_cast<CodeBlock*>(block->allLine[i]);
        if(cblock) {
            auto f = findAMethodBlock(cblock);
            if(f) {
                return f;
            }
        }
    }
    return nullptr;
}

void ObfTools::insert(TokenParser * context, std::string& code, const char * import, const char * insertcode) {
    context->rootBlock->before += string("\n") + import;
    CodeBlock * block = findAMethodBlock(context->rootBlock);
    if(block) {
        block->before += string("\n") + insertcode;
    }
    combineBlock(context->rootBlock, code);
}

}
