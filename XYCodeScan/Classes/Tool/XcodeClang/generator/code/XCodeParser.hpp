//
//  XCodeParser.hpp
//  HYCodeScan
//
//  Created by admin on 2020/8/10.
//

#ifndef XCodeParser_hpp
#define XCodeParser_hpp

#include <stdio.h>
#include <vector>
#include <string>
#include <map>
//#define __PARSER_DEBUG__

namespace hygen {

class CodeParser;
class CodeParserDelegate {
public:
    virtual bool onToken(CodeParser * parser, const std::string& token, std::string & code) = 0;
    virtual void onParseFinish(CodeParser * parser,std::string & code) = 0;
};

class CodeParser {
    std::string code;
    std::string collectCode;
    int pos;
    CodeParserDelegate * delegate;
public:
    CodeParser * parent;
    std::map<std::string, std::string> varCache;
    int recordLines;
    CodeParser(CodeParserDelegate * d, std::string _code, CodeParser * _p) : delegate(d),code(_code), recordLines(0),pos(0), parent(_p)
    {}
    ~CodeParser(){}
    bool parser();
};

}

#endif /* XCodeParser_hpp */
