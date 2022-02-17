//
//  XBlock.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XBlock_hpp
#define XBlock_hpp

#include <stdio.h>
#include <string>
#include <vector>
#include "XLine.h"

namespace hygen
{

class Context;
class Method;

class Block : public Line
{
    friend class Context;
    std::vector<struct Var*> vars;
    std::vector<Method*> methods;
    std::vector<Line*> lines; // 初始化代码
    int __ORDER_MAX__;
    int maxOrder;
    int minOrder;
    std::string beforeCode;
    std::string afterCode;
public:
    Block(Context* cont) : pre(nullptr), context(cont), __ORDER_MAX__(INT_MAX),minOrder(0),maxOrder(0),beforeCode(""), afterCode("")
    {
        int offset = arc4random() % 200 + 100;
        maxValue = arc4random() % 100 + offset;
        minValue = maxValue - offset;
    }
    ~Block();
    void addToAfter(std::string code);
    void addToBefore(std::string code);
    void resetOrder();
    int genAnOrder();
    int getCurMaxOrder();
    int getLastLineOrder();
    void adapterOrder(int dep_order);
    Var * getVarByName(std::string ref);
    
    // 用于决定生成代码时的最大值和最小值
    int maxValue;
    int minValue;
    
    std::string createVar(std::string varType, float &maxValue, float &minValue, bool forceCreate = false);
    Var* selectVar(std::string varType, int noSelectWeight = 2);
    std::string selectOrCreateVar(std::string varType, float &maxValue, float &minValue, int noSelectWeight = 2);
    Method * randomAGlobalMethod();
    void addGlobalMethod(Method* m);
    
    void addVar(Var* var);
    void addLine(Line* line, bool incNum = true);
    
    Block * pre;
    Context * context;
    
    void mergeCode(std::string & code);
};

}

#endif /* XBlock_hpp */
