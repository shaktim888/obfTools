//
//  GCommanFunc.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#include "GCommanFunc.hpp"
#include "HYGenerateNameTool.h"
#import "UserConfig.h"

namespace ocgen {

static int toupper(int __c) {
    return ((__c) & ~32);
}
static int tolower(int __c) {
    return ((__c) | 32);
}
std::string string_tolower(string str){
    transform(str.begin(), str.end(), str.begin(), tolower);
    return str;
}

std::string string_toupper(string str){
    transform(str.begin(), str.end(), str.begin(), toupper);
    return str;
}

std::string normalizeType(std::string t) {
    string s = string_tolower(t);
    static vector<std::string> baseTypes = {
        "int", "float", "bool"
    };
    for(auto itr = baseTypes.begin(); itr != baseTypes.end(); itr++) {
        if(s.find(*itr) == 0) {
            t = s;
            return t;
        }
    }
    return t;
}


string& replace_all_distinct(string& str, const string& old_value, const string& new_value)
{
    for(string::size_type pos(0);pos!=string::npos;pos+=new_value.length())
    {
        if((pos=str.find(old_value,pos)) != string::npos)
        {
            str.replace(pos,old_value.length(),new_value);
        }
        else { break; }
    }
    return str;
}
void split(const string& s, vector<string>& tokens, const string& delimiters, const int splitCnt)
{
    int cnt = 0;
    string::size_type lastPos = 0;
    string::size_type pos = s.find(delimiters, lastPos);
    while (lastPos < s.length()) {
        if(splitCnt > 0 && cnt == splitCnt) {
            pos = s.length();
        }
        tokens.push_back(s.substr(lastPos, pos - lastPos));//use emplace_back after C++11
        lastPos = pos + delimiters.length();
        pos = s.find(delimiters, lastPos);
        if(pos == string::npos) pos = s.length();
        cnt++;
    }
}
std::string randomAVarName() {
    return [[HYGenerateNameTool generateByName:VarName from:nil cache:false] UTF8String];
}

std::string genRandomString(bool isFileName) {
    string ret;
    if(isFileName)
    {
        ret += [[HYGenerateNameTool generateByName:ResName from:nil cache:false] UTF8String];
        ret += (arc4random() % 2 ? ".png" : ".jpg");
    }
    else
    {
        int wordMin = MIN([UserConfig sharedInstance].stringWordMin, [UserConfig sharedInstance].stringWordMax);
        int wordMax = MAX([UserConfig sharedInstance].stringWordMin, [UserConfig sharedInstance].stringWordMax);
        int wordNum = wordMin;
        if(wordMax != wordMin) {
            wordNum += arc4random() % (wordMax - wordMin);
        }
        
        int k = 0;
        for(int i = 0; i < wordNum; i++) {
            ret += [[HYGenerateNameTool generateByName:WordName from:nil cache:false] UTF8String];
            k++;
            if( i < wordNum - 1) {
                if(k >= 3 && arc4random() % 100 <= k * 12) {
                    ret += ",";
                    k = 0;
                }
                ret += " ";
            }
        }
    }
    return ret;
}

void splitWord(const string& s, vector<string> & words) {
    std::smatch m;
    std::regex reg("_?(([A-Z]+)[A-Z][a-z0-9])|([A-Za-z0-9][a-z0-9]+)|([A-Z][A-Z]+)");
    string::const_iterator start = s.begin();
    string::const_iterator end = s.end();
    while (std::regex_search(start, end, m, reg))
    {
        if(m[2]!="") {
            words.push_back(m[2]);
            start = m[2].second;
        } else if(m[3] != "") {
            words.push_back(m[3]);
            start = m[3].second;
        } else if(m[4] != "") {
            words.push_back(m[4]);
            start = m[4].second;
        }
    }
}

}
