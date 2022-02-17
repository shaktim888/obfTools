#import <Foundation/Foundation.h>
#include "CG_Base.hpp"
#include "CG_Generator.hpp"
#include <fstream>
#include <sstream>
#include "OCCodeGen.hpp"
#include "CodeGenerator.h"
#include "CG_TypeManager.hpp"

static char * copyString(std::string str)
{
    auto len = str.length();
    if(len > 0) {
        char * data = (char *)malloc((len + 1)*sizeof(char));
        str.copy(data,len,0);
        data[len] = '\0';
        return data;
    } else {
        return nullptr;
    }
}

char * genClassToFolder(int type, int num, const char * saveFolder)
{
    if(type == gen::HYEnumTypes::Class_OC) {
        // oc重新写一遍
        genOcCode(num, saveFolder);
        return nullptr;
    }
    gen::CodeGenerator codeGenerator;
    std::vector<gen::HYClassInfo*> vec;
    for(int i = 0; i < num; i++) {
        auto cls = codeGenerator.genClass(type);
        vec.push_back(cls);
    }
    
    for(int i = 0; i < vec.size(); i++ ) {
        auto cls = vec[i];
        codeGenerator.buildClass(cls);
        std::ofstream fout;
        std::string outPath = saveFolder;
        outPath += "/" + cls->name;
        //        outPath += "/aa";
        switch(type) {
            case gen::HYEnumTypes::Class_OC:
            case gen::HYEnumTypes::Class_Cplus:
            {
                fout.open(outPath + ".h");
                fout << cls->declare;
                fout.close();
                if(type == gen::HYEnumTypes::Class_OC) {
                    fout.open(outPath + ".m");
                } else {
                    fout.open(outPath + ".mm");
                }
                fout << cls->body;
                fout.close();
                break;
            }
            case gen::HYEnumTypes::Class_Lua:
            {
                fout.open(outPath + ".lua");
                fout << cls->body;
                fout.close();
                break;
            }
            case gen::HYEnumTypes::Class_Js:
            {
                fout.open(outPath + ".js");
                fout << cls->body;
                fout.close();
                break;
            }
        }
    }
    if(type == gen::HYEnumTypes::Class_OC || type == gen::HYEnumTypes::Class_Cplus) {
        gen::HYMethodInfo * callAll = codeGenerator.genCallAllClass(vec);
        std::ofstream fout;
        std::string outPath = saveFolder;
        outPath += "/" + callAll->name;
        fout.open(outPath + ".h");
        fout << callAll->declare;
        fout.close();
        if(type == gen::HYEnumTypes::Class_OC) {
            fout.open(outPath + ".m");
        } else {
            fout.open(outPath + ".mm");
        }
        fout << callAll->body;
        fout.close();
        return copyString(callAll->name);
    }
    return nullptr;
}

struct GenClass * genOneClass(int type) {
    gen::CodeGenerator codeGenerator;
    GenClass * c = (GenClass *)malloc(sizeof(GenClass));
    auto cls = codeGenerator.genClass(type);
    c->body = copyString(cls->body);
    c->declare = copyString(cls->declare);
    c->className = copyString(cls->name);
    delete cls;
    return c;
}

struct GenMethod * genClassMemberMethod(int type, char * className)
{
    gen::CodeGenerator codeGenerator;
    GenMethod * method = (GenMethod *)malloc(sizeof(GenMethod));
    auto m = codeGenerator.genOneClassMethod(className, type, 0);
    method->methodName = copyString(m->name);
    method->body = copyString(m->body);
    method->declare = copyString(m->declare);
    return method;
}

char * genRandomOCProperty()
{
    gen::CodeGenerator codeGenerator;
    std::string str = codeGenerator.randomAddOCProperty();
    return copyString(str);
}

char * genRandomString(int isFileName)
{
    return copyString(gen::TypeManager::genRandomString(isFileName));
}
