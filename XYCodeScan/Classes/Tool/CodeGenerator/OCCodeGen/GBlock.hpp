//
//  GBlock.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GBlock_hpp
#define GBlock_hpp

#include <stdio.h>
#include <string>
#include <vector>
#include <map>
#include "GLine.hpp"

namespace ocgen {

class RuntimeContext;
class VarInfo;

class Block
{
    std::vector<struct VarInfo*> vars;
    std::vector<Line*> lines; // 初始化代码
    std::map<std::string, std::vector<struct VarInfo*>> typeVars;
    int __ORDER_MAX__;
    int maxOrder;
    int minOrder;
    
public:
    Block() : pre(nullptr), context(nullptr), __ORDER_MAX__(INT_MAX),minOrder(0),maxOrder(0), self_order(0),depth(0)
    {
    }
    ~Block();
    RuntimeContext * context;
    std::vector<Block *> childs;
    Block * pre;
    int depth;
    void resetOrder();
    int genAnOrder();
    int getCurMaxOrder();
    int getLastLineOrder();
    void adapterOrder(int dep_order);
    int self_order;
    void combineCode(std::vector<Line*>& vec);
    
    
    std::string createVar(RuntimeContext * context, std::string varType, bool forceCreate = false);
    VarInfo* selectVar(RuntimeContext * context, std::string varType, int noSelectWeight = 2);
    std::string selectOrCreateVar(RuntimeContext * context, std::string varType, int noSelectWeight = 2);
    
    void addVar(VarInfo* var);
    void addLine(Line* line, bool incNum = true, bool pre_offset = false);
};

}

#endif /* GBlock_hpp */
