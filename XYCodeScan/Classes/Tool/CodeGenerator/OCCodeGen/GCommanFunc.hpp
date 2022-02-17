//
//  GCommanFunc.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef GCommanFunc_hpp
#define GCommanFunc_hpp

#include <stdio.h>
#include <string>
#include <vector>
#include <regex>
#include <algorithm>
#include <iostream>
#include <fstream>

namespace ocgen {

using namespace std;

std::string string_tolower(string str);
std::string string_toupper(string str);
std::string normalizeType(std::string t);

std::string randomAVarName();
std::string genRandomString(bool isFileName);

string& replace_all_distinct(string& str, const string& old_value, const string& new_value);
void split(const string& s, vector<string>& tokens, const string& delimiters = " ", const int splitCnt = 0);
void splitWord(const string& s, vector<string> & words);

}

#endif /* GCommanFunc_hpp */
