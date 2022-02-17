#include <string>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include "mmd5.h"
#include "exec_cmd.h"
#include "NameGeneratorExtern.h"
#include "FileOperation.hpp"
#include "pngTools.hpp"
#include "jpegTools.hpp"

using namespace std;

static int switchMode(const string &inName,const vector<string>& bannedFileType){
    unsigned long _lastDotLocation = inName.size();
    for(int i = 0;i<inName.size();++i){
        if(inName[i]=='.'){
            _lastDotLocation = i;
        }
    }
    if(_lastDotLocation==inName.size()) return othermode;//无后缀文件
    
    string suffixString = inName.substr(_lastDotLocation+1,inName.size());
    int mode = othermode;
    if(suffixString=="jpg") mode = jpgmode;
    else if(suffixString=="jpeg") mode = jpgmode;
    else if(suffixString=="png") mode = pngmode;
    else if(suffixString=="mp3") mode = mp3mode;
    else if(suffixString=="json") mode = jsonmode;
    else if(suffixString=="mp4") mode = mp4mode;
    else if(suffixString=="json") mode = textmode;
    else if(suffixString=="xml") mode = textmode;
    else if(suffixString=="js") mode = textmode;
    else if(suffixString=="css") mode = textmode;
    else if(suffixString=="htm") mode = textmode;
    else if(suffixString=="html") mode = textmode;
    else if(suffixString=="lua") mode = textmode;
//    else if(suffixString=="txt") mode = textmode; // 这里还是先不mmd5 这种格式不确定解析方式
    else if(suffixString=="plist") mode = textmode;
    else if(suffixString=="csb") mode = binmode;
    
    for(auto i = 0; i < bannedFileType.size() ; ++i){
        if(suffixString==bannedFileType[i]){
            mode = othermode;
            break;
        }
    }
    
    return mode;
}

static void mmd5jpg(const string &inName, string &logfile){
    JpegParse p(inName.c_str());
    p.random_add_color();
    p.write_jpeg_file((inName).c_str());
}

static void mmd5png(const string &inName, string &logfile){
    PngParse p(inName.c_str());
    p.random_add_color();
    p.write_png_file(inName.c_str());
}


static void mmd5bin(const string &inName, string &logfile) {
    NSString *UUID = [[NSUUID UUID] UUIDString];
    ofstream file(inName.c_str(),ios::app);
    file<<[UUID UTF8String];
    file.close();
}

static void mmd5mp4(const string &inName, string &logfile){
    NSString *UUID = [[NSUUID UUID] UUIDString];
    ofstream file(inName.c_str(),ios::app);
    file<<[UUID UTF8String];
    file.close();
}

NSString * randomSpace(int min, int max, NSString* f)
{
    NSMutableString * ret = NSMutableString.string;
    int m = (arc4random() % (max - min)) + min ;
    while(m > 0) {
        [ret appendString:@" "];
        m--;
    }
    [ret appendString:f];
    m = (arc4random() % (max - min)) + min ;
    while(m > 0) {
        [ret appendString:@" "];
        m--;
    }
    return ret;
}

static void mmd5json(const string &inName, string &logfile){
    NSString * file = [NSString stringWithUTF8String:inName.c_str()];
    file = [file stringByStandardizingPath];
    NSData *data = [[NSData alloc] initWithContentsOfFile:file];
    
    NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if(json) {
        NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *pattern = @"\\{|\\}|\\]|\\[|:";
        NSRegularExpression *regex3 = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray<NSTextCheckingResult *> *results3 = [regex3 matchesInString: str options:NSMatchingReportProgress range:NSMakeRange(0,  str.length)];
        NSMutableArray * arr = [[NSMutableArray alloc] init];
        for(int i = 0; i < results3.count; i++) {
            [arr addObject:[NSValue valueWithRange:[results3 objectAtIndex: i].range]];
        }
        NSArray *sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSRange first = [a rangeValue];
            NSRange second = [a rangeValue];
            if(first.location > second.location) {
                return NSOrderedAscending;
            }
            if(first.location == second.location){
                return NSOrderedSame;
            }
            return NSOrderedDescending;
        }];
        int cnt = 0;
        for(int i = sortedArray.count - 1; i >= 0; i--) {
            cnt++;
            NSRange res = [[sortedArray objectAtIndex: i] rangeValue];
            str = [str stringByReplacingCharactersInRange:res withString: randomSpace(0, 3, [str substringWithRange:res])];
            if(cnt >= 20) {
                break;
            }
        }
        [str writeToFile:file atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
}

static void mmd5mp3(const string &inName, string &logfile){
    ifstream file(inName.c_str(),ios::binary);
    char headArray[1];
    
    vector<char> fileData;
    while(file.read(headArray,1)){
        unsigned long readedBytes = file.gcount();
        if(readedBytes>0)
            fileData.push_back(headArray[0]);
    }

    file.close();
    
    if(fileData.size()>8){
        fileData[6] = rand()%255;
        fileData[7] = rand()%255;
    }
    
    ofstream ofile(inName.c_str());
    if(ofile){
        for(int i = 0 ; i < fileData.size() ; ++i){
            ofile<<fileData[i];
        }
    }
    ofile.close();
    
    logfile.append(inName+"\n");
}

static void mmd5text(const string &inName, string &logfile, const int encodeMode){
//    string endString = "";
//    endString.push_back(0x20);
//    endString.push_back(0x00);
//    int _emptyNum = rand()%100;
//    for (int i = 0 ; i <_emptyNum;++i) {
//        if(encodeMode==utf8 || encodeMode==ansi) endString.push_back(0x20);
//        else if(encodeMode==utf16_small){
//            endString.push_back(0x20);
//            endString.push_back(0x00);
//        }else if(encodeMode==utf16_big){
//            endString.push_back(0x00);
//            endString.push_back(0x20);
//        }else if(encodeMode==utf32_small){
//            endString.push_back(0x00);
//            endString.push_back(0x00);
//            endString.push_back(0x20);
//            endString.push_back(0x00);
//        }else if(encodeMode==utf32_big){
//            endString.push_back(0x00);
//            endString.push_back(0x00);
//            endString.push_back(0x00);
//            endString.push_back(0x20);
//        }
//    }
    ofstream file(inName.c_str(),ios::app);
    file.write(" ", sizeof(char)*1);
    file.flush();
    file.close();
    logfile.append(inName+" "+to_string(encodeMode)+"\n");
}

static void _mmd5(const string &inName, string &logfile,const vector<string>&bannedFileType){
    Timer_start("mmd5");
    int mode = switchMode(inName,bannedFileType);
    if(mode==othermode) return;
    
    int encodeMode = utf8;
    if(FileOperation::isFileDamaged(inName, mode, encodeMode)){
        cout<<inName<<"错误的文件格式"<<endl;
        Timer_end("mmd5");
        return;
    }
    switch (mode){
        case jpgmode:
            mmd5jpg(inName, logfile);
            break;
        case pngmode:
            mmd5png(inName, logfile);
            break;
        case mp3mode:
            mmd5mp3(inName, logfile);
            break;
        case mp4mode:
            mmd5mp4(inName, logfile);
            break;
        case textmode:{
            mmd5text(inName, logfile, encodeMode);
            break;
        }
        case jsonmode:{
            mmd5json(inName, logfile);
            break;
        }
        case binmode: {
            mmd5bin(inName, logfile);
            break;
        }
        default:
            break;
    }
    Timer_end("mmd5");
}

@implementation mmd5

+(void) mmd5File :(NSString *) inFile outDir: (NSString *) outFile
{
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    if(![inFile isEqualToString:outFile]){
        [myFileManager removeItemAtPath:outFile error:NULL];
        [myFileManager copyItemAtPath:inFile toPath:outFile error:nil];
    }
    vector<string> bannedFileType;
    string logString = "";
    _mmd5([outFile UTF8String], logString, bannedFileType);
}

+(void) genAPngPic: (NSString*) inName
{
    PngParse::gemARandomPicture([inName UTF8String]);
}

+(void) genAJpgPic: (NSString*) inName
{
    JpegParse::genAPicture([inName UTF8String]);
}

+(void) mmd5Dir : (NSString *) basePath outDir: (NSString *) outDir
{
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    vector<string> bannedFileType;
    bannedFileType.push_back("png");
    bannedFileType.push_back("jpg");
    bannedFileType.push_back("jpeg");
    NSDirectoryEnumerator *myDirectoryEnumerator = [myFileManager enumeratorAtPath:basePath];
    BOOL isDir = NO;
    BOOL isExist = NO;
    
    string logString = "已修改文件列表:\n";
    NSArray * arr = myDirectoryEnumerator.allObjects;
    for (NSString *path in arr) {
        NSString * inFile = [NSString stringWithFormat:@"%@/%@", basePath, path];
        NSString * outFile = [NSString stringWithFormat:@"%@/%@", outDir, path];
        inFile = [inFile stringByStandardizingPath];
        outFile = [outFile stringByStandardizingPath];
        isExist = [myFileManager fileExistsAtPath:inFile isDirectory:&isDir];
        if (!isDir) {
            if([[outFile lastPathComponent] isEqualToString:@".DS_Store"]) {
                [myFileManager removeItemAtPath:outFile error:NULL];
                continue;
            }
            if(![inFile isEqualToString:outFile]){
                [myFileManager removeItemAtPath:outFile error:NULL];
                [myFileManager copyItemAtPath:inFile toPath:outFile error:nil];
            }
            _mmd5([outFile UTF8String], logString, bannedFileType);
        }
    }
    std::cout<<logString<<std::endl;
}
@end
