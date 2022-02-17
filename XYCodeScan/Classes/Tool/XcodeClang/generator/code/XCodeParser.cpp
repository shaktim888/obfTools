//
//  XCodeParser.cpp
//  HYCodeScan
//
//  Created by admin on 2020/8/10.
//

#include "XCodeParser.hpp"
#include <regex>
#include "XCommanFunc.hpp"
using namespace std;

using namespace hygen;

bool CodeParser::parser() {
#ifdef __PARSER_DEBUG__
    printf("parser: %p\n", this);
#endif
    static std::regex reg("(\\$\\{([^\\{\\}]+)\\})");
    string::const_iterator start = code.begin() + pos;
    string::const_iterator end = code.end();
    
    std::smatch m;
    while (std::regex_search(start, end, m, reg))
    {
        collectCode += code.substr(pos, m[0].first - start);
        pos = pos + (m[0].second - start);
        start = m[0].second;
        std::string inner = m[2];
        if(inner.find(",")!= std::string::npos) {
            std::vector<std::string> items;
            split(inner, items, ",");
            std::string& str = items[arc4random() % items.size()];
            collectCode += str;
        } else {
            trim(inner);
#ifdef __PARSER_DEBUG__
            printf("token: %p, %s\n", this, inner.c_str());
#endif
            if(delegate->onToken(this, inner, collectCode)) {
#ifdef __PARSER_DEBUG__
                printf("break: %p, %s\n", this, inner.c_str());
#endif
                return true;
            }
        }
    }
    if(pos < code.length()) {
        collectCode += code.substr(pos, end - start);
        pos = pos + (end - start);
    }
    delegate->onParseFinish(this, collectCode);
    return false;
}

