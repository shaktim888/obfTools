//
//  CG_Context.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_Context_hpp
#define CG_Context_hpp

#include <stdio.h>
#include "CG_ClassInfo.hpp"
#include "CG_VarInfo.hpp"
namespace gen {


typedef struct Line
{
    int order;
    std::string code;
    bool no_offset;
} Line;

class RuntimeContext;

class HYNewCodeBlock
{
    std::vector<struct HYVarInfo*> vars;
    std::vector<Line*> lines; // 初始化代码
    std::map<string, std::vector<struct HYVarInfo*>> typeVars;
    int __ORDER_MAX__;
    int maxOrder;
    int minOrder;

public:
    HYNewCodeBlock() : pre(nullptr), context(nullptr), __ORDER_MAX__(INT_MAX),minOrder(0),maxOrder(0), self_order(0),depth(0)
    {}
    ~HYNewCodeBlock();
    RuntimeContext * context;
    std::vector<HYNewCodeBlock *> childs;
    HYNewCodeBlock * pre;
    int depth;
    void resetOrder();
    int genAnOrder();
    int getCurMaxOrder();
    int getLastLineOrder();
    void adapterOrder(int dep_order);
    int self_order;
    void combineCode(std::vector<Line*>& vec);

    std::string createVar(RuntimeContext * context, std::string varType, bool forceCreate = false);
    HYVarInfo* selectVar(RuntimeContext * context, std::string varType, int noSelectWeight = 2);
    std::string selectOrCreateVar(RuntimeContext * context, std::string varType, int noSelectWeight = 2);

    void addVar(HYVarInfo* var);
    void addLine(Line* line, bool incNum = true, bool pre_offset = false);
};


class RuntimeContext
{
public:
    RuntimeContext()
    :cls(nullptr) ,curMethod(nullptr)
    ,curBlock(nullptr) ,remainLine(0)
    {}
    HYClassInfo * cls;
    HYMethodInfo * curMethod;
    HYNewCodeBlock * curBlock; // 代码块
    HYNewCodeBlock * rootBlock;
    int remainLine;

    void resetOrder();

    void enterBlock();

    void exitBlock();


};


}
#endif /* CG_Context_hpp */
