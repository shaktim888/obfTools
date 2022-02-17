//#include <string>
//#include <map>
//#include <set>
//#include <vector>
//#include <stack>
//#include "CodeTokenAnalytic.h"
//#include "NameGeneratorExtern.h"
//#include "UserConfig.h"
//#import "StringObfCplus.h"
//
//
//template <class T>
//static int getArrSize(T& arr){
//    return sizeof(arr) / sizeof(arr[0]);
//}
//
//enum Token {
//    tok_eof = -1,
//    tok_number = -2,
//
//    tok_identifier = -4,
//    tok_string = -5,
//
//    tok_define = -6,
//    tok_define_if = -7,
//    tok_define_else = -8,
//    tok_define_end = -9,
//};
//
//static std::string curFileExt = "";
//
//static bool isWaitFuncDef = false;
//static bool isNSStrObf = false;
//static bool isCStrObf = false;
//static bool isAddCode = false;
//static bool isInsertOcProp = false;
//static bool isAddFunc = false;
//static bool isInFunc = false;
//static bool isAddStringObf = false;
//static int prop = 50;
//static int readPos = -1;
//static std::string file_content = "";
//static std::string output = "";
//static int CurTok = 0;
//static int PreTok;
//static int funcDeep = 0;
//// 记录括号前面的token
//static int PreKHTok;
//// 记录等于号的token
//static int PreDYTok;
//static std::string PreKHIdentifier;
//
//static std::set<std::string> funcNameSet;
//static std::set<std::string> varNameSet;
//static std::string varCode;
//static std::string funcCode;
//
//static std::string IdentifierStr;  // Filled in if tok_identifier
//static std::string RecodeString;
//static std::string DefineIdentifier;
//static std::stack<int> storeDeep;
//
//static double NumVal;
//static int LastChar = ' ';
//static std::string cache = "";
//
//static char getNextChar()
//{
//    output += cache;
//    cache = "";
//    readPos += 1;
//    if(readPos >= file_content.length())
//    {
//        return EOF;
//    }
//    char preChar = file_content[readPos];
//    cache += preChar;
//    return preChar;
//}
//
///// gettok - Return the next token from standard input.
//static int gettok() {
//    // Skip any whitespace.
//    while (isspace(LastChar))
//        LastChar = getNextChar();
//
//    if (isalpha(LastChar) || LastChar == '_') { // identifier: [a-zA-Z][a-zA-Z0-9]*
//        IdentifierStr = LastChar;
//        while (isalnum((LastChar = getNextChar())) || LastChar == '_')
//            IdentifierStr += LastChar;
//        return tok_identifier;
//    }
//
//    if (isdigit(LastChar) || LastChar == '.') {   // Number: [0-9.]+
//        std::string NumStr;
//        do {
//            NumStr += LastChar;
//            LastChar = getNextChar();
//        } while (isdigit(LastChar) || LastChar == '.');
//        NumVal = strtod(NumStr.c_str(), 0);
//        return tok_number;
//    }
//
//    if(LastChar == '"')
//    {
//        RecodeString = "";
//        do {
//            LastChar = getNextChar();
//            while(LastChar == '\\')
//            {
//                RecodeString += cache;
//                LastChar = getNextChar();
//                RecodeString += cache;
//                LastChar = getNextChar();
//            }
//            if(LastChar != '"'){
//                RecodeString += cache;
//            }
//        }
//        while (LastChar != EOF && LastChar != '"');
//        LastChar = getNextChar();
//        return tok_string;
//    }
//
//    if(LastChar == '\'')
//    {
//        RecodeString = "";
//        do {
//            LastChar = getNextChar();
//            while(LastChar == '\\')
//            {
//                RecodeString += cache;
//                LastChar = getNextChar();
//                RecodeString += cache;
//                LastChar = getNextChar();
//            }
//            if(LastChar != '\''){
//                RecodeString += cache;
//            }
//        }
//        while (LastChar != EOF && LastChar != '\'');
//        LastChar = getNextChar();
//        return tok_string;
//    }
//
//    // 所有的宏定义我们直接忽略
//    if(LastChar == '#')
//    {
//        DefineIdentifier = "";
//        bool isGetted = false;
//        bool isSkipSpace = true;
//        do {
//            LastChar = getNextChar();
//            if(isSkipSpace) {
//                while (isspace(LastChar) && LastChar!= '\n')
//                    LastChar = getNextChar();
//                isSkipSpace = false;
//            }
//            while(LastChar == '\\')
//            {
//                isGetted = true;
//                LastChar = getNextChar();
//                LastChar = getNextChar();
//            }
//            if(!isGetted)
//            {
//                if(isalnum(LastChar)){
//                    DefineIdentifier += LastChar;
//                } else {
//                    isGetted = true;
//                }
//            }
//        }
//        while (LastChar != EOF && LastChar != '\n' && LastChar != '\r');
//        if (LastChar != EOF){
//            if(DefineIdentifier == "if" || DefineIdentifier == "ifdef" || DefineIdentifier == "ifndef") {
//                return tok_define_if;
//            }
//            if(DefineIdentifier == "elif" || DefineIdentifier == "else") {
//                return tok_define_else;
//            }
//            if(DefineIdentifier == "endif") {
//                return tok_define_end;
//            }
//            return tok_define;
//        }
//    }
//
//    // 处理注释
//    if (LastChar == '/') {
//        LastChar = getNextChar();
//        if(LastChar == '/')
//        {
//            do{
//                LastChar = getNextChar();
//                while(LastChar == '\\')
//                {
//                    RecodeString += cache;
//                    LastChar = getNextChar();
//                    RecodeString += cache;
//                    LastChar = getNextChar();
//                }
//            }
//            while (LastChar != EOF && LastChar != '\n' && LastChar != '\r');
//        }
//        else if(LastChar == '*')
//        {
//            do
//            {
//                LastChar = getNextChar();
//                while(LastChar == '*')
//                {
//                    LastChar = getNextChar();
//                    if(LastChar == '/')
//                    {
//                        LastChar = getNextChar();
//                        return gettok();
//                    }
//                }
//                if (LastChar == EOF)
//                {
//                    return tok_eof;
//                }
//            }while(true);
//        }
//
//        if (LastChar != EOF)
//            return gettok();
//    }
//
//    // Check for end of file.  Don't eat the EOF.
//    if (LastChar == EOF)
//        return tok_eof;
//
//    int ThisChar = LastChar;
//    LastChar = getNextChar();
//    return ThisChar;
//}
//
//static void string_replace( std::string &strBig, const std::string &strsrc, const std::string &strdst)
//{
//    std::string::size_type pos = 0;
//    std::string::size_type srclen = strsrc.size();
//    std::string::size_type dstlen = strdst.size();
//
//    while( (pos=strBig.find(strsrc, pos)) != std::string::npos )
//    {
//        strBig.replace( pos, srclen, strdst );
//        pos += dstlen;
//    }
//}
//
//static void handleString()
//{
//    if(CurTok == tok_string)
//    {
//        if(PreTok == '@' && !isNSStrObf){
//            return;
//        } else if(!isCStrObf) {
//            return;
//        }
//
//        if(!isInFunc) {
//            return;
//        }
//        std::string tmpStr = RecodeString;
//        string_replace(tmpStr, "\\" , "");
//        // 跳过这种情况
//        // char a[] = "xxx"
//        if(PreTok == '=') {
//            if(PreDYTok == ']') {
//                return;
//            }
//        }
//        if(tmpStr.length() > 1)
//        {
//            if(rand() % 100 <= prop)
//            {
//                buildStringObf();
//                if(!isAddStringObf)
//                {
//                    isAddStringObf = true;
//                    varCode += importObfHead();
//                }
//                if(PreTok == '@')
//                {
//                    output = output.substr(0, output.length() - RecodeString.length() - 3);
//                    output += ObfOC(RecodeString.c_str());
//                }
//                else
//                {
//                    output = output.substr(0, output.length() - RecodeString.length() - 2);
//                    output += ObfCPtr(RecodeString.c_str());
//                }
//            }
//        }
//    }
//}
//
//static int getNextToken() {
//    PreTok = CurTok;
//    CurTok = gettok();
//    if(CurTok == '(')
//    {
//        PreKHTok = PreTok;
//        PreKHIdentifier = PreKHTok == tok_identifier ? IdentifierStr : "";
//    }
//    if(CurTok == tok_string){
//        handleString();
//    }
//    if(CurTok == '=')
//    {
//        PreDYTok = PreTok;
//    }
//    if(CurTok == tok_define_if) {
//        storeDeep.push(funcDeep);
//    } else if(CurTok == tok_define_else) {
//        funcDeep = storeDeep.top();
//    } else if(CurTok == tok_define_end) {
//        storeDeep.pop();
//    }
//    return CurTok;
//}
//
//
//enum GenCodeType
//{
//    CallFunction,
//    Logic,
//};
//
//static std::string genVarCode()
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
//
//static std::string genFunctionCode()
//{
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
//            "static const char *"+funcName+"(){" + varName+ "=" + std::to_string(rand()%10000+10) + ";int *d=&"+varName+";*d=10;while(*d>1) (*d)=(*d%4==1)?(*d-1):(*d/3);char temp[]="+"\""+std::to_string(rand()%100000)+"\";*d=sizeof(temp);"+
//            "return "+"\""+std::to_string(rand()%100000000)+"\";}\n",
//
//            "static double "+funcName+"(){"+varName+"="+std::to_string(rand()%10000+10)+";int *d=&"+varName+";*d=10;while(*d>1) (*d)=(*d%4==2)?(*d/2):(*d/4);"+"char temp[]="+"\""+std::to_string(rand()%100000)+"\";*d=sizeof(temp);"+
//            "return "+"(double)*d;}\n",
//
//            "static int "+funcName+"(){"+varName+"="+std::to_string(rand()%10000+10)+";int *d=&"+varName+";*d=100;while(*d>1) (*d)=(*d%4==3)?(*d-100):(*d-500);"+
//            "return "+"*d;}\n",
//
//            "static int *"+funcName+"(){"+varName+"="+std::to_string(rand()%100+10)+";int *d=&"+varName+";*d=10;while(*d>1) (*d)=(*d%4==0)?(*d-1):(*d/3-3);"+
//            "return "+"d;}\n",
//
//            "static void "+funcName+"(){"+varName+"*="+std::to_string(rand()%2+1)+";if( "+varName+"<0)"+varName+"="+std::to_string(rand()%100+10)+";}\n",
//        };
//        funcCode += expressionIsFunction[rand()%expressionIsFunction.size()];
//    }
//    return funcName;
//}
//
//static std::string genOneLineCode(){
//    std::string ret = "";
//    int genType = random() % 2;
//    switch (genType) {
//        case CallFunction:
//        {
//            std::string funcName = genFunctionCode();
//            ret += "\n"+ funcName + "();\n";
//            break;
//        }
//        case Logic:
//        {
//            std::string varName = genVarCode();
//            std::string s = genNameForCplus(CVarName, true);
//            std::vector<std::string> expressionNotFunction = {
//                "\nif(" + std::to_string(rand()%10000)+"<" + std::to_string(rand()%100+101)+"*"+std::to_string(rand()%100+101)+"){"+varName+"="+std::to_string(rand()%100)+";}\n",
//
//                "\nwhile("+varName+">"+std::to_string(rand()%1000)+"){"+varName+"/=10;}\n",
//
//                "\nwhile("+varName+"<"+std::to_string(rand()%1000)+"){"+varName+"+=500;}\n",
//
//                "\n{int *"+s+"=&"+varName+";if((long)"+s+"=="+std::to_string(rand()%100000)+") *"+s+"++"+";}\n",
//            };
//            ret += expressionNotFunction[rand()%expressionNotFunction.size()];
//            break;
//        }
//    }
//    return ret;
//}
//
//static std::string genOneFullFunction(bool isOC)
//{
//    std::string ret = "\n";
//    bool isStatic = rand() % 2 == 0;
//    std::string types[] = {"int", "double", "float", "int *", "double *", "float *", "void *", "void"};
//    bool needConvert[] = {false, false, false, true, true, true, true, false};
//
//    std::string retValue[] = {
//        std::to_string(rand() % 1000),
//        std::to_string(rand() % 1000) + ".0",
//        std::to_string(rand() % 1000) + ".0f",
//        "0x" + std::to_string(rand() % 100),
//        "0x" + std::to_string(rand() % 100),
//        "0x" + std::to_string(rand() % 100),
//        "0x" + std::to_string(rand() % 100),
//        "",
//    };
//    int typeSize = getArrSize(types);
//    int argTypeSize = typeSize - 1;
//    int rindex = rand() % typeSize;
//    std::string funcName = genNameForCplus(CFuncName, true);
//    if(isOC)
//    {
//        ret += (isStatic ? "+ (" : "- (") + types[rindex] + ") " + funcName;
//    } else {
//        ret += "static " + types[rindex] + " " + funcName + "(";
//    }
//    int randArgNum = rand() % 5;
//    for(int i = 0; i< randArgNum; i++) {
//        std::string varName = genNameForCplus(CVarName, false);
//        if(isOC) {
//            if(i != 0){
//                ret += varName + ": (" + types[rand() % argTypeSize] + ")" + varName + " ";
//            } else {
//                ret += ": (" + types[rand() % argTypeSize] + ")" + varName + " ";
//            }
//        } else {
//            if(i != 0){
//                ret += ", " + types[rand() % argTypeSize] + " " + varName;
//            } else {
//                ret += types[rand() % argTypeSize] + " " + varName;
//            }
//        }
//    }
//    ret += isOC ? " {\n" : ") {\n";
//    int lines = rand() % 10 + 2;
//    for(int i = 0; i < lines; i++){
//        ret += genOneLineCode();
//    }
//    ret += "return " + (needConvert[rindex] ? "(" + types[rindex] + ")" : "") + retValue[rindex] + ";\n";
//    ret += "}\n";
//    return ret;
//}
//
//static void randomAddCode() {
//    if(isAddCode && rand() % 100 <= prop)
//    {
//        output += genOneLineCode();
//    }
//}
//
//static void randomAddFunction(bool isOC)
//{
//    if(isAddFunc && rand() % 100 <= prop)
//    {
//        output += genOneFullFunction(isOC);
//    }
//}
//
//static bool handleFor()
//{
//    if(CurTok == tok_identifier && IdentifierStr == "for")
//    {
//        int kh = 0;
//        do
//        {
//            getNextToken();
//            if(CurTok == '(')
//            {
//                kh++;
//            }
//            if(CurTok == ')')
//            {
//                kh--;
//            }
//        }while(kh != 0 && CurTok != tok_eof);
//        return true;
//    }
//    return false;
//}
//
//static bool handTypedef()
//{
//    if(CurTok == tok_identifier && IdentifierStr == "typedef")
//    {
//        int deep = 0;
//        do
//        {
//            getNextToken();
//            if(CurTok == '{') {
//                deep++;
//            } else if(CurTok == '}') {
//                deep--;
//            }else if(CurTok == ';' && deep == 0) break;
//        }while(CurTok != tok_eof);
//        return true;
//    }
//    return false;
//}
//
//static bool skipInnerStruct()
//{
//    if(CurTok == tok_identifier && (IdentifierStr == "struct" || IdentifierStr == "class" || IdentifierStr == "union" || IdentifierStr == "typedef"))
//    {
//        int kh = 0;
//        do
//        {
//            getNextToken();
//            if(CurTok == '{')
//            {
//                kh++;
//            }
//            if(CurTok == '}')
//            {
//                kh--;
//            }
//            if(CurTok == ';' && kh == 0)
//            {
//                break;
//            }
//        }while(CurTok != tok_eof);
//        return true;
//    }
//    return false;
//}
//
//static bool handleIfElse()
//{
//    if(CurTok == tok_identifier && (IdentifierStr == "if" || IdentifierStr == "while"))
//    {
//        int kh = 0;
//        do
//        {
//            getNextToken();
//            if(CurTok == '(')
//            {
//                kh++;
//            }
//            if(CurTok == ')')
//            {
//                kh--;
//            }
//        }while(kh != 0 && CurTok != tok_eof);
//        return true;
//    }
//    else if(CurTok == tok_identifier && (IdentifierStr == "else" || IdentifierStr == "do")){
//        return true;
//    }
//    return false;
//}
//
//static void handleFunction(bool isOC, bool isFunction)
//{
//    isInFunc = true;
//    std::vector<bool> que;
//    funcDeep = 1;
//    bool inExpress = false;
//    que.push_back(inExpress);
//    randomAddCode();
//    do {
//        getNextToken();
//        if(CurTok == ';')
//        {
//            if(!inExpress){
//                randomAddCode();
//            }
//        }
//        while(skipInnerStruct())
//        {
//            getNextToken();
//        }
//        while(handleIfElse() || handleFor()) {
//            getNextToken();
//            inExpress = true;
//        }
//        if(CurTok == '{')
//        {
//            funcDeep++;
//            que.push_back(inExpress);
//            inExpress = (PreTok == '=' || PreTok == '<' || PreTok == '@' || PreTok == '(');
//            // 这是为了解决这种语法： (char*){}
//            if(PreTok == ')')
//            {
//                if((PreKHTok != tok_identifier && PreKHTok != '^') || (PreKHIdentifier == "switch" || PreKHIdentifier == "return") )
//                {
//                   inExpress = true;
//                }
//            }
//            if(!inExpress){
//                randomAddCode();
//            }
//        }
//        // 在这种情况下不需要再添加代码了。
//        if(CurTok == tok_identifier && (IdentifierStr == "return" || IdentifierStr == "break" || IdentifierStr == "continue"))
//        {
//            inExpress = true;
//        }
//        if(CurTok == tok_identifier && IdentifierStr == "case")
//        {
//            inExpress = false;
//        }
//        if(CurTok == '}')
//        {
//            funcDeep--;
//            inExpress = que.back();
//            que.pop_back();
//        }
//        if(CurTok == tok_eof)
//        {
//            return;
//        }
//    }while(funcDeep != 0 && CurTok != tok_eof);
//    if(isFunction) {
//        randomAddFunction(isOC);
//    }
//    isInFunc = false;
//    funcDeep = 0;
//}
//
//// 处理入口逻辑
//static void HandleTopLevelExpression() {
//    handTypedef();
//    while(getNextToken() == tok_identifier)
//    {
//        handTypedef();
//    }
//    if(CurTok == ')' && (PreKHTok == tok_identifier || PreKHTok == '^')) {
//        isWaitFuncDef = true;
//    }
//    if(CurTok == tok_eof) return;
//    // 第一个遇到的是；说明一定不是函数定义了
//    if(CurTok == ';') {
//        isWaitFuncDef = false;
//        return;
//    }
//    // 遇到了函数定义
//    if(CurTok == '{')
//    {
////        if((PreTok == ')' && (PreKHTok == tok_identifier || PreKHTok == '^')) || (PreTok == tok_identifier && (IdentifierStr == "const"|| IdentifierStr == "override")))
//        if(isWaitFuncDef)
//        {
//            isWaitFuncDef = false;
//            if(PreKHTok == tok_identifier || PreTok == tok_identifier)
//            {
//                handleFunction(false, true);
//            } else {
//                handleFunction(false, false);
//            }
//        }
//    }
//}
//
//static std::string randomAddOCProperty()
//{
//    std::string ret = "";
//    int count = arc4random() % 7;
//    std::string types[] = {"int", "double", "float", "bool", "NSString * ", "NSMutableArray *", "NSMutableDictionary *"};
//    int isNeedStrong[] = {0, 0, 0, 0, 1, 2, 2};
//    int len = getArrSize(types);
//    for(int i = 0; i < count; i++)
//    {
//        int rt = arc4random() % len;
//        switch(isNeedStrong[rt])
//        {
//            case 0:
//                ret += "@property (nonatomic, readwrite) " + types[rt] + " " + genNameForCplus(CVarName, false) + ";\n";
//                break;
//            case 1:
//                ret += "@property (nonatomic, readwrite, copy) " + types[rt] + " " + genNameForCplus(CVarName, false) + ";\n";
//                break;
//            case 2:
//                ret += "@property (nonatomic, strong) " + types[rt] + " " + genNameForCplus(CVarName, false) + ";\n";
//                break;
//            default:
//                break;
//        };
//    }
//    return ret;
//}
//
//// 处理@符号
//static void HandleOCDefine()
//{
//    if (getNextToken() == tok_identifier)
//    {
//        if(IdentifierStr == "interface") {
//            do{
//                while(getNextToken() != '@' && CurTok != tok_eof);
//                getNextToken();
//                if(CurTok == tok_identifier && IdentifierStr == "end")
//                {
//                    if(isInsertOcProp) {
//                        std::string proStr = randomAddOCProperty();
//                        output = output.insert(output.length() - 4, proStr);
//                    }
//                    return;
//                }
//            }
//            while(CurTok != tok_eof);
//        }
//        else if(IdentifierStr == "protocol")
//        {
//            do{
//                while(getNextToken() != '@' && CurTok != tok_eof);
//                getNextToken();
//                if(CurTok == tok_identifier && IdentifierStr == "end")
//                {
//                    return;
//                }
//            }
//            while(CurTok != tok_eof);
//        }
//        else if(IdentifierStr == "implementation")
//        {
//            do{
//                do
//                {
//                    getNextToken();
//                }
//                while(CurTok != '{' && CurTok != '-' && CurTok != '+' && CurTok != '@' && CurTok != tok_eof);
//                if(CurTok == '-' || CurTok == '+')
//                {
//                    while(getNextToken() != '{' && CurTok != tok_eof);
//                    handleFunction(true, true);
//                }
//                if(CurTok == '{' && PreTok == ')' && (PreKHTok == tok_identifier || PreKHTok == '^'))
//                {
//                    handleFunction(true, false);
//                }
//                if(CurTok == '@')
//                {
//                    getNextToken();
//                    if(CurTok == tok_identifier && IdentifierStr == "end")
//                    {
//                        break;
//                    }
//                }
//            }while(CurTok != tok_eof);
//        }
//    }
//    else
//    {
//        while(getNextToken() == tok_identifier && CurTok != tok_eof);
//        if(CurTok == ';')
//        {
//            return;
//        }
//    }
//}
//
//static void MainLoop() {
//    while (1) {
//        switch (CurTok) {
//            case tok_eof:    return;
//            case '@': {
//                HandleOCDefine();
//                break;
//            }
//            case ';': case tok_string: case tok_number:
//            {
//                getNextToken(); break;
//            }
//            default: {
//                HandleTopLevelExpression(); break;
//            }
//        }
//    }
//}
//
//const char * rcgCode(char * code, int _prop, char * fileExt)
//{
//    genNameClearCache();
//    funcNameSet.clear();
//    varNameSet.clear();
//    while(!storeDeep.empty())
//        storeDeep.pop();
//    DefineIdentifier = "";
//    funcCode = "";
//    varCode = "";
//    cache = "";
//    IdentifierStr = "";  // Filled in if tok_identifier
//    NumVal = 0;
//    curFileExt = fileExt;
//    isInFunc = false;
//    isAddStringObf = false;
//    isNSStrObf = [UserConfig sharedInstance].encodeNSString;
//    isCStrObf = [UserConfig sharedInstance].encodeCString;
//    isAddFunc = [UserConfig sharedInstance].insertFunction;
//    isAddCode = [UserConfig sharedInstance].insertCode;
//    isInsertOcProp = [UserConfig sharedInstance].addProperty;
//    LastChar = ' ';
//    file_content = code;
//    funcDeep = 0;
//    readPos = -1;
//    output = "";
//    CurTok = 0;
//    PreTok = 0;
//    PreKHTok = 0;
//    prop = _prop >= 0 ? _prop : 50;
//    if(curFileExt == "h" || curFileExt == "hpp")
//    {
//        isAddCode = false;
//        isAddFunc = false;
//        isNSStrObf = false;
//        isCStrObf = false;
//    }
//    MainLoop();
//    output = varCode + funcCode + output;
//    return output.c_str();
//}
//
//
