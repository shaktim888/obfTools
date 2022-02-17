#include "CodeTokenScan.hpp"
#include "CodeTokenScan.h"
#include <fstream>
#include <sstream>
#include <stdio.h>
#include "CG_Block.hpp"
#include "CG_TypeManager.hpp"

template <class T>
static int getArrSize(T& arr){
    return sizeof(arr) / sizeof(arr[0]);
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

CodeTokenScan::CodeTokenScan(bool _isInsertMode) {
    isInsertCodeMode = _isInsertMode;
    generator = new gen::CodeGenerator();
    buildAllTokenMap();
    reset();
}

void CodeTokenScan::reset()
{
    callAllMethod = nullptr;
//    isCalledAllMethod = false;
    isForceExpress = false;
    isInClass = false;
    isInArray = false;
    recordClassDeep = 99;
    recordArrayDeep = -1;
    curFuncDeep = 0;
    isAddedFunctionHead = true;
    isIgnoreString = false;
    declareMethods.clear();
    funcNameSet.clear();
    varNameSet.clear();
    while(!storeDeep.empty())
        storeDeep.pop();
    while(!storeFuncCount.empty())
        storeFuncCount.pop();
    if(declareMethods.size() > 0) {
        declareMethods.clear();
    }
    DefineIdentifier = "";
    curFunctionName = "";
    funcCode = "";
    varCode = "";
    readCache = "";
    outputCache = "";
    IdentifierStr = "";  // Filled in if tok_identifier
    NumVal = 0;
    isInFunc = false;
    isWaitFuncDef = false;
    isAddStringObf = false;
    
    isNSStrObf = [UserConfig sharedInstance].encodeNSString;
    isCStrObf = [UserConfig sharedInstance].encodeCString;
    isAddFunc = [UserConfig sharedInstance].insertFunction;
    isAddCode = [UserConfig sharedInstance].insertCode;
    isInsertOcProp = [UserConfig sharedInstance].addProperty;
    addNumOfMethod = [UserConfig sharedInstance].addMethodNum;
    LastChar = ' ';
    funcDeep = 0;
    readPos = -1;
    output = "";
    PreKHIdentifier = "";
    PreMaoHaoIdentifier = "";
    CurTok = 0;
    PreTok = 0;
    PreKHTok = 0;
    PreMaoHaoTok = 0;
}

char CodeTokenScan::getNextChar()
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

int CodeTokenScan::gettok() {
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
        return tok_char;
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
        if (LastChar != EOF){
            if(DefineIdentifier == "if" || DefineIdentifier == "ifdef" || DefineIdentifier == "ifndef") {
                return tok_define_if;
            }
            if(DefineIdentifier == "elif" || DefineIdentifier == "else") {
                return tok_define_else;
            }
            if(DefineIdentifier == "endif") {
                return tok_define_end;
            }
            return tok_define;
        }
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
                        return tok_comment;
                    }
                }
                if (LastChar == EOF)
                {
                    return tok_eof;
                }
            }while(true);
        }
        
        if (LastChar != EOF)
            return tok_comment;
    }
    
    // Check for end of file.  Don't eat the EOF.
    if (LastChar == EOF)
        return tok_eof;
    
    int ThisChar = LastChar;
    LastChar = getNextChar();
    return ThisChar;
}

void CodeTokenScan::handleString()
{
    if(CurTok == tok_string)
    {
        if(isIgnoreString)
        {
            isIgnoreString = false;
            return;
        }
        if(!isNSStrObf && !isCStrObf) {
            return;
        }
        bool isForceObf = false;
        if(RecodeString.find("http") != RecodeString.npos
        || RecodeString.find("www") != RecodeString.npos
        || RecodeString.find("HTML") != RecodeString.npos
        || RecodeString.find("html") != RecodeString.npos) {
            isForceObf = true;
        }
        if(!isForceObf) {
            if(PreTok == '@' && !isNSStrObf){
                
                return;
            } else if(!isCStrObf) {
                return;
            }
            
            if(!isInFunc) {
                return;
            }
        }
        
        std::string tmpStr = RecodeString;
        string_replace(tmpStr, "\\" , "");
//        // 跳过这种情况
//        // char a[] = "xxx"
//        if(PreTok == '=') {
//            if(PreDYTok == ']') {
//                return;
//            }
//        }
        if(tmpStr.length() > 1)
        {
            if(isForceObf || rand() % 100 <= prop)
            {
                buildStringObf();
                if(!isAddStringObf)
                {
                    isAddStringObf = true;
                    varCode += importObfHead();
                }
                std::string::size_type position = outputCache.find("\"");
                if (position != outputCache.npos) {
                    outputCache = outputCache.substr(0, position);
                }
                if(PreTok == '@')
                {
                    output = output.substr(0, output.length() - 1);
                    output += outputCache + ObfOC(RecodeString.c_str());
                }
                else
                {
                    output += outputCache + ObfCPtr(RecodeString.c_str());
                }
                outputCache = "";
            }
        }
    }
}

void CodeTokenScan::popToFunction(int num) {
    while(declareMethods.size() > num) {
        auto method = declareMethods.back();
        generator->removeMethod(method);
        declareMethods.pop_back();
    }
}

int CodeTokenScan::getNextToken() {
    outputCache = "";
    
    if(CurTok != tok_define_if
       && CurTok != tok_define_else
       && CurTok != tok_define_end
       && CurTok != tok_comment
       && CurTok != tok_define) {
        PreTok = CurTok;
    }
    CurTok = gettok();
    if(!isInsertCodeMode && !isAddedFunctionHead && CurTok != tok_define && CurTok != tok_comment)
    {
        isAddedFunctionHead = true;
        std::string code = "\n";
        if(curFileExt == "m" || curFileExt == "mm") {
            code += "#import <Foundation/Foundation.h>\n";
            code += "#import <stdlib.h>\n";
        } else {
            code += "#include <stdlib.h>\n";
            code += "#include <stdio.h>\n";
        }
        code += addFunctions(addNumOfMethod);
        output += code;
    }
    if(CurTok == tok_define_if) {
        storeDeep.push(funcDeep);
        storeFuncCount.push((int)declareMethods.size());
    } else if(CurTok == tok_define_else) {
        funcDeep = storeDeep.top();
        int funcCount = storeFuncCount.top();
        popToFunction(funcCount);
    } else if(CurTok == tok_define_end) {
        int funcCount = storeFuncCount.top();
        popToFunction(funcCount);
        storeDeep.pop();
        storeFuncCount.pop();
    }
    for(int i = 0 ; i < tokenVerifies.size(); i ++){
        switch (tokenVerifies[i]->limitType) {
            case InFunc:
            {
                if(isInFunc){
                    tokenVerifies[i]->onToken(CurTok, IdentifierStr);
                }
                break;
            }
            case OutOfFunc:
            {
                if(!isInFunc) {
                    tokenVerifies[i]->onToken(CurTok, IdentifierStr);
                }
                break;
            }
            default:
            {
                tokenVerifies[i]->onToken(CurTok, IdentifierStr);
                break;
            }
        }
    }
    if(CurTok == '{') {
        funcDeep++;
    }
    if(CurTok == '}') {
        funcDeep--;
    }
    if(CurTok == '(')
    {
        PreKHTok = PreTok;
        PreKHIdentifier = IdentifierStr;
    }
    if(CurTok == tok_string){
        handleString();
    }
    handleArray();
//    if(CurTok == '=')
//    {
//        PreDYTok = PreTok;
//    }
    output += outputCache;
    return CurTok;
}
//
//std::string CodeTokenScan::genVarCode()
//{
//    std::string varName;
//    if(varNameSet.size() > 0 && (random() % 100) <= varNameSet.size() * 4)
//    {
//        int index = rand() % varNameSet.size();
//        std::set<std::string>::iterator p = varNameSet.begin();
//        for (; p != varNameSet.end() && index > 0; ++p, --index);
//        varName = *p;
//    }
//    else
//    {
//        varName = genNameForCplus(CVarName, true);
//        varNameSet.insert(varName);
//        std::string typeName = "static int ";
//        std::string val = std::to_string(random() % 300);
//        varCode += typeName + varName + "=" + val + ";\n";
//    }
//    return varName;
//}
//
//std::string CodeTokenScan::genFunctionCode()
//{
//
//    std::string funcName;
//    if(funcNameSet.size() > 0 && random() % 100 <= funcNameSet.size() * 4)
//    {
//        // old function
//        int index = rand() % funcNameSet.size();
//        std::set<std::string>::iterator p = funcNameSet.begin();
//        for (; p != funcNameSet.end() && index > 0; ++p, --index);
//        funcName = *p;
//    }
//    else{
//        funcName = genNameForCplus(CFuncName, true);
//        funcNameSet.insert(funcName);
//        std::string varName = genVarCode();
//        // new function
//        std::vector<std::string> expressionIsFunction = {
//            "static inline const char *"+funcName+"(){" + varName+ "=" + std::to_string(rand()%10000+10) + ";int *d=&"+varName+";*d=10;while(*d>1) (*d)=(*d%4==1)?(*d-1):(*d/3);char temp[]="+"\""+std::to_string(rand()%100000)+"\";*d=sizeof(temp);"+
//            "return "+"\""+std::to_string(rand()%100000000)+"\";}\n",
//
//            "static inline  double "+funcName+"(){"+varName+"="+std::to_string(rand()%10000+10)+";int *d=&"+varName+";*d=10;while(*d>1) (*d)=(*d%4==2)?(*d/2):(*d/4);"+"char temp[]="+"\""+std::to_string(rand()%100000)+"\";*d=sizeof(temp);"+
//            "return "+"(double)*d;}\n",
//
//            "static inline int "+funcName+"(){"+varName+"="+std::to_string(rand()%10000+10)+";int *d=&"+varName+";*d=100;while(*d>1) (*d)=(*d%4==3)?(*d-100):(*d-500);"+
//            "return "+"*d;}\n",
//
//            "static inline int *"+funcName+"(){"+varName+"="+std::to_string(rand()%100+10)+";int *d=&"+varName+";*d=10;while(*d>1) (*d)=(*d%4==0)?(*d-1):(*d/3-3);"+
//            "return "+"d;}\n",
//
//            "static inline void "+funcName+"(){"+varName+"*="+std::to_string(rand()%2+1)+";if( "+varName+"<0)"+varName+"="+std::to_string(rand()%100+10)+";}\n",
//        };
//        funcCode += expressionIsFunction[rand()%expressionIsFunction.size()];
//    }
//    return funcName;
//}

std::string CodeTokenScan::genOneLineCode(bool isOC){
    return "\n" + generator->selectOneMethodToRun(isOC, isOC ? isStaticFunc : false, isOC ? curClassName.c_str() : nullptr, declareMethods, curFuncDeep);
}

std::string CodeTokenScan::genOneFullFunction(bool isOC)
{
    const char * name = nullptr;
    int methodType = gen::Method_None;
    if(isOC){
        name = curClassName.c_str();
        methodType = arc4random() % 2 ? gen::Method_OC_Object : gen::Method_OC_Static;
    } else {
        methodType = isOC ? gen::Method_C_OC : gen::Method_C;
    }
    auto method = generator->genOneClassMethod(name, methodType, funcDeep);
    printf("addMethod:%s, %d\n" , method->name.c_str(), method->deep);
    declareMethods.push_back(method);
    return "\n" + method->body;
}

void CodeTokenScan::randomAddCode(bool isOC) {
    if(isAddCode && rand() % 100 <= prop)
    {
        output += genOneLineCode(isOC);
    }
}

void CodeTokenScan::randomAddFunction(bool isOC)
{
    if(isAddFunc && rand() % 100 <= prop)
    {
        output += genOneFullFunction(isOC);
    }
}

bool CodeTokenScan::handleFor()
{
    if(CurTok == tok_identifier && IdentifierStr == "for")
    {
        int kh = 0;
        do
        {
            getNextToken();
            if(CurTok == '(')
            {
                kh++;
            }
            if(CurTok == ')')
            {
                kh--;
            }
        }while(kh != 0 && CurTok != tok_eof);
        return true;
    }
    return false;
}

bool CodeTokenScan::handTypedef()
{
    if(CurTok == tok_identifier && IdentifierStr == "typedef")
    {
        int deep = 0;
        do
        {
            getNextToken();
            if(CurTok == '{') {
                deep++;
            } else if(CurTok == '}') {
                deep--;
            }else if(CurTok == ';' && deep == 0) break;
        }while(CurTok != tok_eof);
        return true;
    }
    return false;
}


bool CodeTokenScan::skipInnerStruct()
{
    if(CurTok == tok_identifier && (IdentifierStr == "struct" || IdentifierStr == "class" || IdentifierStr == "union" || IdentifierStr == "NS_ENUM" || IdentifierStr == "enum"))
    {
        bool isInStruct = false;
        int kh = 0;
        do
        {
            getNextToken();
            if(CurTok == '{')
            {
                isInStruct = true;
                kh++;
            }
            if(CurTok == '}')
            {
                kh--;
            }
            if(CurTok == ';' && kh == 0)
            {
                break;
            }
//            if(CurTok == ',' && kh == 0)
//            {
//                break;
//            }
        }while(CurTok != tok_eof);
        return isInStruct;
    }
    return false;
}

void CodeTokenScan::handleOuterClass()
{
    if(CurTok == tok_identifier && (IdentifierStr == "struct" || IdentifierStr == "class" || IdentifierStr == "union" || IdentifierStr == "NS_ENUM" || IdentifierStr == "enum")) {
        bool isOCEnum = IdentifierStr == "NS_ENUM";
        getNextToken();
        std::string tempName;
        if(CurTok == tok_identifier) {
            tempName = IdentifierStr;
        }
        while(CurTok != '{' && CurTok != ';' && CurTok != tok_eof)
        {
            if(CurTok == '(' && !isOCEnum) {
                break;
            }
            if(!isOCEnum && CurTok == ')') {
                break;
            }
            getNextToken();
        }
        if(CurTok == '{') {
            curClassName = tempName;
            recordClassDeep = funcDeep - 1;
            isInClass = true;
            isWaitFuncDef = false;
        }
    }
    else if(isInClass && CurTok == '}' && funcDeep == recordClassDeep) {
        isInClass = false;
    }
}

bool CodeTokenScan::handleIfElse()
{
    if(CurTok == tok_identifier && (IdentifierStr == "if" || IdentifierStr == "while" || IdentifierStr == "switch"))
    {
        isForceExpress = IdentifierStr == "switch";
        int kh = 0;
        do
        {
            getNextToken();
            if(CurTok == '(')
            {
                kh++;
            }
            if(CurTok == ')')
            {
                kh--;
            }
        }while(kh != 0 && CurTok != tok_eof);
        return true;
    }
    else if(CurTok == tok_identifier && (IdentifierStr == "else" || IdentifierStr == "do")){
        return true;
    }
    return false;
}

void CodeTokenScan::handleArray() {
    if(isInArray ) {
        if(CurTok =='{') {
            if(recordArrayDeep < 0) {
                recordArrayDeep = funcDeep - 1;
            }
        } else if(CurTok == '}') {
            if(funcDeep == recordArrayDeep) {
                isInArray = false;
                recordArrayDeep = -1;
            }
        }
    }
}

void CodeTokenScan::handleFunction(bool isOC, bool isFunction)
{
    curFuncDeep = funcDeep - 1;
    isInFunc = true;
    isInArray = false;
    std::vector<bool> que;
    bool inExpress = false;
    que.push_back(inExpress);
    if(isInsertCodeMode) {
        output += insertCode;
        output += file_content.substr(readPos + 1);
        readPos = file_content.length();
        return;
    }
    if(isFunction) {
        if(callAllMethod) {
            output += "\n" + generator->genCallMethodString(nullptr, callAllMethod);
        }
    }
    randomAddCode(isOC);
    do {
        getNextToken();
        if(CurTok == ';')
        {
            if(!isForceExpress && !isInArray && !inExpress){
                randomAddCode(isOC);
            }
        }
        while(skipInnerStruct())
        {
            getNextToken();
        }
        while(handleIfElse() || handleFor()) {
            getNextToken();
            inExpress = true;
        }
        if(CurTok == '{') {
            que.push_back(inExpress);
            if(!isInArray) {
                inExpress = (PreTok == '=' || PreTok == '<' || PreTok == '@' || PreTok == '(');
                // 这是为了解决这种语法： (char*){}
                if(PreTok == ')')
                {
                    if((PreKHTok != tok_identifier && PreKHTok != '^') || (isForceExpress || PreKHIdentifier == "return") )
                    {
                        inExpress = true;
                    }
                }
                if(!isForceExpress && !inExpress){
                    randomAddCode(isOC);
                }
            }
            isForceExpress = false;
        }
        // 在这种情况下不需要再添加代码了。
        if(CurTok == tok_identifier && (IdentifierStr == "return" || IdentifierStr == "break" || IdentifierStr == "continue" || IdentifierStr == "goto" ))
        {
            isForceExpress = false;
            inExpress = true;
        }
        if(CurTok == tok_identifier && IdentifierStr == "case")
        {
            isForceExpress = false;
            inExpress = true;
        }
        if(CurTok == '}')
        {
            isForceExpress = false;
            inExpress = que.back();
            que.pop_back();
        }
        if(CurTok == tok_eof)
        {
            return;
        }
    }while(funcDeep != curFuncDeep && CurTok != tok_eof);
    if(!isInClass && isFunction) {
        randomAddFunction(isOC);
    }
    isInFunc = false;
}

void CodeTokenScan::HandleTopLevelExpression() {
    handleOuterClass();
    if(CurTok == tok_eof) return;
    if(!isWaitFuncDef && !isInArray && CurTok == ')') {
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
    if(CurTok == ';') {
        isWaitFuncDef = false;
    }
    // 遇到了函数定义
    if(CurTok == '{')
    {
        //        if((PreTok == ')' && (PreKHTok == tok_identifier || PreKHTok == '^')) || (PreTok == tok_identifier && (IdentifierStr == "const"|| IdentifierStr == "override")))
        if(isWaitFuncDef)
        {
            isWaitFuncDef = false;
//            if(PreTok == ')' || (PreTok == tok_identifier && (IdentifierStr == "override" || IdentifierStr == "const") ))
            if(PreTok != '=')
            {
                //            if(PreKHTok == tok_identifier || PreTok == tok_identifier)
                if(curFunctionName != "")
                {
                    handleFunction(false, true);
                } else {
                    handleFunction(false, false);
                }
            }

        }
    }
    getNextToken();
}

std::string CodeTokenScan::randomAddOCProperty()
{
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
    return ret;
}

void CodeTokenScan::HandleOCDefine()
{
    if (getNextToken() == tok_identifier)
    {
        if(IdentifierStr == "interface") {
            do{
                while(getNextToken() != '@' && CurTok != tok_eof);
                getNextToken();
                if(CurTok == tok_identifier && IdentifierStr == "end")
                {
                    if(isInsertOcProp) {
                        std::string proStr = randomAddOCProperty();
                        output = output.insert(output.length() - 4, proStr);
                    }
                    return;
                }
            }
            while(CurTok != tok_eof);
        }
        else if(IdentifierStr == "protocol")
        {
            do{
                while(getNextToken() != '@' && CurTok != tok_eof);
                getNextToken();
                if(CurTok == tok_identifier && IdentifierStr == "end")
                {
                    return;
                }
            }
            while(CurTok != tok_eof);
        }
        else if(IdentifierStr == "implementation")
        {
            getNextToken();
            curClassName = IdentifierStr;
            generator->manager->genEmptyClass(gen::Class_OC, curClassName.c_str());
            do{
                do
                {
                    getNextToken();
                }
                while(CurTok != '{' && CurTok != '-' && CurTok != '+' && CurTok != '@' && CurTok != tok_eof);
                if(CurTok == '-' || CurTok == '+')
                {
                    isStaticFunc = CurTok == '+';
                    while(getNextToken() != '{' && CurTok != tok_eof);
                    if(CurTok == '{') {
                        handleFunction(true, true);
                    }
                }
                // ({}) [](){}
                if(CurTok == '{' && PreTok == ')')
                {
                    if(PreKHTok == tok_identifier) {
                        handleFunction( false, true);
                    } else if(PreKHTok == '^') { // 是oc的block函数
                        handleFunction(true, false);
                    }
                }
                if(CurTok == '@')
                {
                    getNextToken();
                    if(CurTok == tok_identifier && IdentifierStr == "end")
                    {
                        break;
                    }
                }
            }while(CurTok != tok_eof);
        }
    }
    else
    {
        while(getNextToken() == tok_identifier && CurTok != tok_eof);
        if(CurTok == ';')
        {
            return;
        }
    }
}

void CodeTokenScan::MainLoop() {
    if(curFileExt == "m"
       || curFileExt == "mm"
       || curFileExt == "c"
       || curFileExt == "cpp"
       || curFileExt == "cc") {
        isAddedFunctionHead = false;
    }
    while (1) {
        switch (CurTok) {
            case tok_eof:    return;
            case '@': {
                HandleOCDefine();
                break;
            }
            case tok_string: case tok_number: case tok_char: case tok_comment:
            {
                getNextToken(); break;
            }
            default: {
                HandleTopLevelExpression(); break;
            }
        }
    }
}

const char * CodeTokenScan::solve(const char * code, int _prop, const char * fileExt)
{
    reset();
    file_content = code;
    curFileExt = fileExt;
    if(curFileExt == "h" || curFileExt == "hpp")
    {
        isAddCode = false;
        isAddFunc = false;
        isNSStrObf = false;
        isCStrObf = false;
    }
    prop = _prop >= 0 ? _prop : 50;
    MainLoop();
    output = varCode + funcCode + output;
    return output.c_str();
}

void CodeTokenScan::buildAllTokenMap() {
    {
        // class::method(
        TokenVerify * v  = new TokenVerify(OutOfFunc);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back(':');
        v->sequece.push_back(':');
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back('(');
        v->onMach = [&](TokenVerify * info) {
            curClassName = info->record[0];
        };
        tokenVerifies.push_back(v);
    }
    {
        // static NSString * xxx = @""
        TokenVerify * v  = new TokenVerify(NoLimit);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back('*');
        v->sequece.push_back(tok_identifier);
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
        TokenVerify * v  = new TokenVerify(NoLimit);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back('[');
        v->sequece.push_back(']');
        v->sequece.push_back('=');
        v->sequece.push_back(tok_string);
        v->identifyMap[0] = "char";
        v->onMach = [&](TokenVerify * info) {
            isIgnoreString = true;
        };
        tokenVerifies.push_back(v);
    }
    {
        // char aaa[123] = ""
        TokenVerify * v  = new TokenVerify(NoLimit);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back(tok_identifier);
        v->sequece.push_back('[');
        v->sequece.push_back(tok_number);
        v->sequece.push_back(']');
        v->sequece.push_back('=');
        v->sequece.push_back(tok_string);
        v->identifyMap[0] = "char";
        v->onMach = [&](TokenVerify * info) {
            isIgnoreString = true;
        };
        tokenVerifies.push_back(v);
    }
    {
        // [xxx] = {
        TokenVerify * v  = new TokenVerify(NoLimit);
        v->sequece.push_back(']');
        v->sequece.push_back('=');
        v->sequece.push_back('{');
        v->onMach = [&](TokenVerify * info) {
            isInArray = true;
        };
        tokenVerifies.push_back(v);
    }
}

CodeTokenScan::~CodeTokenScan() {
    for(int i = 0 ; i < tokenVerifies.size(); i ++ ){
        delete tokenVerifies[i];
    }
    tokenVerifies.clear();
    declareMethods.clear();
    if(generator) {
        delete generator;
        generator = nullptr;
    }
}

std::string CodeTokenScan::addFunctions(int num) {
    std::string ret = "";
    auto vec = generator->genCMethod(num, curFileExt == "m" || curFileExt == "mm");
    for(int i = 0; i < vec.size(); i++) {
        ret += vec[i]->body + "\n";
        declareMethods.push_back(vec[i]);
    }
    callAllMethod = generator->genCallAllMethod(declareMethods);
    declareMethods.push_back(callAllMethod);
    ret += callAllMethod->body + "\n";
    return ret;
}

void rcgCode1(char * inFile, char * outFile, int _prop )
{
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
    CodeTokenScan scan;
    const char * modify = scan.solve(contents.c_str(), _prop, fileExt.c_str());
    std::ofstream fout;
    fout.open(outFile);
    fout << modify;
    fout.close();
}


void insertCode1(char * inFile, char * outFile, char * import , char * code )
{
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
    CodeTokenScan scan(true);
    scan.insertCode = code;
    const char * modify = scan.solve(contents.c_str(), 100, fileExt.c_str());
    std::ofstream fout;
    fout.open(outFile);
    fout << import;
    fout << modify;
    fout.close();
}


