#include <string>
#include "GenLibTools.hpp"
#include <vector>
#include <stdlib.h>
#include <dirent.h>
#include <map>
#include <set>
#include "NameGeneratorExtern.h"
#include <fstream>
using namespace std;

enum TypeEnum
{
    ENUM_Int = 10,
    ENUM_CharPtr = ENUM_Int + 3,
    ENUM_Float = ENUM_CharPtr + 2,
    ENUM_Double = ENUM_Float + 1,
    ENUM_TYPE_END
};

enum CalcEnum
{
    Enum_None = 1,
    ENUM_Add = Enum_None + 5,
    ENUM_Sub = ENUM_Add  + 5,
    ENUM_Mul = ENUM_Sub  + 2,
    ENUM_Div = ENUM_Mul  + 1,
    ENUM_OP_END
};

enum LogicEnum
{
    Logic_Calc = 5,
    Logic_Return = Logic_Calc + 5,
    ENUM_LOGIC_END
};

struct Method
{
    std::string name;
    int retType;
    std::vector<std::string> args;
};

static int randomFromTheTypes(std::vector<int> & types) {
    auto len = types.size() - 1;
    int rd = arc4random() % types[len];
    for(int i = 0; i < len; i++) {
        if(rd <= types[i]) {
            return types[i];
        }
    }
    return types[len - 1];
}

static std::string getOpName(int op) {
    switch (op) {
        case ENUM_Add:
            return "+";
            break;
        case ENUM_Sub:
            return "-";
            break;
        case ENUM_Mul:
            return "/";
            break;
        case ENUM_Div:
            return "/";
            break;
        default:
            break;
    }
    return "";
}

static char randomOneChar()
{
    switch (arc4random() % 3) {
        case 0:
            return char('a' + arc4random() % 26);
            break;
        case 1:
            return char('A' + arc4random() % 26);
            break;
        default:
            return char('0' + arc4random() % 10);
            break;
    }
}

static std::string getTypeName(int type) {
    switch (type) {
        case ENUM_Int:
            return "int ";
            break;
        case ENUM_CharPtr:
            return "char* ";
            break;
        case ENUM_Float:
            return "float ";
            break;
        case ENUM_Double:
            return "double ";
            break;
        default:
            break;
    }
    return "";
}

static std::string getRandomName() {
    static std::set<std::string> nameset;
    std::string name = "";
    do
    {
        int len = (arc4random() % 6) + 5;
        name = "sub_";
        for(int i = 0; i < len; i++) {
            name += randomOneChar();
        }
    }while(nameset.count(name) > 0);
    nameset.insert(name);
    return name;
}

static std::string genTypeValue(int type) {
    switch (type) {
        case ENUM_Int:
            return std::to_string(arc4random() % 100 + 1);
            break;
        case ENUM_Float:
            return std::to_string(arc4random() % 100 + 1) + "." + std::to_string(arc4random() % 100) + "f";
            break;
        case ENUM_Double:
            return std::to_string(arc4random() % 100 + 1) + "." + std::to_string(arc4random() % 100);
            break;
        case ENUM_CharPtr:
        {
            std::string ret = "\"";
            for(int i = 1; i > 0; i--) {
                ret += randomOneChar();
            }
            ret += "\"";
            return ret;
            break;
        }
        default:
            break;
    }
    return "";
}

static std::string getRandomVar(std::vector<std::string>& vars, int type, int op)
{
    if(vars.size() > 0) {
        if(arc4random() % 100 <= 50) {
            auto varName = vars[arc4random() % vars.size()];
            if(op == ENUM_Mul) {
                return "(" + varName + " > 0 ? " + varName + " : 1 )";
            }
            return vars[arc4random() % vars.size()];
        }
    }
    return genTypeValue(type);
}

static std::string getOneLogic(Method * method) {
    if(method->retType == ENUM_CharPtr) {
        return std::string("return ") + getRandomVar(method->args, method->retType, Enum_None) + ";\n";
    }
    static std::vector<int> logics = { Logic_Calc, Logic_Return, ENUM_LOGIC_END };
    static std::vector<int> ops = { ENUM_Add, ENUM_Sub, ENUM_Mul , ENUM_Div, ENUM_OP_END};
    int logic = randomFromTheTypes(logics);
    switch (logic) {
        case Logic_Return:
        {
            return "return " + getRandomVar(method->args, method->retType, Enum_None) + ";\n";
            break;
        }
        case Logic_Calc:
        {
             static std::vector<int> ops = { ENUM_Add, ENUM_Sub, ENUM_Mul , ENUM_Div, ENUM_OP_END};
            int op = randomFromTheTypes(ops);
            if(method->retType == ENUM_Int && op == ENUM_Div) {
                op = (arc4random() % 2) ? ENUM_Add : ENUM_Sub;
            }
            return "return " + getRandomVar(method->args, method->retType, Enum_None) + getOpName(op) + getRandomVar(method->args, method->retType, op) + ";\n";
        }
        default:
            break;
    }
    return "";
}

static Method* genOneStaticFunc(std::string& content)
{
    static std::vector<int> types = {ENUM_Int, ENUM_CharPtr, ENUM_Float, ENUM_Double, ENUM_TYPE_END };
    auto method = new Method();
    method->retType = randomFromTheTypes(types);
    method->name = getRandomName();
    int args = arc4random() % 4;
    content += "static inline " + getTypeName(method->retType) + method->name + "(";
    for(int i = 0; i < args; i++) {
        std::string argName = getRandomName();
        method->args.push_back(argName);
        content += std::string((i == 0) ? "" : ",") + getTypeName(method->retType) + argName;
    }
    content += ") {\n";
    content += getOneLogic(method);
    content += "}\n";
    return method;
}

static void genCallFunc(std::vector<Method *>& methods, std::string& content)
{
    std::map<int , std::vector<std::string>> vars;
    
    vars[ENUM_Int] = std::vector<std::string>();
    vars[ENUM_Float] = std::vector<std::string>();
    vars[ENUM_Double] = std::vector<std::string>();
    vars[ENUM_CharPtr] = std::vector<std::string>();
    
    for(int i = 0; i < methods.size(); i++) {
        auto m = methods[i];
        bool useVar = arc4random() % 100 <= 10;
        if(useVar) {
            content += getTypeName(m->retType) + "var" + std::to_string(i) + " = " + m->name + "(";
        } else {
            content += m->name + "(";
        }
        for(int x = 0; x < m->args.size(); x++) {
            content += (x == 0) ? "" : ",";
            content += getRandomVar(vars[m->retType], m->retType, Enum_None);
        }
        if(useVar) {
            vars[m->retType].push_back(std::string("var") + std::to_string(i));
        }
        content += ");\n";
    }
}

void GenLibTools::genOneFile(int numOfFunc, char * saveTo)
{
    std::vector<Method*> methods;
    std::string content = "";
    for(int i = 0; i < numOfFunc; i++) {
        methods.push_back(genOneStaticFunc(content));
    }
    std::string funcName = genNameForCplus(CFuncName, true);
//    std::string funcName = "disableWhite";
    content += "extern void " + funcName + "() {\n";
    genCallFunc(methods, content);
    content += "}\n";
    std::ofstream fout;
    std::string outPath = std::string(saveTo) + "/" + funcName;
    fout.open(outPath + ".m");
    fout << content;
    fout.close();
    std::string headContent = "";
    std::string def = "__" + funcName + "__h";
    headContent += "#ifndef " + def + "\n";
    headContent += "#define " + def + "\n";
    
    headContent += "extern void " + funcName + "();\n";
    
    headContent += "#endif\n";
    fout.open(outPath + ".h");
   
    fout << headContent;
    fout.close();
    
    for(int i = 0 ; i < methods.size(); i++ ) {
        delete methods[i];
    }
}

void GetFilesName(string path, vector<string>& files)
{
    struct dirent *dirp;
    
    DIR* dir = opendir(path.c_str());
    
    while ((dirp = readdir(dir)) != nullptr) {
        if (dirp->d_type == DT_REG) {
            // 文件
            files.push_back(dirp->d_name);
            
        } else if (dirp->d_type == DT_DIR) {
            // 文件夹
//            GetFilesName(dirp->d_name, files);
        }
    }
    
    closedir(dir);
}

string getFileExt(string filePath)
{
    string fileExt;
    char *ptr, c = '.';
    int pos = filePath.find_last_of('.');
    //获取后缀
    return filePath.substr(pos+1, filePath.size());
}

void GenLibTools::autoCompile(char *folder, char *toFolder) {
    vector<string> files;
    GetFilesName(folder, files);
    for(auto itr = files.begin(); itr != files.end(); itr++) {
        string filePath = string(folder) + "/" + *itr;
        string ext = getFileExt(filePath);
        if(ext == "h") {
            
        }
    }
}


extern "C" void genOneFile(int numOfFunc, char * saveTo) {
    GenLibTools tools;
    tools.genOneFile(numOfFunc, saveTo);
}

extern "C" void compileFolder(char * folder, char * saveTo) {
    GenLibTools tools;
    tools.autoCompile(folder, saveTo);
}
