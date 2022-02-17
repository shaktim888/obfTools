#ifndef CodeTokenScan_h
#define CodeTokenScan_h

#include <string>
#include <map>
#include <set>
#include <vector>
#include <stack>
#include "CodeTokenScan.h"
#include "NameGeneratorExtern.h"
#include "UserConfig.h"
#import "StringObfCplus.h"
#include "CG_Generator.hpp"
#include <functional>


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

enum GenCodeType
{
    CallFunction,
    Logic,
};

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

class CodeTokenScan
{
    char getNextChar();
    int gettok();
    void handleString();
    int getNextToken();
    
    bool handleFor();
    bool handTypedef();
    bool skipInnerStruct();
    bool handleIfElse();
    void handleArray();
    void handleFunction(bool isOC, bool isFunction);
    void HandleTopLevelExpression();
    std::string randomAddOCProperty();
    void HandleOCDefine();
    void MainLoop();
    void reset();
    std::string addFunctions(int num);
    
    std::string curClassName;
//    std::string genVarCode();
//    std::string genFunctionCode();
    std::string genOneLineCode(bool isOC);
    std::string genOneFullFunction(bool isOC);
    void randomAddCode(bool isOC);
    void randomAddFunction(bool isOC);
    void buildAllTokenMap();
    void handleOuterClass();
    void popToFunction(int num);
public:
    CodeTokenScan(bool isInsertMode = false);
    ~CodeTokenScan();
    std::string insertCode;
    const char * solve(const char * code, int _prop, const char * fileExt);
private:
    std::string curFileExt;
    std::vector<TokenVerify*> tokenVerifies;
    std::vector<gen::HYMethodInfo*> declareMethods;
    gen::CodeGenerator * generator;
    bool isWaitFuncDef;
    bool isNSStrObf;
    bool isCStrObf;
    bool isAddCode;
    bool isInsertOcProp;
    bool isAddFunc;
    bool isInFunc;
    bool isInClass;
    bool isInsertCodeMode;
    int recordClassDeep;
    bool isInArray;
    int curFuncDeep;
    int recordArrayDeep;
    bool isAddStringObf;
    bool isForceExpress;
//    bool isCalledAllMethod;
    gen::HYMethodInfo * callAllMethod;
//    bool isStartInclude;
    int prop;
    long readPos;
    int addNumOfMethod;
    bool isStaticFunc;
    std::string file_content;
    std::string output;
    int CurTok;
    int PreTok;
    int funcDeep;
    // 记录括号前面的token
    int PreKHTok;
    // 记录冒号前面的token
    int PreMaoHaoTok;
    // 记录等于号的token
//    int PreDYTok;
    std::string PreKHIdentifier;
    std::string PreMaoHaoIdentifier;
    
    std::set<std::string> funcNameSet;
    std::set<std::string> varNameSet;
    std::string varCode;
    std::string funcCode;
    
    std::string curFunctionName;
    std::string IdentifierStr;  // Filled in if tok_identifier
    std::string RecodeString;
    bool isIgnoreString;
    bool isAddedFunctionHead;
    std::string DefineIdentifier;
    std::stack<int> storeDeep;
    std::stack<int> storeFuncCount;
    
    double NumVal;
    int LastChar;
    std::string readCache;
    std::string outputCache;
};

#endif /* CodeTokenScan_h */
