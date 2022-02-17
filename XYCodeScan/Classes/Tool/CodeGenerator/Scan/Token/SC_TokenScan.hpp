//
//  TokenScan.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef TokenScan_hpp
#define TokenScan_hpp

#include <stdio.h>
#include <stack>
#include <map>
#include <functional>
#include "SC_TokenContext.hpp"

namespace scan
{

enum EnumLimitType {
    NoLimit,
    InFunc,
    OutOfFunc,
};

struct TokenVerify
{
    typedef std::function<void (TokenVerify*)> onMatchFunc;
    TokenVerify(int _limitType): cur(0) , curIden(-1) , onMach(nullptr), limitType(_limitType)
    {
        
    }
    bool onToken(int token, std::string & curIdentify);
    std::vector<int> sequece;
    std::vector<std::string> record;
    std::map<int, std::string> identifyMap;
    onMatchFunc onMach;
    int id;
    int limitType;
    int cur;
    int curIden;
};

class TokenScan
{
private:
    void buildAllTokenMap();
    void handleString(TokenParser * context);
    int getNextToken(TokenParser * context);
    void mainloop(TokenParser * context);
    void handleArray(TokenParser * context);
    void HandleOCDefine(TokenParser * context);
    void handleFunction(TokenParser * context, bool isOC, bool isFunction);
    bool skipInnerStruct(TokenParser * context);
    bool handleIfElse(TokenParser * context);
    bool handleFor(TokenParser * context);
    void handleOuterClass(TokenParser * context);
    void HandleTopLevelExpression(TokenParser * context);
    void addRubbishCode(TokenParser * context);
    void revertEnv(TokenParser * context);
    void reset();
    
    int funcDeep;
    int curFuncDeep;
    int recordArrayDeep;
    int recordClassDeep;
    int PreKHTok;
    
    BlockType curBlockType;
    bool isInFunc;
    bool isInArray;
    bool isIgnoreString;
    bool isStaticFunc;
    bool isForceExpress;
    bool isWaitFuncDef;
    bool isAddedFunctionHead;
    
    std::string PreKHIdentifier;
    std::string curClassName;
    std::string curFunctionName;
    std::string curBlockName;
    
    std::stack<int> storeDeep;
    std::stack<int> storeBlockDepth;
    std::vector<TokenVerify*> tokenVerifies;
    
public:
    TokenScan();
    void obfFile(const char * filepath, const char * outFile, int prop);
    void insertToFile(const char * inFile, const char * outFile, const char * import , const char * code);
    
};

}

#endif /* TokenScan_hpp */
