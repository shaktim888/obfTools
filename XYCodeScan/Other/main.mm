//
//  main.m
//  HYCodeObfuscation
//
//  Created by HY admin on 2019/8/16.
//  Copyright © 2019年 HY admin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <getopt.h>
#import "HYDefineRenameTool.h"
#import "HYObfuscationTool.h"
#import "HYGenerateNameTool.h"
#import "rcg.h"
#import "ProjectObf.h"
#import "ImageObf.h"
#import "ImageTools.h"
#import "LuaCodeObf.h"
#import "ListenceVerify.h"
#import "UserConfig.h"
#import "StringObf.h"
#import "FileLogger.h"
#import "mmd5.h"
#import "CodeGenerator.h"
#import "GenLibTools.h"
#import "LuaCall.hpp"
#import "myLuaParser.h"
#import "LuaObf.h"
#import "xxteaTools.h"
#import "ZipLoader.h"
#import "ZipEncrypt.h"
#import "ClangXcode.h"

void print_usage(void)
{
    fprintf(stderr,
            "HYCodeScan %s\n"
            "Usage: HYCodeScan [options]\n"
            "\n"
            "  where options are:\n"
            "        -h, --help                 show help\n"
            "        --redefine                 set to reDefine .h file mode\n"
            "        --xcode                    set to obfuscation xcodeproject mode\n"
            "        --rcg                      set to generate code mode\n"
            "        --scan                     set to scan code mode\n"
            "        --image                    set to image encode mode\n"
            "        --salt                     set to image salt sound mode\n"
            "        --xxtea                    set to xxtea decode mode\n"
            "        --lua                      set to run lua code\n"
            "        --luaobf                   obf lua code mode\n"
            "        --mmd5                     modify file md5 value\n"
            "        --luacompress              set lua compress mode\n"
            "        --encrypt                  encrypt folder\n"
            "        --decrypt                  decrypt folder\n"
            "---------------------------------------------------------\n"
            "        --nobackup                 not backup\n"
            "        -o <path>,--output <path>  path to file where obfuscated symbols are written\n"
            "        -i <path>,--input  <path>  input need obfuscated file or folder or image\n"
            "        -f <word>,--filter <word>  add filter word\n"
            "        -t <target>,--target <target> set xcodeProj target\n"
            "        -p <xcodeproj>,--project <xcodeproj> set xcodeProj path\n"
            "        -P <num>,--prob <num>      set code obfuscation probability\n"
            "        -j <file>,--json <file>    set json file\n"
            "        -d, --decode               decode image mode\n"
            "        -a, --args                 set run arguments\n"
            "        -k, --key                  set xxtea key\n"
            "        -s, --sign                 set xxtea sign\n"
            "        -w, --wait                 run lua is need wait?\n"
            "        -g <file>, --ignore <file> set ignore file\n"
            "        --config                   custom set config file\n"
            "        -e                         ignore remain arguments and run\n"
            ,
            "1.1"
            );
}

#define CD_OPT_redefine        1
#define CD_OPT_xcode           2
#define CD_OPT_rcg             3
#define CD_OPT_scan            4
#define CD_OPT_image           5
#define CD_OPT_salt            6
#define CD_OPT_xxtea           7
#define CD_OPT_lua             8
#define CD_OPT_lua_obf         9
#define CD_OPT_config          10
#define CD_OPT_nobackup        11
#define CD_OPT_lua_compress    12
#define CD_OPT_mmd5            13
#define CD_OPT_zip             14
#define CD_OPT_unzip           15


void HandleException(NSException *exception)
{
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString
                               stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
                               NSLog(@"%@", exceptionInfo);

}

void InstallUncaughtExceptionHandler(void)
{
    NSSetUncaughtExceptionHandler(&HandleException);
}

int main(int argc, const char * argv[]) {
//    [UserConfig sharedInstance].xcodePath = @"/Users/admin/Downloads/TUMOBI/TUMOBI.xcodeproj";
//    [[ClangXcode sharedInstance] obfWithXcode];
//
//    return 0;
//    genClassToFolder(Gen_OC, 10, "/Users/admin/Desktop/xxxx");
//
//    return 0;
//    parserLua("/Users/admin/Documents/test/aa/game.lua","/Users/admin/Documents/test/aa/game2.lua");
//    return 0;
//    [LuaObf compressLuaFile:@"/Users/admin/Documents/admin/ocpatch/LSC/Sample/iOS_OSX/LuaScript/src"];

//    [ImageTools pngquant:5 file:@"/Users/admin/Desktop/20_3/aaa.png"];
//        [mmd5 mmd5File:@"/Users/admin/Documents/test/timg.jpeg" outDir:@"/Users/admin/Documents/test/timg22.jpeg"];
//        return 1;
//    [HYGenerateNameTool generateName:ArgName from:@"x" typeName:nil cache:false globalClassPrefix:nil];
//    [HYGenerateNameTool resolveWord:@"/Users/admin/Documents/admin/obfuscatorTools/CodeScan/HYCodeScan/File/NameTemplate/cet4.list"];
//    genOneFile(100, "/Users/admin/Desktop/vv/test");
//    compileFolder("/Users/admin/Desktop/vv/test", "/Users/hqq/Desktop/vv/test2");
//    genClassToFolder(Gen_Cplus, 10, "/Users/admin/Desktop/vv/test");
//    genClassMemberMethod(Gen_Method_Cplus_Static, "NoClass");
//    [UserConfig sharedInstance].addMethodNum = 1;
//    [CodeGenerator rcg:@"/Users/admin/Documents/test/cc.cpp" output:@"/Users/admin/Documents/test/cc1.cpp" prop:100];
//    return 1;
//    [CodeGenerator insertCode:@"/Users/admin/Desktop/vv/MHomeController.m" output:@"/Users/hqq/Desktop/vv/MHomeController.m" import:@"#import aaaa\n" code:@"\naaaa();\n"];
    
//    genClassMemberMethod(Gen_Method_C, "NoClass");
//    genOneMethod(Gen_Method_C, "xyz");
//    [mmd5 mmd5File:@"/Users/admin/Desktop/vv/Contents.json" outDir:@"/Users/admin/Desktop/vv/Contents.json"];
//    [CodeGenerator rcg:@"/Users/admin/Desktop/vv/dplus.c" output:@"/Users/admin/Desktop/vv/dplus.c" prop:100];
//    Timer_start("test");
//    disableWhite();
//    Timer_end("test");
//    Timer_summary();
//    return 0;
//    [ImageTools addNoice:@"/Users/hqq/Desktop/vv/什么.png" outfile:@"/Users/hqq/Desktop/vv/什么2.png"];
    
//    [LuaCodeObf generateLuaFile:@"/Users/hqq/Desktop/aa" num:1];
//    [StringObf buildWithFuncName:@"fsdf" cfuncName:@"dsdfsCC"];
//    [StringObf ObfCPtr:@"zipArchiveDidUnzipArchiveAtPath"];
//    return 0;
    
//    compressToZip("/Users/admin/Downloads/MNFloatBtn-master", "/Users/admin/Downloads/dddd.file");
//    loadZipFile("/Users/admin/Downloads/dddd.file" , "/Users/admin/Downloads/vvas");
//    return 0;
//
//
//    [mmd5 genAJpgPic:@"/Users/admin/Downloads/xxxxx.jpg"];
//    [mmd5 genAPngPic:@"/Users/admin/Downloads/xxxxx.png"];
//    return 1;

//    InstallUncaughtExceptionHandler();
//    if(![listence verify]) {
//        NSLog(@"请先注册以上的注册码。");
//        return 0;
//    }
    int mode = 0;
    @autoreleasepool {
        int ch;
        int prop = -1;
        NSString* outFile;
        NSString* xcodeProj;
        NSString* jsonFile;
        NSString* ignoreFile;
        NSString* args;
        NSString* key;
        NSString* sign;
        LuaCall * luaCall;
        bool isNobackup = false;
        bool isDecode = false;
        bool isWait = false;
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSMutableArray* prefixes = [[NSMutableArray alloc] init];
        NSMutableArray* targets = [[NSMutableArray alloc] init];
        struct option longopts[] = {
            { "help",                    no_argument,       NULL, 'h' },
            { "redefine",                no_argument,       NULL, CD_OPT_redefine },
            { "xcode",                   no_argument,       NULL, CD_OPT_xcode },
            { "rcg",                     no_argument,       NULL, CD_OPT_rcg },
            { "scan",                    no_argument,       NULL, CD_OPT_scan },
            { "image",                   no_argument,       NULL, CD_OPT_image },
            { "salt",                    no_argument,       NULL, CD_OPT_salt },
            { "xxtea",                   no_argument,       NULL, CD_OPT_xxtea },
            { "lua",                     no_argument,       NULL, CD_OPT_lua },
            { "luaobf",                  no_argument,       NULL, CD_OPT_lua_obf },
            { "luacompress",             no_argument,       NULL, CD_OPT_lua_compress },
            { "mmd5",                    no_argument,       NULL, CD_OPT_mmd5 },
            { "encrypt",                 no_argument,       NULL, CD_OPT_zip },
            { "decrypt",                 no_argument,       NULL, CD_OPT_unzip },
            //---------------------------------
            { "nobackup",                no_argument,       NULL, CD_OPT_nobackup },
            { "output",                  required_argument, NULL, 'o' },
            { "input",                   required_argument, NULL, 'i' },
            { "filter",                  required_argument, NULL, 'f' },
            { "prop",                    required_argument, NULL, 'P' },
            { "target",                  required_argument, NULL, 't' },
            { "project",                 required_argument, NULL, 'p' },
            { "key",                     required_argument, NULL, 'k' },
            { "sign",                    required_argument, NULL, 's' },
            { "wait",                    no_argument,       NULL, 'w' },
            { "args",                    required_argument, NULL, 'a' },
            { "json",                    required_argument, NULL, 'j' },
            { "decode",                  no_argument,       NULL, 'd' },
            { "config",                  required_argument, NULL, CD_OPT_config },
            { "ignore",                  required_argument, NULL, 'g' },
            { "end",                     required_argument, NULL, 'e' },
            { NULL,                      0,                 NULL, 0 },
        };
        while ( (ch = getopt_long(argc, (char * const *)argv, "hewo:i:f:t:a:p:P:g:j:k:s:", longopts, NULL)) != -1) {
            //            NSLog(@"%c", ch);
            switch (ch) {
                case 'h':
                    print_usage();
                    return 1;
                    break;
                case CD_OPT_redefine:
                case CD_OPT_xcode:
                case CD_OPT_rcg:
                case CD_OPT_scan:
                case CD_OPT_image:
                case CD_OPT_salt:
                case CD_OPT_xxtea:
                case CD_OPT_lua:
                case CD_OPT_lua_obf:
                case CD_OPT_lua_compress:
                case CD_OPT_mmd5:
                case CD_OPT_zip:
                case CD_OPT_unzip:
                    mode = ch;
                    break;
                    //----------------------------------------------------
                case CD_OPT_nobackup:
                    isNobackup = true;
                    break;
                case 'o':
                    outFile = [NSString stringWithUTF8String:optarg];
                    break;
                case 'i':
                    [array addObject:[NSString stringWithUTF8String:optarg]];
                    break;
                case 'f':
                    [prefixes addObject:[NSString stringWithUTF8String:optarg]];
                    break;
                case 'w':
                    isWait = true;
                    break;
                case 't':
                    [targets addObject:[NSString stringWithUTF8String:optarg]];
                    break;
                case 'a':
                    args = [NSString stringWithUTF8String:optarg];
                    break;
                case 'k':
                    key = [NSString stringWithUTF8String:optarg];
                    break;
                case 's':
                    sign = [NSString stringWithUTF8String:optarg];
                    break;
                case 'p':
                    xcodeProj = [NSString stringWithUTF8String:optarg];
                    [UserConfig sharedInstance].xcodePath = xcodeProj;
                    break;
                case 'P':
                    prop = atoi(optarg);
                    break;
                case 'g':
                    ignoreFile = [NSString stringWithUTF8String:optarg];
                    break;
                case 'j':
                    jsonFile = [NSString stringWithUTF8String:optarg];
                    break;
                case 'd':
                    isDecode = true;
                    break;
                case CD_OPT_config:
                    [[UserConfig sharedInstance] loadFromJson:[NSString stringWithUTF8String:optarg]];
                    break;
                case 'e':
                    goto start;
                default:
                    // 出现错误的时候。直接走可视化界面
                    [FileLogger loggerEnabled:[UserConfig sharedInstance].saveLog];
                    return NSApplicationMain(argc, argv);
            }
        }
    start:
        if(isNobackup) {
            [UserConfig sharedInstance].backup = false;
        }
        if(ignoreFile) {
            [UserConfig sharedInstance].customIgnoreFile = ignoreFile;
        }
        if(mode == CD_OPT_redefine) {
            [HYDefineRenameTool renameHeadFile:array callback:^(NSString* name) {
                if(!name) {
                    NSLog(@"reDefine Finished!");
                }
            }];
        } else if(mode == CD_OPT_lua_obf) {
            [UserConfig sharedInstance].isMinifyLua = false;
            [UserConfig sharedInstance].isUglifyLua = false;
            [UserConfig sharedInstance].insertLuaCocos = true;
            for(NSString * file in array)
            {
                [LuaObf obf:file outfile:file];
            }
        } else if(mode == CD_OPT_scan) {
            [HYObfuscationTool reset];
            [HYObfuscationTool obfuscateAtDir:array
                                     prefixes:prefixes];
            
            [HYObfuscationTool write:[array firstObject]];
            NSLog(@"Scan Finished!");
        } else if(mode == CD_OPT_rcg)
        {
            for(NSString * file in array)
            {
                [CodeGenerator rcg:file output:file prop:prop];
            }
        } else if(CD_OPT_xxtea == mode)
        {
            if(isDecode) {
                [xxteaTools decodeFile:[array firstObject] output:outFile key:key sign:sign];
            } else {
                [xxteaTools encodeFile:[array firstObject] output:outFile key:key sign:sign];
            }
        } else if(mode == CD_OPT_xcode)
        {
            [ProjectObf obf];
            return 0;
        } else if(mode == CD_OPT_image)
        {
            if(isDecode)
            {
                NSLog(@"%@", [ImageObf decodeImg:[array firstObject]]);
            } else {
                [ImageObf encodeImg:jsonFile img:[array firstObject]];
            }
            return 0;
        } else if(mode == CD_OPT_salt)
        {
            for(NSString * file in array)
            {
                [ImageTools addNoice:file outfile:outFile];
            }
            return 0;
        } else if(mode == CD_OPT_lua)
        {
            luaCall = new LuaCall();
            luaCall->setArgs([args UTF8String]);
            NSString * infile = [array firstObject];
            if(![infile hasPrefix:@"/"]) {
                infile = [[NSBundle mainBundle] pathForResource:infile ofType:nil];
            }
            NSLog(@"执行脚本 Lua:%@ args:%@",infile , args);
            if(infile) {
                luaCall->executeFile([infile UTF8String], isWait);
            }
            delete luaCall;
            return 0;
        } else if(mode == CD_OPT_lua_compress)
        {
            NSString * infile = [array firstObject];
            [LuaObf compressLuaFile:infile output:outFile prefix:nil];
        } else if(mode == CD_OPT_mmd5)
        {
            [UserConfig sharedInstance].imageMode = 4;
            NSString * infile = [array firstObject];
            [ImageTools solveImage:infile];
            [mmd5 mmd5Dir:infile outDir:infile];
        } else if(mode == CD_OPT_zip)
        {
            compressToZip([[array firstObject] UTF8String], [outFile UTF8String]);
        } else if(mode == CD_OPT_unzip)
        {
            loadZipFile([[array firstObject] UTF8String], [outFile UTF8String]);
        }
    }
    if(mode == 0) {
        [FileLogger loggerEnabled:[UserConfig sharedInstance].saveLog];
        return NSApplicationMain(argc, argv);
    }
    return 0;
    
}
