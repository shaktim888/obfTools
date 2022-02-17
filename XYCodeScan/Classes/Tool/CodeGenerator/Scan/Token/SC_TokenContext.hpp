//
//  SC_TokenContext.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef SC_TokenContext_hpp
#define SC_TokenContext_hpp

#include <stdio.h>
#include <string>
#include <vector>

namespace scan {

enum BlockType {
    BLOCK_NONE,
    BLOCK_DEFINE,
    BLOCK_CPP,
    BLOCK_C_CPP_Method,
    BLOCK_OC_Interface,
    BLOCK_OC_Implementation,
    BLOCK_OC_Protocol,
    BLOCK_OC_METHOD,
    BLOCK_OC_METHOD_STATIC,
    BLOCK_LOGIC,
};

enum Token {
    tok_eof = -1,
    tok_number = -2,
    
    tok_identifier = -4,
    tok_char = -5,
    tok_string = -6,
    
    tok_define_if = -7,
    tok_define_else = -8,
    tok_define_end = -9,
    tok_define = -10,
    
    tok_comment = -11,
};

class Line
{
public:
    Line() : isFromSource(false) {
        
    }
    bool isFromSource;
    virtual ~Line() {
        
    };
};

class CodeLine : public Line {
public:
    std::string code;
};

class CodeBlock : public Line
{
public:
    
    CodeBlock(BlockType t) : blockType(t)
    {}
    
    BlockType blockType;
    bool isInLogic;
    bool isHasString;
    CodeBlock * pre;
    int funcDepth;
    std::string className;
    std::string blockName;
    std::string before;
    std::vector<Line *> allLine;
    std::string after;
    
    bool isMethod() {
        return blockType == BLOCK_C_CPP_Method || blockType == BLOCK_OC_METHOD || blockType == BLOCK_OC_METHOD_STATIC;
    }
    
    bool isOC() {
        if(isMethod()) {
            return blockType == BLOCK_OC_METHOD || blockType == BLOCK_OC_METHOD_STATIC;
        }
        CodeBlock * block = this;
        while(block && block->isInLogic) {
            if(block->isMethod()) {
                return block->isOC();
            }
            block = block->pre;
        }
        return false;
    }
    
    ~CodeBlock() {
        for(auto itr = allLine.begin(); itr != allLine.end(); itr++ ) {
            delete(*itr);
        }
    }
};

class TokenParser
{
    int _gettok();
    
    int LastChar;
    int readPos;
    
    std::string outputCache;
    std::string readCache;
    
    std::string file_content;
public:
    TokenParser(std::string code, std::string ext, int _prop);
    ~TokenParser() {
        if(rootBlock) {
            delete(rootBlock);
            rootBlock = nullptr;
            curBlock = nullptr;
        }
    }
    // 所有字符串汇总
    std::vector<std::string>cachedStr;
    double NumVal;
    std::string IdentifierStr;
    int preTok;
    int curTok;
    int depth;
    
    std::string RecodeString;
    std::string DefineIdentifier;
    std::string curFileExt;
    
    CodeBlock* rootBlock;
    CodeBlock* curBlock;
    
    bool isAddCode;
    bool isAddFunc;
    bool isNSStrObf;
    bool isCStrObf;
    bool isInsertOcProp;
    int prop;

    char getNextChar();
    int gettok();
    void enterBlock(bool isInLogic, BlockType isInClass, int funcDepth, std::string clsName, std::string blockName);
    void exitBlock(int offset = 0);
    void popToDepth(int depth);
    void cacheLine();
    void cacheBlockBegin();
    void cacheBlockEnd(int offset = 0);
    
    std::string getStringName(int index);
    void cacheString();
    
};

}

#endif /* SC_TokenContext_hpp */
