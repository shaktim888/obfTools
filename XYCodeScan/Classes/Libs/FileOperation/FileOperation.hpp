#ifndef file_operation_hpp
#define file_operation_hpp

#include <stdio.h>
#include <string>
#include <sys/stat.h>
#include <fstream>
#include <iostream>
#include <vector>
using namespace std;

enum fileMode{
    jpgmode=1,pngmode,mp3mode,mp4mode,textmode,binmode,jsonmode,othermode
};

enum encodeMode{
    utf8=1,utf16_small,utf16_big,utf32_small,utf32_big,ansi
};

enum fileStatus{
    fileStatusElse=-1,fileStatusNotExist=0,fileStatusFile,fileStatusDirectory
};

class FileOperation{
public:
    static int fileStatus(const std::string &inName);
    static bool getTextFile(const string &inName, string&);
    static bool getBinaryFile(const string &inName, vector<char>&);
    static bool writeTextFile(const string&,const string&);
    static bool isFileDamaged(const string &inName, const int mode, int& encodeMode);
    static bool isDataUTF8(const vector<unsigned char>& data);
    static bool isDataANSI(const vector<unsigned char>& data);
    static bool isDataUTF16(const vector<unsigned char>& data, int& encodeMode);
    static bool isDataUTF32(const vector<unsigned char>& data, int& encodeMode);
    static bool createDirectory(const std::string& path);
};

#endif /* file_operation_hpp */
