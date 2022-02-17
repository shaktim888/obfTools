#include "FileOperation.hpp"
#include "stdlib.h"
#include <sys/stat.h>
#include <vector>
#include <string>
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
#include <ftw.h>
#endif
#include <sys/types.h>
#include <errno.h>
#include <dirent.h>

int FileOperation::fileStatus(const std::string &inName){
    struct stat s;
    const char* path = inName.c_str();
    if(stat(path,&s)==fileStatusNotExist){
        if(s.st_mode & S_IFDIR){
            return fileStatusDirectory;
        }else if (s.st_mode & S_IFREG){
            return fileStatusFile;
        }else{
            return fileStatusElse;
        }
    }else{
        return 0;
    }
}

bool FileOperation::getTextFile(const string &inName, string &text){
    ifstream file(inName);
    const int maxLineLengthOfCmdString = 1024*1024;
    char buf[maxLineLengthOfCmdString];
    if(file.is_open()){
        while(!file.eof()){
            file.getline(buf,sizeof(buf));
            text+=strcat(buf,"\n");
        }
        file.close();
        return true;
    }else{
        file.close();
        return false;
    }
}

bool FileOperation::getBinaryFile(const string &inName, vector<char>& data){
    ifstream file(inName.c_str(),ios::binary);
    if(file.is_open()){
        char headArray[1];
        
        while(file.read(headArray,1)){
            unsigned long readedBytes = file.gcount();
            if(readedBytes>0){
                data.push_back(headArray[0]);
            }
        }
        
        file.close();
        return true;
    }else{
        file.close();
        return false;
    }
}

bool FileOperation::writeTextFile(const string& inName, const string &data){
    ofstream file(inName,ios::out);
    if(file.is_open()){
        file<<data;
        file.close();
        return true;
    }else{
        file.close();
        return false;
    }
}

bool isFormatRight(unsigned char x,const string &format){
    if(format.size()!=8){
        cout<<format<<" ";
        cout<<"你的格式错误"<<endl;
        return false;
    }
    
    vector<int> bits;
    while(x>0){
        bits.push_back(x%2);
        x/=2;
    }
    for(int i = bits.size(); i<8 ; i++) bits.push_back(0);
    
    vector<int> formatBits;
    for(int i = format.size()-1 ; i >=0 ; --i){
        if(format[i]=='x') formatBits.push_back(-1);
        else formatBits.push_back(format[i]-'0');
    }
    
    for(int i = 0 ;i < 8; i++){
        if(bits[i]!=formatBits[i] && formatBits[i]!=-1) return false;
    }
    
    return true;
}

bool FileOperation::isDataUTF8(const vector<unsigned char>& data){
    //UTF8如果带BOM的话，BOM头：0xEF 0xBB 0xBF，符合情况3，不需特殊考虑
    auto len = data.size();
    for(int i = 0 ; i < len ; ++i){
        if(isFormatRight(data[i], "0xxxxxxx")) continue;
        if(isFormatRight(data[i], "110xxxxx") && i+1<len && isFormatRight(data[i+1], "10xxxxxx")){
            ++i;
            continue;
        }
        if(isFormatRight(data[i], "1110xxxx") && i+2<len && isFormatRight(data[i+1], "10xxxxxx") && isFormatRight(data[i+2], "10xxxxxx")){
            i+=2;
            continue;
        }
        if(isFormatRight(data[i], "11110xxx") && i+3<len && isFormatRight(data[i+1], "10xxxxxx") && isFormatRight(data[i+2], "10xxxxxx") && isFormatRight(data[i+3], "10xxxxxx")){
            i+=3;
            continue;
        }
        if(isFormatRight(data[i], "111110xx") && i+4<len && isFormatRight(data[i+1], "10xxxxxx") && isFormatRight(data[i+2], "10xxxxxx") && isFormatRight(data[i+3], "10xxxxxx") && isFormatRight(data[i+4], "10xxxxxx")){
            i+=4;
            continue;
        }
        if(isFormatRight(data[i], "1111110x") && i+5<len && isFormatRight(data[i+1], "10xxxxxx") && isFormatRight(data[i+2], "10xxxxxx") && isFormatRight(data[i+3], "10xxxxxx") && isFormatRight(data[i+4], "10xxxxxx") && isFormatRight(data[i+5], "10xxxxxx")){
            i+=5;
            continue;
        }
        return false;
    }
    return true;
}

bool FileOperation::isDataANSI(const vector<unsigned char>& data){
    auto len = data.size();
    for(int i = 0 ; i < len ;++i){
        if(data[i]<=0x7F) continue;
        if(data[i]>0x7F && i+1<len && data[i+1]>0x7F){
            i++;
            continue;
        }
        return false;
    }
    return true;
}

bool FileOperation::isDataUTF16(const vector<unsigned char>& data, int& encodeMode){
    auto len = data.size();
    if(len<2 || len%2!=0) return false;
    
    if(data[0]==0xFF && data[1]==0xFE){
        encodeMode = utf16_small;
        return true;
    }
    if(data[0]==0xFE && data[1]==0xFF){
        encodeMode = utf16_big;
        return true;
    }
    return false;
}

bool FileOperation::isDataUTF32(const vector<unsigned char>& data, int& encodeMode){
    auto len = data.size();
    if(len<4 || len%4!=0) return false;
    if(data[0]!=0x00 || data[1]!=0x00) return false;
    
    if(data[2]==0xFF && data[3]==0xFE){
        encodeMode = utf32_small;
        return true;
    }
    if(data[2]==0xFE && data[3]==0xFF){
        encodeMode = utf32_big;
        return true;
    }
    return false;
}

bool FileOperation::isFileDamaged(const string &inName, const int mode, int& encodeMode){
    ifstream file(inName.c_str(),ios::binary);
    const int maxHeadLength = 100000;
    char headArray[maxHeadLength];
    vector<vector<int>> head(100);
    
//    if(mode==jpgmode || mode==pngmode){
//        head[jpgmode] = {-1,-40};
//        head[pngmode] = {-119,80,78,71,13,10,26,10};
//        file.read(headArray,sizeof(char)*head[mode].size());
//        file.close();
//
//        for(int i = 0 ; i < head[mode].size(); i++){
//            if(headArray[i]!=head[mode][i]){
//                return true;
//            }
//        }
//        return false;
//    }else
    if(mode==textmode){//智能分析是否为加密后的文本
        ifstream file(inName.c_str(),ios::binary);
        char headArray[1];
        
        vector<unsigned char> data;
        while(file.read(headArray,1)){
            unsigned long readedBytes = file.gcount();
            if(readedBytes>0){
                data.push_back(headArray[0]);
            }
        }
        
        if(isDataUTF8(data)){
            encodeMode = utf8;
            return false;
        }
        if(isDataANSI(data)) {
            encodeMode = ansi;
            return false;
        }
        if(isDataUTF16(data, encodeMode)) return false;
        if(isDataUTF32(data, encodeMode)) return false;
        
        file.close();
        return true;
    }else{
        return false;
    }
}


static bool isDirectoryExistInternal(const std::string& dirPath)
{
    struct stat st;
    if (stat(dirPath.c_str(), &st) == 0)
    {
        return S_ISDIR(st.st_mode);
    }
    return false;
    
}

bool FileOperation::createDirectory(const std::string& path)
{
    if (isDirectoryExistInternal(path))
        return true;

    // Split the path
    size_t start = 0;
    size_t found = path.find_first_of("/\\", start);
    std::string subpath;
    std::vector<std::string> dirs;

    if (found != std::string::npos)
    {
        while (true)
        {
            subpath = path.substr(start, found - start + 1);
            if (!subpath.empty())
                dirs.push_back(subpath);
            start = found+1;
            found = path.find_first_of("/\\", start);
            if (found == std::string::npos)
            {
                if (start < path.length())
                {
                    dirs.push_back(path.substr(start));
                }
                break;
            }
        }
    }

    DIR *dir = NULL;

    // Create path recursively
    subpath = "";
    for (int i = 0; i < dirs.size(); ++i)
    {
        subpath += dirs[i];
        dir = opendir(subpath.c_str());

        if (!dir)
        {
            // directory doesn't exist, should create a new one

            int ret = mkdir(subpath.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
            if (ret != 0 && (errno != EEXIST))
            {
                // current directory can not be created, sub directories can not be created too
                // should return
                return false;
            }
        }
        else
        {
            // directory exists, should close opened dir
            closedir(dir);
        }
    }
    return true;
}

