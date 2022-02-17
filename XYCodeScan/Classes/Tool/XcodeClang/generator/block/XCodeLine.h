//
//  XCodeLine.h
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XCodeLine_h
#define XCodeLine_h
#include "XLine.h"
namespace hygen
{

class CodeLine : public Line
{
public:
    CodeLine() : noLn(false)
    {}
    std::string code;
    bool noLn;
};

}
#endif /* XCodeLine_h */
