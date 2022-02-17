//
//  OCCodeGen.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/1.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "OCCodeGen.hpp"
#include "GOCClassInfo.hpp"
#include "GAllTypeManager.hpp"
#include <regex>
#import "HYGenerateNameTool.h"
#import "NameGeneratorExtern.h"
#include "GRuntimeContext.hpp"
#include "GParamInfo.hpp"
#include "GPropInfo.hpp"

using namespace std;

namespace ocgen {

class AutoBlock
{
    RuntimeContext * context;
public:
    AutoBlock(RuntimeContext * _context) {
        context = _context;
        context->enterBlock();
    }
    ~AutoBlock() {
        context->exitBlock();
    }
};

class OCCodeGen
{
public:
    // 创建出类声明
    void genAllClassDec(int n, const char * folder)
    {
        AllTypeManager* manager = AllTypeManager::getInstance();
        manager->clearAllCustomType();
        std::vector<OCClassInfo *> allCls;
        for(int i = 0;i < n; i ++ ){
            auto cls = genClassDec(manager);
            allCls.push_back(cls);
            manager->addCustomType(cls);
        }
        
        for(int i = 0;i < allCls.size(); i++) {
            genClassAllMethods(allCls[i], folder);
        }
    }
    
    OCClassInfo * genClassDec(AllTypeManager* manager)
    {
        genNameClearCache(CFuncName);
        // 1. 选出要继承的类
        auto inter = manager->randomAInterface();
        NSString * cname = [HYGenerateNameTool generateByTypeName:TypeName from:[NSString stringWithUTF8String:inter->name.c_str()] cache:true];
        OCClassInfo * cls = new OCClassInfo();
        cls->name = [cname UTF8String];
        cls->superclass = inter->name;
        cls->b_type = B_Class;
        // 2. 类名采用 单词+类名后缀（1-2个，如果是单字母就一个，或者没有）
        // 3. 选出部分进行继承
        if(inter->methods.size() > 0) {
            int extCnt = 0;
            int si = arc4random() % inter->methods.size();
            for(int i = -1; i != si && extCnt <= 5; i= (i + 1)% inter->methods.size()) {
                if(i < 0) i = si;
                if(arc4random() % 3 == 0) {
                    extCnt++;
                    MethodInfo * m = new MethodInfo();
                    m->name = inter->methods[i]->name;
                    m->retType = inter->methods[i]->retType;
                    m->declare = inter->methods[i]->declare;
                    m->methodType = B_Interface;
                    for(auto itr = inter->methods[i]->params.begin(); itr != inter->methods[i]->params.end(); itr++ ) {
                        ParamInfo * pp = new ParamInfo();
                        pp->name = (*itr)->name;
                        pp->type = (*itr)->type;
                        pp->var = (*itr)->var;
                        m->params.push_back(pp);
                    }
                    cls->interfaceMethods.push_back(m);
                }
            }
        }
        OCClassInfo * superCls = dynamic_cast<ocgen::OCClassInfo *>(manager->getType(inter->name));
        if(superCls) {
            // 拷贝是为了管理和释放方便。也可以使用用引用计数。懒得在这里花很大精力。
            for(auto itr = superCls->props.begin(); itr != superCls->props.end(); itr++) {
                cls->props.push_back((*itr)->copy());
            }
            for(auto itr = superCls->publicMethods.begin(); itr != superCls->publicMethods.end(); itr++) {
                cls->publicMethods.push_back((*itr)->copy());
            }
        }
        
        // 4. 创建函数。函数参数先确定类型。建立类型对应的参数名字映射。比如数字对应len、count。如果是类则取类的后缀。
        int randNum = arc4random() % 5 + 5;
        int percent = 10;
        for(int i = 0; i < randNum; i++) {
            genNameClearCache(CArgName);
            MethodInfo * m = new MethodInfo();
            m->retType = manager->randomAType(nullptr);
            m->methodType = B_Method;
            NSString * methodName = [HYGenerateNameTool generateByTypeName:FuncName from:[NSString stringWithUTF8String:m->retType.c_str()] cache:true];
            m->name = [methodName UTF8String];
            int parmNum = arc4random() % 3 + 1;
            while(parmNum > 0) {
                ParamInfo * parm = new ParamInfo();
                parm->type = manager->randomAType(nullptr, percent);
                parm->name = [[HYGenerateNameTool generateByTypeName:ArgName from:[NSString stringWithUTF8String:parm->type.c_str()] cache:true] UTF8String];
                parm->var = parm->name;
                percent += 30;
                m->params.push_back(parm);
                parmNum--;
            }
            cls->customMethods.push_back(m);
        }
        return cls;
    }
    
    void genClassAllMethods(OCClassInfo * cls, const char * outfolder)
    {
        AllTypeManager* manager = AllTypeManager::getInstance();
        // 1. 创建上下文对象.填入类型
        RuntimeContext context;
        context.cls = cls;
        context.manager = manager;
        AutoBlock _auto_block(&context);
        {
            cls->addDep(&context, cls->superclass);
            cls->addDep(&context, cls->name);
            auto line = new Line();
            line->code = "@implementation " + cls->name;
            line->order = context.curBlock->genAnOrder();
            context.curBlock->addLine(line, false, true);
        }
        {
            auto line = new Line();
            line->code = "@end";
            line->order = context.curBlock->getLastLineOrder();
            context.curBlock->addLine(line, false, true);
        }
        {
            auto var = new VarInfo();
            var->name = "self";
            var->type = cls->name;
            var->order = context.curBlock->genAnOrder();
            context.curBlock->addVar(var);
        }
        // 2. 遍历函数。开始进行实现函数体
        for(auto itr = cls->interfaceMethods.begin(); itr != cls->interfaceMethods.end(); itr++) {
            enterFunc(&context, *itr);
        }
        for(auto itr = cls->customMethods.begin(); itr != cls->customMethods.end(); itr++) {
            enterFunc(&context, *itr);
        }
        string folder = outfolder;
        if(folder[folder.size() - 1] != '/') {
            folder += "/";
        }
        genClsHeadFile(&context, folder + cls->name + ".h");
        genClsBodyFile(&context, folder + cls->name + ".m");
    }
    
    void genClsHeadFile(RuntimeContext * context, std::string outfile) {
        context->cls->removeDep(context, context->cls->name);
        string genCode = "";
        
        for(auto itr = context->cls->addedLib.begin(); itr != context->cls->addedLib.end(); itr++) {
            string tname = itr->first;
            if(context->manager->getType(tname)) {
                genCode += "@class " + itr->first + ";\n";
            } else {
                genCode += "#import " + itr->first + "\n";
            }
            
        }
        genCode += "@interface " + context->cls->name + " : " + context->cls->superclass + "\n";
        
        for(auto itr = context->cls->interfaceMethods.begin(); itr != context->cls->interfaceMethods.end(); itr++) {
            genCode += (*itr)->getDeclareString(context) + ";\n";
        }
        for(auto itr = context->cls->customMethods.begin(); itr != context->cls->customMethods.end(); itr++) {
            genCode += (*itr)->getDeclareString(context) + ";\n";
        }
        genCode += "@end";
        
        FILE *fp = NULL;
        fp = fopen(outfile.c_str(), "wb+");
        if (NULL == fp)
        {
            return;
        }
        
        fwrite(genCode.c_str(), genCode.size(), 1, fp);
        
        fclose(fp);
    }
    
    void genClsBodyFile(RuntimeContext * context, std::string outfile) {
        // 合并所有的代码
        vector<Line*> codes;
        context->rootBlock->combineCode(codes);
        string genCode = "";
        for(auto itr = codes.begin(); itr != codes.end(); itr++) {
            genCode += (*itr)->code + "\n";
        }
        FILE *fp = NULL;
        fp = fopen(outfile.c_str(), "wb+");
        if (NULL == fp)
        {
            return;
        }
        fwrite(genCode.c_str(), genCode.size(), 1, fp);
        
        fclose(fp);
    }
    
    
    void enterFunc(RuntimeContext * context, MethodInfo * m)
    {
        AutoBlock _auto_block(context);
        context->curMethod = m;
        m->genDeclare(context);
        // 1. 将函数的参数放到变量池中
        for(auto itr = m->params.begin(); itr != m->params.end(); itr++) {
            if(context->manager->isCanOpType((*itr)->type)) {
                context->cls->addDep(context, (*itr)->type);
                VarInfo * var = new VarInfo();
                var->name = (*itr)->var;
                var->type = (*itr)->type;
                var->order = context->curBlock->genAnOrder();
                context->curBlock->addVar(var);
            }
        }
        // 2. 如果是创建函数模式。
            // 调用super函数，插入到before
        if(m->methodType == B_Interface) {
            superCall(context);
        }
        // 创建返回值对象 键入到body。加入到变量池。将返回语句插入到after
        {
            if(context->manager->isCanOpType(m->retType)) {
                context->cls->addDep(context, m->retType);
                std::string retVarname = context->curBlock->createVar(context, m->retType, true);
                auto line = new Line();
                line->code = "return " + retVarname + ";";
                line->order = context->curBlock->getLastLineOrder();
                context->curBlock->addLine(line, false);
            } else {
                if(m->retType != "void")
                {
                    printf("严重错误：无法生成函数的返回值 %s\n", m->retType.c_str());
                }
            }
        }
        // 3. 循环调用block
        int cnt = arc4random() % 3 + 5;
        context->remainLine = cnt;
        while(context->remainLine > 0) {
            block(context);
        }
    }

    void block(RuntimeContext * context) {
        context->curBlock->resetOrder();
        int kind = arc4random() % 100;
        if(kind < 10) {
            block_if(context);
        } else if(kind < 20) {
            block_while(context);
        } else {
            block_callvar(context);
        }
        // 1. 寻找一个变量
            // 调用函数。如果是数组。生成自由运算
            // 如果
        
    }
    
    void block_callvar(RuntimeContext * context) {
        VarInfo * var = context->curBlock->selectVar(context, "");
        while(!var) {
            string tp = context->manager->randomAType(context, 1);
            context->curBlock->createVar(context, tp, true);
            var = context->curBlock->selectVar(context, tp);
        }
        BaseType* c = context->manager->getType(var->type);
        if(c) {
            c->objectCall(context, var);
        } else {
            if(context->manager->isNumType(var->type)) {
                auto line = new Line();
                line->code = var->name + "=" + _genNumberOpStr(context, arc4random() % 2 + 2, var->type) + ";";
                line->order = context->curBlock->genAnOrder();
                context->curBlock->addLine(line);
            }
            if(var->type == "bool") {
                VarInfo * select = context->curBlock->selectVar(context, "");
                while(!select || select == var) {
                    string tp = context->manager->randomAType(context, 1);
                    context->curBlock->createVar(context, tp, true);
                    select = context->curBlock->selectVar(context, tp);
                }
                string cond = gen_condition(context, select);
                auto line = new Line();
                line->order = context->curBlock->genAnOrder();
                line->code = var->name + " = " + cond + ";";
                context->curBlock->addLine(line);
            }
        }
    }

    std::string _genNumberOpStr(RuntimeContext * context, int deep, string& typeName) {
        static std::vector<string> numOp = {
            "+", "-", "*" //, "/"
        };
                
        if(deep <= 0) {
            return context->curBlock->selectOrCreateVar(context, typeName, 20) + numOp[arc4random() % numOp.size()] + context->curBlock->selectOrCreateVar(context, typeName, 20);
        }
        int rd = arc4random() % 3;
        switch (rd) {
            case 1:
                return context->curBlock->selectOrCreateVar(context, typeName, 20) + numOp[arc4random() % numOp.size()] + "(" + _genNumberOpStr(context, deep - 1, typeName) + ")";
                break;
            case 2:
                return "(" + _genNumberOpStr(context, deep - 1, typeName) + ")" + numOp[arc4random() % numOp.size()] + context->curBlock->selectOrCreateVar(context, typeName, 20) ;
                break;
            default:
                return context->curBlock->selectOrCreateVar(context, typeName, 20) + numOp[arc4random() % numOp.size()] + _genNumberOpStr(context, deep - 1, typeName);
                break;
        }
    }
    
    string gen_condition(RuntimeContext * context, VarInfo * var) {
        BaseType * c = context->manager->getType(var->type);
        if(c) {
            return c->execABoolValue(context, var);
        } else {
            if(context->manager->isNumType(var->type)) {
                static vector<string> ops = {">", ">=", "<=", "<", "==", "!="};
                return var->name + ops[arc4random() % ops.size()] + to_string(arc4random() % 100);
            }
            if(var->type == "bool") {
                return var->name;
            }
        }
        return "true";
    }
    
    void block_if(RuntimeContext * context) {
        VarInfo * var = context->curBlock->selectVar(context, "");
        while(!var) {
            string tp = context->manager->randomAType(context, 1);
            context->curBlock->createVar(context, tp, true);
            var = context->curBlock->selectVar(context, tp);
        }
        string cond = gen_condition(context, var);
        AutoBlock _auto_block(context);
        {
            auto sline = new Line();
            sline->code = "if(" + cond + ") {";
            sline->order = context->curBlock->genAnOrder();
            context->curBlock->addLine(sline, true, true);
        }
        {
            auto eline = new Line();
            eline->code = "}";
            eline->order = context->curBlock->getLastLineOrder();
            context->curBlock->addLine(eline, false, true);
        }
        // 随机生成几句
        int num = 1;
        if(context->remainLine > 0) {
            num = arc4random() % context->remainLine + 1;
        }
        for(int i = 0; i < num; i++) {
            block(context);
        }
    }
    
    void block_while(RuntimeContext * context) {
        VarInfo * var = context->curBlock->selectVar(context, "");
        while(!var) {
            string tp = context->manager->randomAType(context, 1);
            context->curBlock->createVar(context, tp, true);
            var = context->curBlock->selectVar(context, tp);
        }
        string cond = gen_condition(context, var);
        AutoBlock _auto_block(context);
        {
            auto sline = new Line();
            sline->code = "while(" + cond + ") {";
            sline->order = context->curBlock->genAnOrder();
            context->curBlock->addLine(sline, true, true);
        }
        {
            auto eline = new Line();
            eline->code = "}";
            eline->order = context->curBlock->getLastLineOrder();
            context->curBlock->addLine(eline, false, true);
        }
        // 随机生成几句
        int num = 1;
        if(context->remainLine > 0) {
            num = arc4random() % context->remainLine + 1;
        }
        for(int i = 0; i < num; i++) {
            block(context);
        }
    }
    
    void superCall(RuntimeContext * context) {
        MethodInfo * m = context->curMethod;
        std::string supercall = "[super " + m->name;
        for (auto p = m->params.begin(); p != m->params.end(); p++) {
            if(p == m->params.begin()) {
                supercall = supercall + ":" + (*p)->var;
            } else {
                supercall = supercall + " " + (*p)->name + ":" + (*p)->var;
            }
        }
        supercall += "];";
        Line * line = new Line();
        line->code = supercall;
        line->order = -1; // 最优先调用
        context->curBlock->addLine(line);
    }
    
private:
    std::vector<OCClassInfo *> cls;
};
 
}

void genOcCode(int n, const char * outpath) {
    ocgen::OCCodeGen gen;
    gen.genAllClassDec(n, outpath);
}
