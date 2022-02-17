#import <Foundation/Foundation.h>
#import "LuaObf.h"
#import "NSString+Extension.h"
#import "UserConfig.h"
#import "myLuaParser.h"
#define LUA_USE
#ifdef LUA_USE
#import "LuaCall.hpp"
#endif

@interface LuaObf ()
{
#ifdef LUA_USE
    LuaCall * luaCall;
#endif
}
@end

@implementation LuaObf

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype) init {
    self = [super init];
    if (self) {
#ifdef LUA_USE
        luaCall = new LuaCall();
#endif
    }
    return self;
}

- (void)dealloc
{
#ifdef LUA_USE
    delete luaCall;
#endif
}

- (void) compressLuaFile: (NSString* ) folder output: (NSString *) output prefix:(NSString *) prefix
{
#ifdef LUA_USE
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    [arr addObject:folder];
    [arr addObject:output];
    if(prefix) {
        [arr addObject:prefix];
    }
    luaCall->setArgs([[arr componentsJoinedByString:@" "] UTF8String]);
    NSString * infile = [[NSBundle mainBundle] pathForResource:@"File/lua/compress.lua" ofType:nil];
    if(infile) {
        luaCall->executeFile([infile UTF8String], false);
    }
#endif
}

- (void) obf : (NSString*) file outfile: (NSString*) outfile
{
    file = [file stringByStandardizingPath];
    outfile = [outfile stringByStandardizingPath];
    //判断是不是文件夹
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isFolder = NO;
    //判断是不是存在路径 并且是不是文件夹
    BOOL isExist = [fileManager fileExistsAtPath:file isDirectory:&isFolder];
    if (isExist){
        if (isFolder){
            NSLog(@"正在混淆文件夹：%@", file);
            NSArray* array = [fileManager contentsOfDirectoryAtPath:file error:nil];
            for(int i = 0; i<[array count]; i++)
            {
                NSString *fullPath = [file stringByAppendingPathComponent:[array objectAtIndex:i]];
                NSString *fullToPath = [outfile stringByAppendingPathComponent:[array objectAtIndex:i]];
                [self obf:fullPath outfile:fullToPath];
            }
        } else {
            if([file hasSuffix:@".lua"]) {
                NSLog(@"正在混淆lua：%@", file);
                
                if(![file isEqualToString:outfile]){
                    [fileManager removeItemAtPath:outfile error:NULL];
                    [fileManager copyItemAtPath:file toPath:outfile error:nil];
                }
                
                if([UserConfig sharedInstance].insertLuaCocos) {
                    parserLua([outfile UTF8String], [outfile UTF8String]);
                }
#ifdef LUA_USE
                if([UserConfig sharedInstance].isUglifyLua || [UserConfig sharedInstance].isMinifyLua) {
                    NSMutableArray * arr = [[NSMutableArray alloc] init];
                    if([UserConfig sharedInstance].isUglifyLua) {
                        [arr addObject:@"--uglify"];
                    }
                    if([UserConfig sharedInstance].isMinifyLua) {
                        [arr addObject:@"--minify"];
                    }
                    [arr addObject:@"--input"];
                    [arr addObject:outfile];
                    [arr addObject:@"--output"];
                    [arr addObject:outfile];
                    luaCall->setArgs([[arr componentsJoinedByString:@" "] UTF8String]);
                    NSString * infile = [[NSBundle mainBundle] pathForResource:@"File/lua/obf.lua" ofType:nil];
                    if(infile) {
                        luaCall->executeFile([infile UTF8String], false);
                    }
                }
#endif
            }
        }
    }
}

+ (void) compressLuaFile: (NSString* ) folder output: (NSString *) output prefix:(NSString *) prefix
{
    return [[self sharedInstance] compressLuaFile:folder output:output prefix:prefix];
}

+ (void) obf : (NSString*) file outfile: (NSString*) outfile
{
    if([UserConfig sharedInstance].isUglifyLua || [UserConfig sharedInstance].isMinifyLua || [UserConfig sharedInstance].insertLuaCocos) {
        return [[self sharedInstance] obf:file outfile:outfile];
    }
}
@end
