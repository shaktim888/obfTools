//
//  EnumInfo.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/3.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef GEnumInfo_hpp
#define GEnumInfo_hpp

#include "GBaseType.hpp"

namespace ocgen {

using namespace std;

class EnumInfo : public BaseType
{
    std::vector<string> items;
    void initByOneLine(std::string &s) override;
    
    std::string execABoolValue(RuntimeContext * context, VarInfo * var) override;
    std::string genOneInstance(RuntimeContext * context) override;
    void objectCall(RuntimeContext * context, VarInfo * b) override;
};
}

#endif /* EnumInfo_hpp */
