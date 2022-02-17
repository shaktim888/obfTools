//
//  GLine.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GLine_hpp
#define GLine_hpp

#include <stdio.h>
#include <string>

namespace ocgen {

typedef struct Line
{
    int order;
    std::string code;
    bool no_offset;
} Line;

}

#endif /* GLine_hpp */
