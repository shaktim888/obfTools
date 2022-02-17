//
//  BaseType.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "GBaseType.hpp"

#include "GRuntimeContext.hpp"
#include "GCommanFunc.hpp"
#include "GBlock.hpp"

namespace ocgen {
using namespace std;

B_Type getBTypeByString(std::string & type) {
   if(type == "struct") {
       return B_Type::B_Struct;
   }
   if(type == "class") {
       return B_Type::B_Class;
   }
   if(type == "enum") {
       return B_Type::B_Enum;
   }
   return B_Type::B_NONE;
}
void BaseType::addDep(RuntimeContext * context, std::string clsName) {
    replace_all_distinct(clsName, "*", "");
    replace_all_distinct(clsName, " ", "");
    BaseType * c = context->manager->getType(clsName);
    if(c) {
        if(c->libName != "") {
            std::string libPath = "<" + c->libName + "/"+ c->libName + ".h>";
            if(!addedLib[libPath]) {
                auto line = new Line();
                line->code = "#import " + libPath;
                line->order = IMPORT_ORDER;
                context->rootBlock->addLine(line, false, true);
                addedLib[libPath] = true;
            }
        } else {
            if(!addedLib[c->name]) {
                std::string libPath = "\"" + c->name + ".h\"";
                auto line = new Line();
                line->code = "#import " + libPath;
                line->order = IMPORT_ORDER;
                context->rootBlock->addLine(line, false, true);
                addedLib[c->name] = true;
            }
        }
    }
}

void BaseType::removeDep(RuntimeContext * context, std::string clsName) {
    BaseType * c = context->manager->getType(clsName);
    if(c) {
        std::string libPath;
        if(c->libName != "") {
            libPath = "<" + c->libName + "/"+ c->libName + ".h>";
        } else {
            libPath = "\"" + c->name + ".h\"";
        }
        addedLib.erase(libPath);
    }
}




}
