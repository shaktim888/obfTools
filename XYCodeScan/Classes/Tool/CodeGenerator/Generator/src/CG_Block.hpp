//
//  CG_Block.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/14.
//

#ifndef CG_Block_hpp
#define CG_Block_hpp

#include <stdio.h>
#include <string>
using namespace std;

namespace gen {

struct HYCodeBlock
{
    HYCodeBlock() : needRevert(false) {}
    std::string beforeStart;
    std::string start;
    std::string beforeBody;
    std::string body;
    std::string afterBody;
    std::string end;
    bool needRevert;
};

}
#endif /* CG_Block_hpp */
