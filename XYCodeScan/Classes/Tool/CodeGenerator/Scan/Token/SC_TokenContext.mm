//
//  SC_TokenContext.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#include "SC_TokenContext.hpp"
#import "UserConfig.h"

namespace scan {

char TokenParser::getNextChar()
{
    outputCache += readCache;
    readCache = "";
    readPos += 1;
    if(readPos >= file_content.length())
    {
        return EOF;
    }
    char preChar = file_content[readPos];
    readCache += preChar;
    return preChar;
}

TokenParser::TokenParser(std::string code, std::string ext, int _prop) {
    file_content = code;
    curFileExt = ext;
    prop = _prop >= 0 ? _prop : 50;

    isInsertOcProp = [UserConfig sharedInstance].addProperty;
    if(curFileExt == "h" || curFileExt == "hpp")
    {
        isAddCode = false;
        isAddFunc = false;
        isNSStrObf = false;
        isCStrObf = false;
    } else {
        isNSStrObf = [UserConfig sharedInstance].encodeNSString;
        isCStrObf = [UserConfig sharedInstance].encodeCString;
        isAddFunc = [UserConfig sharedInstance].insertFunction;
        isAddCode = [UserConfig sharedInstance].insertCode;
    }
    rootBlock = nullptr;
    curBlock = nullptr;
    DefineIdentifier = "";
    readCache = "";
    outputCache = "";
    IdentifierStr = "";  // Filled in if tok_identifier
    NumVal = 0;
    LastChar = ' ';
    readPos = -1;
    preTok = 0;
    curTok = 0;
    enterBlock(false, BLOCK_NONE, 0, "", ""); // 先创建个root block
}

int TokenParser::gettok() {
    if(curTok != Token::tok_define_if
       && curTok != Token::tok_define_else
       && curTok != Token::tok_define_end
       && curTok != Token::tok_comment
       && curTok != Token::tok_define) {
        preTok = curTok;
    }
    curTok = _gettok();
    return curTok;
}

int TokenParser::_gettok() {
    // Skip any whitespace.
    while (isspace(LastChar))
        LastChar = getNextChar();
    
    if (isalpha(LastChar) || LastChar == '_') { // identifier: [a-zA-Z][a-zA-Z0-9]*
        IdentifierStr = LastChar;
        while (isalnum((LastChar = getNextChar())) || LastChar == '_')
            IdentifierStr += LastChar;
        return tok_identifier;
    }
    
    if (isdigit(LastChar) || LastChar == '.') {   // Number: [0-9.]+
        std::string NumStr;
        do {
            NumStr += LastChar;
            LastChar = getNextChar();
        } while (isdigit(LastChar) || LastChar == '.');
        NumVal = strtod(NumStr.c_str(), 0);
        return tok_number;
    }
    if(LastChar == '"')
    {
        RecodeString = "";
        do {
            do {
                LastChar = getNextChar();
                while(LastChar == '\\')
                {
                    RecodeString += readCache;
                    int temp = getNextChar();
                    RecodeString += readCache;
                    LastChar = getNextChar();
                    if((LastChar == '\n' && temp == '\r') ||
                       (LastChar == '\r' && temp == '\n'))
                    {
                        LastChar = getNextChar();
                        RecodeString += readCache;
                    }
                }
                if(LastChar != '"'){
                    RecodeString += readCache;
                }
            }
            while (LastChar != EOF && LastChar != '"');
            LastChar = getNextChar();
            while (isspace(LastChar))
                LastChar = getNextChar();
        } while(LastChar == '"');
        return tok_string;
    }
    
    if(LastChar == '\'')
    {
        RecodeString = "";
        do {
            LastChar = getNextChar();
            while(LastChar == '\\')
            {
                RecodeString += readCache;
                int temp = getNextChar();
                RecodeString += readCache;
                LastChar = getNextChar();
                if((LastChar == '\n' && temp == '\r') ||
                   (LastChar == '\r' && temp == '\n'))
                {
                    LastChar = getNextChar();
                    RecodeString += readCache;
                }
            }
            if(LastChar != '\''){
                RecodeString += readCache;
            }
        }
        while (LastChar != EOF && LastChar != '\'');
        LastChar = getNextChar();
        return Token::tok_char;
    }
    
    // 所有的宏定义我们直接忽略
    if(LastChar == '#')
    {
        DefineIdentifier = "";
        bool isGetted = false;
        bool isSkipSpace = true;
        do {
            LastChar = getNextChar();
            if(isSkipSpace) {
                while (isspace(LastChar) && LastChar!= '\n')
                    LastChar = getNextChar();
                isSkipSpace = false;
            }
            while(LastChar == '\\')
            {
                isGetted = true;
                int temp = getNextChar();
                LastChar = getNextChar();
                if((LastChar == '\n' && temp == '\r') ||
                   (LastChar == '\r' && temp == '\n'))
                {
                    LastChar = getNextChar();
                }
            }
            if(!isGetted)
            {
                if(isalnum(LastChar)){
                    DefineIdentifier += LastChar;
                } else {
                    isGetted = true;
                }
            }
        }
        while (LastChar != EOF && LastChar != '\n');
        
        if(DefineIdentifier == "if" || DefineIdentifier == "ifdef" || DefineIdentifier == "ifndef") {
            return Token::tok_define_if;
        }
        if(DefineIdentifier == "elif" || DefineIdentifier == "else") {
            return Token::tok_define_else;
        }
        if(DefineIdentifier == "endif") {
            return Token::tok_define_end;
        }
        return Token::tok_define;
        
    }
    
    // 处理注释
    if (LastChar == '/') {
        LastChar = getNextChar();
        if(LastChar == '/')
        {
            do{
                LastChar = getNextChar();
                while(LastChar == '\\')
                {
                    int temp = getNextChar();
                    LastChar = getNextChar();
                    if((LastChar == '\n' && temp == '\r') ||
                       (LastChar == '\r' && temp == '\n'))
                    {
                        LastChar = getNextChar();
                    }
                }
            }
            while (LastChar != EOF && LastChar != '\n');
        }
        else if(LastChar == '*')
        {
            do
            {
                LastChar = getNextChar();
                while(LastChar == '*')
                {
                    LastChar = getNextChar();
                    if(LastChar == '/')
                    {
                        LastChar = getNextChar();
                        return Token::tok_comment;
                    }
                }
                if (LastChar == EOF)
                {
                    return Token::tok_eof;
                }
            }while(true);
        }
        
        if (LastChar != EOF)
            return Token::tok_comment;
    }
    
    // Check for end of file.  Don't eat the EOF.
    if (LastChar == EOF)
        return Token::tok_eof;
    
    int ThisChar = LastChar;
    LastChar = getNextChar();
    return ThisChar;
}

void TokenParser::enterBlock(bool inlogic, BlockType blockType, int funcDepth, std::string clsName, std::string blockName) {
    depth++;
    auto b = new CodeBlock(blockType);
    b->isInLogic = inlogic;
    b->isFromSource = true;
    b->funcDepth = funcDepth;
    b->className = clsName;
    b->blockName = blockName;
    if(curBlock) {
        b->pre = curBlock;
        curBlock->allLine.push_back(b);
        curBlock = b;
    } else {
        if(rootBlock) {
            // 出现这情况大概率是出错了。
            b->pre = rootBlock;
        } else {
            b->pre = nullptr;
            rootBlock = b;
        }
        curBlock = b;
    }
    cacheBlockBegin();
}

void TokenParser::exitBlock(int offset) {
    cacheBlockEnd(offset);
    if(curBlock && curBlock->pre != nullptr) {
        depth--;
        curBlock = curBlock->pre;
    }
}

void TokenParser::popToDepth(int d) {
    for(int i= depth; i > d; i--) {
        exitBlock();
    }
}

void TokenParser::cacheLine() {
    if(curBlock && outputCache != "") {
        auto line = new CodeLine();
        line->isFromSource = true;
        line->code = outputCache;
        curBlock->allLine.push_back(line);
        outputCache = "";
    }
}

void TokenParser::cacheBlockBegin() {
    if(curBlock && outputCache != "") {
        curBlock->before += outputCache;
        outputCache = "";
    }
}

void TokenParser::cacheBlockEnd(int offset) {
    if(curBlock && outputCache != "") {
        if(offset > 0) {
            std::string x = outputCache.substr(outputCache.length() - offset);
            outputCache = outputCache.substr(0, outputCache.length() - offset);
            cacheLine();
            outputCache = x;
        }
        curBlock->after += outputCache;
        outputCache = "";
    }
}

static void string_replace( std::string &strBig, const std::string &strsrc, const std::string &strdst)
{
    std::string::size_type pos = 0;
    std::string::size_type srclen = strsrc.size();
    std::string::size_type dstlen = strdst.size();
    
    while( (pos=strBig.find(strsrc, pos)) != std::string::npos )
    {
        strBig.replace( pos, srclen, strdst );
        pos += dstlen;
    }
}

std::string TokenParser::getStringName(int index) {
    return "_VAR_STRING_PLACEHOLD_" + std::to_string(index) + "_";
}

void TokenParser::cacheString() {
    if(!curBlock->isInLogic) return;
    std::string tmpStr = RecodeString;
    string_replace(tmpStr, "\\" , "");
    
    bool isForceObf = false;
    if(RecodeString.find("http") != RecodeString.npos
    || RecodeString.find("www") != RecodeString.npos
    || RecodeString.find("HTML") != RecodeString.npos
    || RecodeString.find("html") != RecodeString.npos) {
        isForceObf = true;
    }
    if(!isForceObf) {
        if(!isNSStrObf && !isCStrObf) {
            return;
        }
        if(preTok == '@') {
            if(!isNSStrObf) return;
        } else {
            if(!isCStrObf) return;
        }
        if(arc4random() % 100 > prop) {
            return;
        }
    }
    
    if(tmpStr.length() > 1)
    {
        std::string::size_type position = outputCache.find("\"" + RecodeString + "\"");
        if (position != outputCache.npos) {
            std::string preStr = outputCache.substr(0, position + 1);
            std::string surStr = outputCache.substr(position + RecodeString.length() + 2);
            char start = '\"';
            if(preTok == '@') {
                start = '@';
            }
            size_t p = preStr.find_last_of(start);
            if(p != outputCache.npos) {
                tmpStr = preStr.substr(p) + tmpStr + "\"";
                preStr = preStr.substr(0, p);
            }
            outputCache = preStr + getStringName(cachedStr.size()) + surStr;
            cachedStr.push_back(tmpStr);
            
            CodeBlock * tmp = curBlock;
            while(tmp && tmp->isInLogic) {
                if(tmp->isMethod()) {
                    tmp->isHasString = true; // 在函数块中标记一下存在字符串
                    break;
                }
                tmp = tmp->pre;
            }
        }
    }
}

}
