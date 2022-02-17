//
//  GBlock.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "GBlock.hpp"
#include "GRuntimeContext.hpp"
#include "GCommanFunc.hpp"
#include "GVarInfo.hpp"

namespace ocgen {

std::string Block::createVar(RuntimeContext * context, std::string varType, bool forceCreate) {
    std::string formatVarType = varType;
    replace_all_distinct(formatVarType, "*", "");
    replace_all_distinct(formatVarType, " ", "");
    BaseType* c = context->manager->getType(formatVarType);
    if(c) {
        context->cls->addDep(context, c->name);
        if(forceCreate || c->b_type == B_Class || c->b_type == B_Struct) {
            VarInfo * var = new VarInfo();
            string code = c->genOneInstance(context);
            var->type = c->name;
            var->order = genAnOrder();
            std::string varname = randomAVarName();
            var->name = varname;
            if(c->b_type == B_Class ) {
                auto line = new Line();
                line->code = c->name + "* " + varname + "="+ code + ";";
                line->order = var->order;
                lines.push_back(line);
            } else {
                auto line = new Line();
                line->code = c->name + " " + varname + "="+ code + ";";
                line->order = var->order;
                lines.push_back(line);
            }
            addVar(var);
            return varname;
        } else {
            return c->genOneInstance(context);
        }
    } else {
        vector<std::string> words;
        split(formatVarType, words, "-");
        std::string ret;
        std::string tp;
        if(words[0].find("int") == 0) {
            tp = "int";
            int max = 100, min = 0;
            if(words.size() > 0) {
                if(words.size() == 2) {
                    max = atoi(words[1].c_str());
                }
                if(words.size() > 2) {
                    min = atoi(words[1].c_str());
                    max = atoi(words[2].c_str());
                }
            }
            if(max == min)
                ret = to_string(min);
            else
                ret = to_string(arc4random() % (max - min));
        }
        else if(words[0].find("float") == 0 || words[0].find("CGFloat") == 0) {
            tp = "float";
            float max = 100.0, min = 0.0;
            if(words.size() > 1) {
                if(words.size() == 2) {
                    max = atof(words[1].c_str());
                }
                if(words.size() > 2) {
                    min = atof(words[1].c_str());
                    max = atof(words[2].c_str());
                }
            }
            if(max == min)
                ret = to_string(min);
            else
                ret = to_string(float(min) + float(arc4random() % int((max - min) * 1000)) / 1000.0);
        }
        else if(words[0].find("string") == 0) {
            tp = "char *";
            ret = "\"" + genRandomString(arc4random() % 100 < 20) + "\"";
        }
        else if(words[0].find("bool") == 0) {
            tp = "bool";
            ret = arc4random() % 2 == 0 ? "true" : "false";
        }
        if(forceCreate && ret != "") {
            std::string varname = randomAVarName();
            VarInfo * var = new VarInfo();
            var->order = genAnOrder();
            var->name = varname;
            var->type = words[0];
            addVar(var);
            auto line = new Line();
            line->code = tp + " " + varname + "=" + ret + ";";
            line->order = var->order;
            lines.push_back(line);
            return varname;
        } else {
            return ret;
        }
    }
    return "";
}

int Block::getCurMaxOrder() {
    maxOrder = minOrder > maxOrder ? minOrder : maxOrder;
    return maxOrder++;
}

int Block::genAnOrder(){
    int order = minOrder;
    if(minOrder < maxOrder) {
        order = arc4random() % (maxOrder - minOrder) + minOrder;
    }
    minOrder = order + 1;
    maxOrder = minOrder > maxOrder ? minOrder : maxOrder;
    return order;
}

void Block::resetOrder() {
    minOrder = 0;
}

void Block::addVar(VarInfo* var) {
    vars.push_back(var);
    if(typeVars.find(var->type) == typeVars.end()) {
        typeVars[var->type] = std::vector<VarInfo*>();
    }
    typeVars[var->type].push_back(var);
    if(var->order < 0) {
        var->order = genAnOrder();
    }
    if(context && context->cls) {
        context->cls->addDep(context, var->type);
    }
    adapterOrder(var->order);
}

static bool cmpLine(Line* x,Line* y) ///cmp函数传参的类型不是vector<int>型，是vector中元素类型,即int型
{
    return x->order < y->order;
}

static bool cmpBlock(Block* x,Block* y) ///cmp函数传参的类型不是vector<int>型，是vector中元素类型,即int型
{
    return x->self_order < y->self_order;
}

void Block::combineCode(std::vector<Line*>& vec){
    sort(childs.begin(), childs.end(), cmpBlock);
    sort(lines.begin(), lines.end(), cmpLine);
    auto block_itr = childs.begin();
    string tab = "  ";
    string space = "";
    string space_1 = "";
    for(int i = 0; i <= depth; i++ ) {
        space_1 = space;
        space += tab;
    }
    for(auto line_itr = lines.begin(); line_itr != lines.end(); line_itr++) {
        while(block_itr != childs.end() && (*block_itr)->self_order < (*line_itr)->order) {
            (*block_itr)->combineCode(vec);
            block_itr++;
        }
        if((*line_itr)->no_offset) {
            (*line_itr)->code = space_1 + (*line_itr)->code;
        } else {
            (*line_itr)->code = space + (*line_itr)->code;
        }
        
        vec.push_back(*line_itr);
    }
    while(block_itr != childs.end()) {
        (*block_itr)->combineCode(vec);
        block_itr++;
    }
}

std::string Block::selectOrCreateVar(RuntimeContext * context, std::string varType, int noSelectWeight) {
    VarInfo * var = selectVar(context, varType, noSelectWeight);
    if(!var) {
        return createVar(context, varType);
    }
    return var->name;
}

void Block::addLine(Line* line, bool incNum, bool needOffset) {
    line->no_offset = needOffset;
    lines.push_back(line);
    if(incNum) {
        context->remainLine--;
    }
};

VarInfo* Block::selectVar(RuntimeContext * context, std::string varType, int noSelectWeight) {
    if(arc4random() % 100 < noSelectWeight) { // 小概率不去池子里拿
        return nullptr;
    }
    std::string formatVarType = varType;
    replace_all_distinct(formatVarType, "*", "");
    replace_all_distinct(formatVarType, " ", "");
    int varNum = 0;
    Block * itr = this;
    while(itr) {
        if(varType == "") {
            varNum += itr->vars.size();
        } else {
            if(itr->typeVars.find(varType) != itr->typeVars.end()) {
                varNum += itr->typeVars[varType].size();
            }
        }
        itr = itr->pre;
    }
    VarInfo * var = nullptr;
    if(varNum > 0) {
        int index = arc4random() % varNum;
        itr = this;
        while(itr) {
            if(varType == "") {
                if(index < itr->vars.size()) {
                    var = itr->vars[index];
                    break;
                }
                index -= itr->vars.size();
            } else {
                if(itr->typeVars.find(varType) != itr->typeVars.end()) {
                    if(index < itr->typeVars[varType].size()) {
                        var = itr->typeVars[varType][index];
                        break;
                    }
                    index -= itr->typeVars[varType].size();
                }
            }
            itr = itr->pre;
        }
        
    }
    if(var) {
        adapterOrder(var->order);
        return var;
    }
    return nullptr;
}

void Block::adapterOrder(int dep_order) {
    minOrder = (minOrder < dep_order + 1) ? dep_order + 1 : minOrder;
    maxOrder = minOrder > maxOrder ? minOrder : maxOrder;
}

Block::~Block() {
   for(auto itr = lines.begin(); itr != lines.end(); itr++) {
       delete(*itr);
   }
   for(auto itr = childs.begin(); itr != childs.end(); itr++) {
       delete(*itr);
   }
}

int Block::getLastLineOrder() {
    return __ORDER_MAX__--;
}
}
