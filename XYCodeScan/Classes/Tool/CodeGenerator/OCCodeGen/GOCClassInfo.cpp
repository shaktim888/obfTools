//
//  ClassInfo.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "GOCClassInfo.hpp"
#include "GRuntimeContext.hpp"
#include "GCommanFunc.hpp"
#include "GParamInfo.hpp"
#include "GPropInfo.hpp"

namespace ocgen {

std::string OCClassInfo::genOneInstance(RuntimeContext * context)
{
    context->cls->addDep(context, name);
    size_t total = createMethods.size() + initMethods.size();
    if(total > 0) {
        int index = arc4random() % total;
        if(index < createMethods.size()) {
            MethodInfo* m = createMethods[index];
            std::string call = m->getRealCall(context);
            replace_all_distinct(call, "#this", this->name);
            replace_all_distinct(call, "#self", this->name);
            if(!m->isconst && !(m->call.find("(") != string::npos && m->call.find(")") != string::npos)
               && !(m->call.find("[") == 0 && m->call.find("]") == m->call.length() - 1)) {
                return string("[") + this->name + " " + call + "]";
            } else {
                return call;
            }
        } else {
            MethodInfo* m = initMethods[index - createMethods.size()];
            std::string call = m->getRealCall(context);
            replace_all_distinct(call, "#this", this->name);
            replace_all_distinct(call, "#self", this->name);
            if(!m->isconst && !(m->call.find("(") != string::npos && m->call.find(")") != string::npos)
               && !(m->call.find("[") == 0 && m->call.find("]") == m->call.length() - 1)) {
                return string("[[") + this->name + " alloc] " + call + "]";
            } else {
                return call;
            }
        }
    } else {
        return "[[" + name + " alloc] init]";
    }
}

void OCClassInfo::initByOneLine(std::string &s)
{
    std::vector<string> tokens;
    split(s,tokens, "##");
    std::vector<string> types;
    split(tokens[1], types, "#", 1);
    B_EMethod mt = getEMethodByString(types[0]);
    switch (mt) {
        case B_EMethod::B_Method:
        case B_EMethod::B_Init:
        case B_EMethod::B_Create:
        {
            MethodInfo * method = new MethodInfo();
            method->call = types[1];
            method->methodType = mt;
            if(tokens.size() > 2) {
                std::vector<string> args;
                split(tokens[2], args, ",");
                method->retType = this->name;
                for(auto it = args.begin(); it != args.end(); ++it){
                    if(mt == B_EMethod::B_Method && it == args.begin()) {
                        method->retType = normalizeType(*it);
                    } else {
                        ParamInfo * p = new ParamInfo();
                        p->type = normalizeType(*it);
                        method->params.push_back(p);
                    }
                }
            }
            if(mt == B_EMethod::B_Method)   publicMethods.push_back(method);
            if(mt == B_EMethod::B_Init)     initMethods.push_back(method);
            if(mt == B_EMethod::B_Create)   createMethods.push_back(method);
            vector<string> mflag;
            split(types[0], mflag, "_");
            if(mflag.size() > 1) {
                for(int i = 1; i < mflag.size(); i++) {
                    if(mflag[i] == "const") {
                        method->isconst = true;
                    }
                }
            }
            break;
        }
        case B_EMethod::B_Property:
        {
            PropInfo * prop = new PropInfo();
            prop->name = types[1];
            prop->ret = normalizeType(tokens[2]);
            props.push_back(prop);
            vector<string> mflag;
            split(types[0], mflag, "_");
            if(mflag.size() > 1) {
                for(int i = 1; i < mflag.size(); i++) {
                    if(mflag[i] == "read") {
                        prop->readonly = true;
                    } else if(mflag[i] == "write") {
                        prop->writeonly = true;
                    }
                }
            }
            
            break;
        }
        default:
            break;
    }
    
}

OCClassInfo::~OCClassInfo() {
    for(auto itr = createMethods.begin(); itr != createMethods.end(); itr++) {
        delete (*itr);
    }
    createMethods.clear();
    
    for(auto itr = initMethods.begin(); itr != initMethods.end(); itr++) {
        delete (*itr);
    }
    initMethods.clear();
    
    
    for(auto itr = publicMethods.begin(); itr != publicMethods.end(); itr++) {
        delete (*itr);
    }
    publicMethods.clear();
    
    for(auto itr = customMethods.begin(); itr != customMethods.end(); itr++) {
        delete (*itr);
    }
    customMethods.clear();
    
    for(auto itr = interfaceMethods.begin(); itr != interfaceMethods.end(); itr++) {
        delete (*itr);
    }
    interfaceMethods.clear();
    
    for(auto itr = props.begin(); itr != props.end(); itr++) {
        delete (*itr);
    }
    props.clear();
}

std::string OCClassInfo::execABoolValue(RuntimeContext * context, VarInfo * var)
{
    if(b_type == B_Class && arc4random() % 100 < 20) {
        return var->name;
    }
    int cnt = 0;
    cnt += props.size();
    if(cnt > 0) {
        cnt = arc4random() % cnt;
        if(cnt < props.size()){
            PropInfo* p = props[cnt];
            BaseType * c = context->manager->getType(p->ret);
            string ref = var->name + "." + p->name;
            if(!c) {
                if(context->manager->isNumType(p->ret)) {
                    static vector<string> ops = {">", ">=", "<=", "<", "=="};
                    return ref + ops[arc4random() % ops.size()] + to_string(arc4random() % 100);
                }
                if(p->ret == "bool") {
                    return ref;
                }
                return "true";
            }
            if(c->b_type == B_Class) {
                return ref;
            }
            if(c->b_type == B_Struct) {
                OCClassInfo* struct_C = dynamic_cast<OCClassInfo*>(c);
                if(struct_C->props.size() > 0) {
                    int rid = arc4random() % struct_C->props.size();
                    PropInfo* p2 = struct_C->props[rid];
                    string cacheRef = ref;
                    while(true) {
                        ref = cacheRef + "." + p2->name;
                        if(context->manager->isNumType(p2->ret)) {
                            static vector<string> ops = {">", ">=", "<=", "<", "=="};
                            return ref + ops[arc4random() % ops.size()] + to_string(arc4random() % 100);
                        }
                        if(p2->ret == "bool") {
                            return ref;
                        }
                        rid = (rid + 1) % struct_C->props.size();
                        p2 = struct_C->props[rid];
                    }
                }
            }
            if(c->b_type == B_Enum) {
                return ref + (arc4random() % 2 ? "==" : "!=") + c->genOneInstance(context);
            }
        }
    }
    if(b_type == B_Class) {
        return var->name;
    }
    return "true";
}

void OCClassInfo::objectCall(RuntimeContext * context, VarInfo * var) {
    int cnt = 0;
    cnt += props.size();
    cnt += publicMethods.size();
    cnt += customMethods.size();
    if(cnt > 0) {
        cnt = arc4random() % cnt;
        if(cnt < props.size()){
            PropInfo * p = props[cnt];
            // get or set
            if(p->writeonly || (!p->readonly && arc4random() % 100 < 50)) {
                string str = context->curBlock->selectOrCreateVar(context, p->ret);
                auto line = new Line();
                line->code = var->name + "." + p->name + " = " + str + ";";
                line->order = context->curBlock->genAnOrder();
                context->curBlock->addLine(line);
            } else {
                bool needCreateVar = arc4random() % 100 < 30;
                auto line = new Line();
                if(b_type == B_Struct) needCreateVar = true;
                if(needCreateVar && context->manager->isCanOpType(p->ret)) {
                    VarInfo * innerVar = new VarInfo();
                    innerVar->name = randomAVarName();
                    innerVar->order = context->curBlock->genAnOrder();
                    innerVar->type = p->ret;
                    context->curBlock->addVar(innerVar);
                    line->order = innerVar->order;
                    line->code = context->manager->formatType(p->ret) + innerVar->name + " = " + var->name + "." + p->name + ";";
                } else {
                    line->code = "[" + var->name + " " + p->name + "];";
                    
                    line->order = context->curBlock->genAnOrder();
                }
                context->curBlock->addLine(line);
                
            }
        } else {
            MethodInfo * m = cnt < props.size() + publicMethods.size() ? publicMethods[cnt - props.size()] : customMethods[cnt - props.size() - publicMethods.size()];
            string rc = m->getRealCall(context);
            replace_all_distinct(rc, "#this", var->name);
            replace_all_distinct(rc, "#self", var->name);
            if(!m->isconst && !(m->call.find("(") != string::npos && m->call.find(")") != string::npos)
               && !(m->call.find("[") == 0 && m->call.find("]") == m->call.length() - 1)) {
                rc = string("[") + var->name + " " + rc + "];";
            } else {
                rc = rc + ";";
            }
            bool needCreateVar = arc4random() % 100 < 30;
            auto line = new Line();
            if(needCreateVar && context->manager->isCanOpType(m->retType)) {
                VarInfo * innerVar = new VarInfo();
                innerVar->name = randomAVarName();
                innerVar->order = context->curBlock->genAnOrder();
                innerVar->type = m->retType;
                context->curBlock->addVar(innerVar);
                line->order = innerVar->order;
                line->code = context->manager->formatType(m->retType) + innerVar->name + " = " + rc;
            } else {
                line->code = rc;
                line->order = context->curBlock->genAnOrder();
            }
            context->curBlock->addLine(line);
            
        }
    }
}

}
