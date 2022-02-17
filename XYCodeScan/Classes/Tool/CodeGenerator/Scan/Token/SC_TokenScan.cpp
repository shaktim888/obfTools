//
//  TokenScan.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#include "SC_TokenScan.hpp"
#include "NameGeneratorExtern.h"
#include "SC_ObfTools.hpp"
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <set>

namespace scan {

bool TokenVerify::onToken(int token, std::string &curIdentify)  {
    bool needRecheck = cur != 0;
    if(token == sequece[cur]) {
        if(token == tok_identifier) {
            curIden++;
            if(identifyMap.find(curIden) == identifyMap.end() || identifyMap[curIden] == curIdentify) {
                cur++;
                record.push_back(curIdentify);
            } else {
                cur = 0;
                curIden = -1;
                record.clear();
                if(needRecheck) {
                    return onToken(token, curIdentify);
                }
            }
        }else {
            cur++;
        }
    } else {
        cur = 0;
        curIden = -1;
        record.clear();
        if(needRecheck) {
            return onToken(token, curIdentify);
        }
    }
    if(cur >= sequece.size()) {
        cur = 0;
        curIden = -1;
        if(onMach) onMach(this);
        return true;
    }
    return false;
}

void TokenScan::reset()
{
//    isCalledAllMethod = false;
    isForceExpress = false;
    curBlockType = BLOCK_NONE;
    isInArray = false;
    isIgnoreString = false;
    isAddedFunctionHead = false;
    recordClassDeep = 99;
    recordArrayDeep = -1;
    curFuncDeep = 0;
    while(!storeDeep.empty())
        storeDeep.pop();

    curFunctionName = "";

    isInFunc = false;
    isWaitFuncDef = false;
    
    funcDeep = 0;
    PreKHIdentifier = "";
    PreKHTok = 0;
}

void TokenScan::buildAllTokenMap() {
    {
        // class::method(
        TokenVerify * v  = new TokenVerify(EnumLimitType::OutOfFunc);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back(':');
        v->sequece.push_back(':');
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back('(');
        v->onMach = [&](TokenVerify * info) {
            if(!isInFunc) {
                curClassName = info->record[0];
                curBlockType = BLOCK_C_CPP_Method;
            }
        };
        tokenVerifies.push_back(v);
    }
    {
        // static NSString * xxx = @""
        TokenVerify * v  = new TokenVerify(EnumLimitType::NoLimit);
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back('*');
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back('=');
        v->sequece.push_back('@');
        v->identifyMap[0] = "static";
        v->identifyMap[1] = "NSString";
        v->onMach = [&](TokenVerify * info) {
            isIgnoreString = true;
        };
        tokenVerifies.push_back(v);
    }
    {
        // char aaa[] = ""
        TokenVerify * v  = new TokenVerify(EnumLimitType::NoLimit);
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back('[');
        v->sequece.push_back(']');
        v->sequece.push_back('=');
        v->sequece.push_back(Token::tok_string);
        v->identifyMap[0] = "char";
        v->onMach = [&](TokenVerify * info) {
            isIgnoreString = true;
        };
        tokenVerifies.push_back(v);
    }
    {
        // char aaa[123] = ""
        TokenVerify * v  = new TokenVerify(EnumLimitType::NoLimit);
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back(Token::tok_identifier);
        v->sequece.push_back('[');
        v->sequece.push_back(Token::tok_number);
        v->sequece.push_back(']');
        v->sequece.push_back('=');
        v->sequece.push_back(Token::tok_string);
        v->identifyMap[0] = "char";
        v->onMach = [&](TokenVerify * info) {
            isIgnoreString = true;
        };
        tokenVerifies.push_back(v);
    }
    {
        // [xxx] = {
        TokenVerify * v  = new TokenVerify(EnumLimitType::NoLimit);
        v->sequece.push_back(']');
        v->sequece.push_back('=');
        v->sequece.push_back('{');
        v->onMach = [&](TokenVerify * info) {
            isInArray = true;
        };
        tokenVerifies.push_back(v);
    }
}

void TokenScan::handleArray(TokenParser * context) {
    if(isInArray) {
        if(context->curTok =='{') {
            if(recordArrayDeep < 0) {
                recordArrayDeep = funcDeep - 1;
            }
        } else if(context->curTok == '}') {
            if(funcDeep == recordArrayDeep) {
                isInArray = false;
                recordArrayDeep = -1;
                getNextToken(context);
            }
        }
    }
}

int TokenScan::getNextToken(TokenParser * context) {
    context->gettok();
    if(!isAddedFunctionHead && (context->curTok == Token::tok_define || context->curTok == Token::tok_comment))
    {
        context->cacheBlockBegin();
    } else {
        isAddedFunctionHead = true;
    }
    if(context->curTok == tok_define_if) {
        storeDeep.push(funcDeep);
        storeBlockDepth.push(context->depth);
        curBlockType = BLOCK_DEFINE;
        context->enterBlock(!isInArray && isInFunc, curBlockType, funcDeep, curClassName, curBlockName);
    } else if(context->curTok == tok_define_else) {
        funcDeep = storeDeep.top();
        int blockDepth = storeBlockDepth.top();
        context->popToDepth(blockDepth);
        revertEnv(context);
        curBlockType = BLOCK_DEFINE;
        context->enterBlock(!isInArray && isInFunc, curBlockType, funcDeep, curClassName, curBlockName);
    } else if(context->curTok == tok_define_end) {
        storeDeep.pop();
        int blockDepth = storeBlockDepth.top();
        storeBlockDepth.pop();
        context->popToDepth(blockDepth);
        revertEnv(context);
    }
    for(int i = 0 ; i < tokenVerifies.size(); i ++){
        switch (tokenVerifies[i]->limitType) {
            case InFunc:
            {
                if(isInFunc){
                    tokenVerifies[i]->onToken(context->curTok, context->IdentifierStr);
                }
                break;
            }
            case OutOfFunc:
            {
                if(!isInFunc) {
                    tokenVerifies[i]->onToken(context->curTok, context->IdentifierStr);
                }
                break;
            }
            default:
            {
                tokenVerifies[i]->onToken(context->curTok, context->IdentifierStr);
                break;
            }
        }
    }
    
    if(context->curTok == '{') {
        funcDeep++;
    }
    if(context->curTok == '}') {
        funcDeep--;
    }
    if(context->curTok == '(')
    {
        PreKHTok = context->preTok;
        PreKHIdentifier = context->IdentifierStr;
    }
    if(context->curTok == tok_string){
        handleString(context);
    }
    handleArray(context);
//    if(CurTok == '=')
//    {
//        PreDYTok = PreTok;
//    }
    if(context->curTok == Token::tok_eof) { // 防止遗漏了内容
        context->cacheBlockEnd();
    }
    return context->curTok;
}

void TokenScan::handleString(TokenParser * context)
{
    if(context->curTok == tok_string)
    {
        if(isIgnoreString)
        {
            isIgnoreString = false;
            return;
        }
        context->cacheString();
    }
}

bool TokenScan::skipInnerStruct(TokenParser * context)
{
    if(context->curTok == Token::tok_identifier && (context->IdentifierStr == "struct" || context->IdentifierStr == "class" || context->IdentifierStr == "union" || context->IdentifierStr == "NS_ENUM" || context->IdentifierStr == "enum"))
    {
        bool isInStruct = false;
        int kh = 0;
        do
        {
            getNextToken(context);
            if(context->curTok == '{')
            {
                isInStruct = true;
                kh++;
            }
            if(context->curTok == '}')
            {
                kh--;
            }
            if(context->curTok == ';' && kh == 0)
            {
                break;
            }
//            if(CurTok == ',' && kh == 0)
//            {
//                break;
//            }
        }while(context->curTok != Token::tok_eof);
        return isInStruct;
    }
    return false;
}

bool TokenScan::handleIfElse(TokenParser * context)
{
    if(context->curTok == Token::tok_identifier && (context->IdentifierStr == "if" || context->IdentifierStr == "while" || context->IdentifierStr == "switch"))
    {
        isForceExpress = context->IdentifierStr == "switch";
        curBlockName = context->IdentifierStr;
        int kh = 0;
        do
        {
            getNextToken(context);
            if(context->curTok == '(')
            {
                kh++;
            }
            if(context->curTok == ')')
            {
                kh--;
            }
        }while(kh != 0 && context->curTok != Token::tok_eof);
        return true;
    }
    else if(context->curTok == Token::tok_identifier && (context->IdentifierStr == "else" || context->IdentifierStr == "do")){
        curBlockName = context->IdentifierStr;
        return true;
    }
    return false;
}

bool TokenScan::handleFor(TokenParser * context)
{
    if(context->curTok == Token::tok_identifier && context->IdentifierStr == "for")
    {
        int kh = 0;
        do
        {
            getNextToken(context);
            if(context->curTok == '(')
            {
                kh++;
            }
            if(context->curTok == ')')
            {
                kh--;
            }
        }while(kh != 0 && context->curTok != Token::tok_eof);
        return true;
    }
    return false;
}

void TokenScan::handleFunction(TokenParser * context, bool isOC, bool isFunction)
{
    curBlockName = "";
    context->enterBlock(true, curBlockType, funcDeep, curClassName, curBlockName);
    curFuncDeep = funcDeep - 1;
    isInFunc = true;
    isInArray = false;
    std::vector<bool> que;
    bool inExpress = false;
    bool waitCloseOnLine = false;
    que.push_back(inExpress);
//    if(isInsertCodeMode) {
//        output += insertCode;
//        output += file_content.substr(readPos + 1);
//        readPos = file_content.length();
//        return;
//    }
//    if(isFunction) {
//        if(callAllMethod) {
//            output += "\n" + generator->genCallMethodString(nullptr, callAllMethod);
//        }
//    }
//    randomAddCode(isOC);
    do {
        getNextToken(context);
        if(context->curTok == ';')
        {
            if(!waitCloseOnLine && !isForceExpress && !isInArray && !inExpress){
                context->cacheLine();
//                randomAddCode(isOC);
            }
            if(waitCloseOnLine) {
                waitCloseOnLine = false;
            }
        }
        while(skipInnerStruct(context))
        {
            getNextToken(context);
        }
        while(handleIfElse(context) || handleFor(context)) {
            getNextToken(context);
            waitCloseOnLine = true;
        }
        if(context->curTok == '{') {
            if(waitCloseOnLine) {
                waitCloseOnLine = false;
            }
            if(!isInArray) {
                que.push_back(inExpress);
                inExpress = (context->preTok == '=' || context->preTok == '<' || context->preTok == '@' || context->preTok == '(');
                // 这是为了解决这种语法： (char*){}
                if(context->preTok == ')')
                {
                    if((PreKHTok != tok_identifier && PreKHTok != '^') || (isForceExpress || PreKHIdentifier == "return") )
                    {
                        inExpress = true;
                    }
                }
                curBlockType = BLOCK_LOGIC;
                context->enterBlock(true, curBlockType, funcDeep, curClassName, curBlockName);
//                if(!isForceExpress && !inExpress){
//                    context->cacheLine();
//                }
            }
            isForceExpress = false;
        }
        // 在这种情况下不需要再添加代码了。
        if(context->curTok == Token::tok_identifier && (context->IdentifierStr == "return" || context->IdentifierStr == "break" || context->IdentifierStr == "continue" || context->IdentifierStr == "goto" ))
        {
            isForceExpress = false;
            inExpress = true;
        }
        if(context->curTok == Token::tok_identifier && context->IdentifierStr == "case")
        {
            curBlockName = context->IdentifierStr;
            isForceExpress = false;
            inExpress = true;
        }
        if(context->curTok == '}')
        {
            if(!isInArray) {
                context->exitBlock();
                revertEnv(context);
                isForceExpress = false;
                inExpress = que.back();
                que.pop_back();
            }
        }
        if(context->curTok == tok_eof)
        {
            return;
        }
    }while(funcDeep != curFuncDeep && context->curTok != tok_eof);
//    if(!isInClass && isFunction) {
//        randomAddFunction(isOC);
//    }
    isInFunc = false;
}

void TokenScan::revertEnv(TokenParser * context) {
    curBlockType = context->curBlock->blockType;
    curClassName= context->curBlock->className;
    curBlockName = context->curBlock->blockName;
}

void TokenScan::handleOuterClass(TokenParser * context)
{
    if(context->curTok == tok_identifier && (context->IdentifierStr == "struct" || context->IdentifierStr == "class" || context->IdentifierStr == "union" || context->IdentifierStr == "NS_ENUM" || context->IdentifierStr == "enum")) {
        bool isOCEnum = context->IdentifierStr == "NS_ENUM";
        curBlockName = context->curTok;
        getNextToken(context);
        std::string tempName;
        if(context->curTok == tok_identifier) {
            tempName = context->IdentifierStr;
        }
        while(context->curTok != '{' && context->curTok != ';' && context->curTok != tok_eof)
        {
            if(context->curTok == '(' && !isOCEnum) {
                break;
            }
            if(!isOCEnum && context->curTok == ')') {
                break;
            }
            getNextToken(context);
        }
        if(context->curTok == '{') {
            curClassName = tempName;
            recordClassDeep = funcDeep - 1;
            curBlockType = BLOCK_CPP;
            isWaitFuncDef = false;
            context->enterBlock(false, curBlockType, funcDeep, curClassName, curBlockName);
        }
    }
    else if(curBlockType == BLOCK_CPP && context->curTok == '}' && funcDeep == recordClassDeep) {
        context->exitBlock();
        revertEnv(context);
    }
}

void TokenScan::HandleOCDefine(TokenParser * context)
{
    if (getNextToken(context) == Token::tok_identifier)
    {
        if(context->IdentifierStr == "interface") {
            curBlockName = context->IdentifierStr;
            getNextToken(context);
            curClassName = context->IdentifierStr;
            curBlockType = BLOCK_OC_Interface;
            context->enterBlock(false, curBlockType, funcDeep, curClassName, curBlockName);
            do{
                while(getNextToken(context) != '@' && context->curTok != Token::tok_eof);
                getNextToken(context);
                if(context->curTok == Token::tok_identifier && context->IdentifierStr == "end")
                {
//                    if(isInsertOcProp) {
//                        std::string proStr = randomAddOCProperty();
//                        output = output.insert(output.length() - 4, proStr);
//                    }
                    context->exitBlock(4);
                    revertEnv(context);
                    return;
                }
            }
            while(context->curTok != tok_eof);
        }
        else if(context->IdentifierStr == "protocol")
        {
            curBlockName = context->IdentifierStr;
            getNextToken(context);
            curClassName = context->IdentifierStr;
            curBlockType = BLOCK_OC_Protocol;
            context->enterBlock(false, curBlockType, funcDeep, curClassName, curBlockName);
            do{
                while(getNextToken(context) != '@' && context->curTok != Token::tok_eof);
                getNextToken(context);
                if(context->curTok == Token::tok_identifier && context->IdentifierStr == "end")
                {
                    context->exitBlock(4);
                    revertEnv(context);
                    return;
                }
            }
            while(context->curTok != Token::tok_eof);
        }
        else if(context->IdentifierStr == "implementation")
        {
            curBlockName = context->IdentifierStr;
            getNextToken(context);
            curBlockType = BLOCK_OC_Implementation;
            curClassName = context->IdentifierStr;
            context->enterBlock(false, curBlockType, funcDeep, curClassName, curBlockName);
//            generator->manager->genEmptyClass(gen::Class_OC, curClassName.c_str());
            do{
                do
                {
                    getNextToken(context);
                }
                while(context->curTok != '{' && context->curTok != '-' && context->curTok != '+' && context->curTok != '@' && context->curTok != Token::tok_eof);
                if(context->curTok == '-' || context->curTok == '+')
                {
                    isStaticFunc = context->curTok == '+';
                    while(getNextToken(context) != '{' && context->curTok != Token::tok_eof);
                    if(context->curTok == '{') {
                        curBlockType = isStaticFunc ? BLOCK_OC_METHOD_STATIC : BLOCK_OC_METHOD;
                        handleFunction(context, true, true);
                    }
                }
                // ({}) [](){}
                if(context->curTok == '{' && context->preTok == ')')
                {
                    if(PreKHTok == Token::tok_identifier) {
                        curBlockType = BLOCK_C_CPP_Method;
                        handleFunction(context, false, true);
                    } else if(PreKHTok == '^') { // 是oc的block函数
                        curBlockType = BLOCK_LOGIC;
                        handleFunction(context, true, false);
                    }
                }
                if(context->curTok == '@')
                {
                    getNextToken(context);
                    if(context->curTok == Token::tok_identifier && context->IdentifierStr == "end")
                    {
                        context->exitBlock(4);
                        revertEnv(context);
                        break;
                    }
                }
            }while(context->curTok != Token::tok_eof);
        }
    }
    else
    {
        while(getNextToken(context) == Token::tok_identifier && context->curTok != Token::tok_eof);
        if(context->curTok == ';')
        {
            return;
        }
    }
}

void TokenScan::HandleTopLevelExpression(TokenParser * context) {
    handleOuterClass(context);
    if(context->curTok == Token::tok_eof) return;
    if(!isWaitFuncDef && !isInArray && context->curTok == ')') {
        if(PreKHTok == tok_identifier || PreKHTok == '^' || PreKHIdentifier == "operator" || PreKHTok == '>') {
            isWaitFuncDef = true;
            if(PreKHTok == tok_identifier) {
                curFunctionName = PreKHIdentifier;
            } else {
                curFunctionName = "";
            }
        }
    }
    // 第一个遇到的是；说明一定不是函数定义了
    if(context->curTok == ';') {
        isWaitFuncDef = false;
    }
    // 遇到了函数定义
    if(context->curTok == '{')
    {
        //        if((PreTok == ')' && (PreKHTok == tok_identifier || PreKHTok == '^')) || (PreTok == tok_identifier && (IdentifierStr == "const"|| IdentifierStr == "override")))
        if(isWaitFuncDef)
        {
            isWaitFuncDef = false;
//            if(PreTok == ')' || (PreTok == tok_identifier && (IdentifierStr == "override" || IdentifierStr == "const") ))
            if(context->preTok != '=')
            {
                //            if(PreKHTok == tok_identifier || PreTok == tok_identifier)
                if(curFunctionName != "")
                {
                    curBlockType = BLOCK_C_CPP_Method;
                    handleFunction(context, false, true);
                } else {
                    curBlockType = BLOCK_LOGIC;
                    handleFunction(context, false, false);
                }
            }

        }
    }
    getNextToken(context);
}

void TokenScan::mainloop(TokenParser * context) {
    while (1) {
        switch (context->curTok) {
            case tok_eof:    return;
            case '@': {
                HandleOCDefine(context);
                break;
            }
            case tok_string: case tok_number: case tok_char: case tok_comment:
            {
                getNextToken(context); break;
            }
            default: {
                HandleTopLevelExpression(context); break;
            }
        }
    }
}

void TokenScan::addRubbishCode(TokenParser * context) {
    for(auto itr = context->rootBlock->allLine.begin(); itr != context->rootBlock->allLine.end(); itr++) {
        CodeLine* line = dynamic_cast<CodeLine*>(*itr);
        if(line) {
            
        } else {
            CodeBlock * block = dynamic_cast<CodeBlock*>(*itr);
            if(block) {
                
            }
        }
    }
}

void TokenScan::obfFile(const char * inFile, const char * outFile, int prop) {
    genNameClearCache(CFuncName);
    genNameClearCache(CVarName);
    std::ifstream t(inFile);
    std::string fileName = inFile;
    std::string fileExt = fileName.substr(fileName.find_last_of('.') + 1);
    std::stringstream buffer;
    buffer << t.rdbuf();
    std::string contents(buffer.str());
    const unsigned char* c = (const unsigned char *)contents.c_str();
    unsigned bom = c[0] | (c[1] << 8) | (c[2] << 16);
    if (bom == 0xBFBBEF) { // UTF8 BOM
        contents.erase(0,3);
    }
    t.close();
    TokenParser context(contents, fileExt, prop);
    mainloop(&context);
    ObfTools tools;
    std::string code;
    tools.start(&context, code);
    std::ofstream fout;
    fout.open(outFile);
    fout << code;
    fout.close();
}

void TokenScan::insertToFile(const char * inFile, const char * outFile, const char * import , const char * code) {
    std::ifstream t(inFile);
    std::string fileName = inFile;
    std::string fileExt = fileName.substr(fileName.find_last_of('.') + 1);
    std::stringstream buffer;
    buffer << t.rdbuf();
    std::string contents(buffer.str());
    const unsigned char* c = (const unsigned char *)contents.c_str();
    unsigned bom = c[0] | (c[1] << 8) | (c[2] << 16);
    if (bom == 0xBFBBEF) { // UTF8 BOM
        contents.erase(0,3);
    }
    t.close();
    TokenParser context(contents, fileExt, 0);
    mainloop(&context);
    ObfTools tools;
    std::string newcode;
    tools.insert(&context, newcode, import, code);
    std::ofstream fout;
    fout.open(outFile);
    fout << newcode;
    fout.close();
}

TokenScan::TokenScan() {
    reset();
    buildAllTokenMap();
}

}
