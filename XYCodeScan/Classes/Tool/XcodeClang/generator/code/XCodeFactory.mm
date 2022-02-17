//
//  XCodeFactory.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/29.
//

#include "XCodeFactory.hpp"
#include "XContext.h"
#include <regex>
#include "XCommanFunc.hpp"
#include "XCodeLine.h"
#import "NSString+Extension.h"
#include <set>

using namespace std;
namespace hygen {

CodeFactory::CodeFactory()
:curNeedWait(true),context(nullptr),topParser(nullptr)
{
    loadAllTpFile();
    typeManager = new TypeManager();
}

CodeFactory::~CodeFactory() {
}

void CodeFactory::supportType(int type) {
    if(trueTpMap.find(type) == trueTpMap.end()) {
        trueTpMap[type] = std::vector<std::string>();
        falseTpMap[type] = std::vector<std::string>();
        
        trueOpTp[type] = std::map<std::string, std::string>();
        falseOpTp[type] = std::map<std::string, std::string>();
    }
}

void CodeFactory::loadAllTpFile() {
    supportType(CodeMode_OC);
    supportType(CodeMode_C);
    supportType(CodeMode_CXX);
    
    loadTpFolder(true);
    loadTpFolder(false);
}

void CodeFactory::loadTpFolder(bool isTrue)
{
    std::map<int, std::vector<std::string>>& tpMap = isTrue ? trueTpMap : falseTpMap;
    std::map<int, std::map<std::string, std::string>> &opMap = isTrue ? trueOpTp : falseOpTp;
    
    NSString * folder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"File/CodeGenerator/template/"];
    folder = [folder stringByAppendingPathComponent:isTrue ? @"true" : @"false"];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:folder];
    for (NSString *subpath in subpaths) {
        if ([subpath hasSuffix:@".tp"]) {
            NSString * ocContent = [NSString hy_stringWithFile:[folder stringByAppendingPathComponent:subpath]];
            std::string content = [ocContent UTF8String];
            NSString * fileName = [subpath stringByDeletingPathExtension];
            
            std::vector<std::string> arr;
            split(content, arr, "##");
            std::vector<std::string> surport;
            split(arr[1], surport, ",");
            bool isBlock = [fileName hasPrefix:@"block_"];
            fileName = [fileName stringByReplacingOccurrencesOfString:@"op_" withString:@""];
            trim(arr[2]);
            for(int i = 0 ; i < surport.size(); i++) {
                trim(surport[i]);
                if(surport[i] == "oc") {
                    if(isBlock) {
                        tpMap[CodeMode_OC].push_back(arr[2]);
                    } else {
                        opMap[CodeMode_OC][[fileName UTF8String]] = arr[2];
                    }
                }
                if(surport[i] == "c") {
                    if(isBlock) {
                        tpMap[CodeMode_C].push_back(arr[2]);
                    } else {
                        opMap[CodeMode_C][[fileName UTF8String]] = arr[2];
                    }
                }
                if(surport[i] == "c++") {
                    if(isBlock) {
                        tpMap[CodeMode_CXX].push_back(arr[2]);
                    } else {
                        opMap[CodeMode_CXX][[fileName UTF8String]] = arr[2];
                    }
                }
            }
       }
    }
}

bool CodeFactory::isStart() {
    return context;
}

void CodeFactory::start(CodeMode m, bool isInsert) {
    if(context) {
        delete context;
    }
    context = new Context(this, m, isInsert);
    context->manager = typeManager;
}

std::string CodeFactory::finish() {
    popCodeStack();
    // 获得代码
    std::string code;
    context->getFullCode(code);
    delete context;
    context= nullptr;
    return code;
}

void CodeFactory::resetTopParser() {
    topParser = nullptr;
}

void CodeFactory::insertCode(std::string code, bool canWrap, bool insertCode) {
    context->remainLine = 5;
    curNeedWait = canWrap;
    if(!canWrap) { // 可包裹
        while (topParser != NULL) {
            topParser->parser();
        }
    }
    if(insertCode) {
        genCode(true, canWrap);
    }
    if(code.length() > 0) {
        CodeLine * line = new CodeLine();
        // 放在当前的最后一行
        line->order = context->curBlock->getCurMaxOrder();
        line->code = code;
        line->noLn = true;
        context->curBlock->addLine(line, false);
    }
}

void CodeFactory::appendToAfter(std::string code) {
    if(context) {
        context->curBlock->addToAfter(code);
    }
}

void CodeFactory::insertToBefore(std::string code) {
    if(context) {
        context->curBlock->addToBefore(code);
    }
}

bool CodeFactory::genCode(bool isRun, bool canWrap, bool notParser) {
    context->curBlock->resetOrder();
    if(!notParser && topParser != NULL) {
        // 有概率让它会跳出。再继续执行下一个代码工作
        if(arc4random() % 100 < topParser->recordLines * 20) {
            topParser->parser();
        }
    }
    if(topParser != NULL) {
        topParser->recordLines++;
    }
    context->remainLine--;
    if(canWrap && arc4random() % 100 < 20) {
        return randomABlock(isRun);
    } else {
        Var * var = context->curBlock->selectVar("", 20);
        while(!var) {
            string tp = context->manager->randomAType(context, isRun);
            float mx1 = -INT_MAX, mn1 = INT_MAX;
            context->curBlock->createVar(tp,mx1, mn1, true);
            var = context->curBlock->selectVar(tp);
        }
        context->manager->call(context, var);
    }
    return false;
}

std::string CodeFactory::genCondition(bool mustTrue) {
    Var * var = context->curBlock->selectVar("");
    while(!var) {
        string tp = context->manager->randomAType(context, mustTrue);
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        context->curBlock->createVar(tp, mx1, mn1, true);
        var = context->curBlock->selectVar(tp);
    }
    return context->manager->getBooleanValue(context, var, mustTrue);
}


void CodeFactory::enterBlock(std::string code) {
    if(context) {
        context->enterBlock(code);
    }
    storeCodeParserStack();
}

void CodeFactory::storeCodeParserStack() {
    codeDepthStack.push(coro_stack.size());
    topParser = nullptr;
}

void CodeFactory::exitBlock(std::string code) {
    popCodeStack();
    
    if(context) {
        context->exitBlock(code);
    }
}

void CodeFactory::popCodeStack() {
    int s = 0;
    if(codeDepthStack.size() > 0) {
        s = codeDepthStack.top();
        codeDepthStack.pop();
    }
    while(coro_stack.size() > s) {
        auto status = coro_stack.top();
#ifdef __PARSER_DEBUG__
        printf("popTop: %p\n", status);
#endif
        status->parser();
    }
    if(coro_stack.size() > 0) {
        topParser = coro_stack.top();
    } else {
        topParser = nullptr;
    }
}

static void reviewAllCalled(Method * method, std::set<Method *> &record) {
    if(method->called.size() > 0)
    {
        for(auto iter = method->called.begin(); iter != method->called.end() ; ++iter)
        {
            auto m = *iter;
            if(m && record.count(m) == 0) {
                record.insert(m);
                reviewAllCalled(m, record);
            }
        }
    }
}

bool CodeFactory::checkFunctionIsConflict(Method * fromMethod, Method * toMethod) {
    std::set<Method *> called;
    reviewAllCalled(toMethod, called);
    if(called.count(fromMethod)) {
        return true;
    }
    return false;
}

bool CodeFactory::onToken(CodeParser * parser, const std::string & token, std::string& collect)
{
    if(token == "block_start") {
        context->enterBlock(collect);
        collect = "";
    } else if(token == "block_end") {
        context->exitBlock(collect);
        collect = "";
    } else if(token == "block") {
        if(collect != "") {
            auto line = new CodeLine();
            line->order = context->curBlock->getCurMaxOrder();
            line->code = collect;
            context->curBlock->addLine(line, false);
            collect = "";
        }
        if(curNeedWait) {
            return true;
        }
    } else if(token == "block_false") {
        context->curBlock->addToBefore(collect);
        collect = "";
        if(context->remainLine > 0) {
            return genCode(false, true, true);
        }
    } else if(token.find("declare") == 0) {
        std::vector<std::string> cuts;
        split(token, cuts, "_");
        std::string varName = randomAVarName();
        parser->varCache[cuts[1]] = varName;
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        std::string ref = context->curBlock->createVar(cuts[2],mx1, mn1);
        collect += context->manager->formatTypeName(context, cuts[2]) + " " + varName + " = " + ref;
        auto var = new Var();
        var->varName = varName;
        var->typeName = cuts[2];
        var->maxValue = mx1;
        var->minValue = mn1;
        context->curBlock->addVar(var);
    } else if(token == "int" || token == "float") {
        std::string typeName = token;
        float mx1 = -INT_MAX, mn1 = INT_MAX;
        collect += context->curBlock->selectOrCreateVar(token, mx1, mn1);
    } else if(token == "bool") {
        collect += genCondition(arc4random() % 2 == 0);
    } else if(token == "true") {
        collect += genCondition(true);
    } else if(token == "false") {
        collect += genCondition(false);
    } else {
        if(parser->varCache.find(token) != parser->varCache.end()) {
            collect += parser->varCache[token];
        } else {
            collect += token;
        }
    }
    return false;
}

void CodeFactory::onParseFinish(CodeParser * parser, std::string& collect)
{
    auto line = new CodeLine();
    line->code = collect;
    line->order = context->curBlock->getCurMaxOrder();
    context->curBlock->addLine(line, false);
    collect = "";
#ifdef __PARSER_DEBUG__
    printf("finish: %p\n", parser);
#endif
    topParser = parser->parent;
    delete parser;
    coro_stack.pop();
}

bool CodeFactory::randomABlock(bool isTrue) {
    std::vector<std::string>& vec = isTrue ? trueTpMap[context->cmode] : falseTpMap[context->cmode];
    int index = arc4random() % vec.size();
    
    auto parser = new CodeParser(this, vec[index], topParser);
#ifdef __PARSER_DEBUG__
    printf("create: %p\n", parser);
    printf("createCode: %s\n", vec[index].c_str());
#endif
    parser->recordLines = 0;
    coro_stack.push(parser);
    topParser = parser;
    return parser->parser();
}

}
