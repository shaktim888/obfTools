//
//  HYObfuscationTool.m
//  HYCodeObfuscation
//
//  Created by HY admin on 2019/8/17.
//  Copyright © 2019年 HY admin. All rights reserved.
//

#import "HYObfuscationTool.h"
#import "NSString+Extension.h"
#import "NSFileManager+Extension.h"
#import "HYClangTool.h"
#import "UserConfig.h"
#import "HYGenerateNameTool.h"

#define HYEncryptKeyVar @"#var#"
#define HYEncryptKeyComment @"#comment#"
#define HYEncryptKeyFactor @"#factor#"
#define HYEncryptKeyValue @"#value#"
#define HYEncryptKeyLength @"#length#"
#define HYEncryptKeyContent @"#content#"

@implementation HYObfuscationTool

//+ (NSString *)_encryptStringDataHWithComment:(NSString *)comment
//                                         var:(NSString *)var
//{
//    NSMutableString *content = [NSMutableString string];
//    [content appendString:[NSString hy_stringWithFilename:@"File/ScanTemplate/HYEncryptStringDataHUnit" extension:@"tpl"]];
//    [content replaceOccurrencesOfString:HYEncryptKeyComment
//                             withString:comment
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    [content replaceOccurrencesOfString:HYEncryptKeyVar
//                             withString:var
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    return content;
//}
//
//+ (NSString *)_encryptStringDataMWithComment:(NSString *)comment
//                                         var:(NSString *)var
//                                      factor:(NSString *)factor
//                                       value:(NSString *)value
//                                      length:(NSString *)length
//{
//    NSMutableString *content = [NSMutableString hy_stringWithFilename:@"File/ScanTemplate/HYEncryptStringDataMUnit"
//                                                            extension:@"tpl"];
//    [content replaceOccurrencesOfString:HYEncryptKeyComment
//                             withString:comment
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    [content replaceOccurrencesOfString:HYEncryptKeyVar
//                             withString:var
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    [content replaceOccurrencesOfString:HYEncryptKeyFactor
//                             withString:factor
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    [content replaceOccurrencesOfString:HYEncryptKeyValue
//                             withString:value
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    [content replaceOccurrencesOfString:HYEncryptKeyLength
//                             withString:length
//                                options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
//    return content;
//}
//
//+ (void)encryptString:(NSString *)string
//           completion:(void (^)(NSString *, NSString *))completion
//{
//    if (string.hy_stringByRemovingSpace.length == 0
//        || !completion) return;
//
//    // 拼接value
//    NSMutableString *value = [NSMutableString string];
//    char factor = arc4random_uniform(pow(2, sizeof(char) * 8) - 1);
//    const char *cstring = string.UTF8String;
//    int length = (int)strlen(cstring);
//    for (int i = 0; i< length; i++) {
//        [value appendFormat:@"%d,", factor ^ cstring[i]];
//    }
//    [value appendString:@"0"];
//
//    // 变量
//    NSString *var = [NSString stringWithFormat:@"_%@", string.hy_crc32];
//
//    // 注释
//    NSMutableString *comment = [NSMutableString string];
//    [comment appendFormat:@"/* %@ */", string];
//
//    // 头文件
//    NSString *hStr = [self _encryptStringDataHWithComment:comment var:var];
//
//    // 源文件
//    NSString *mStr = [self _encryptStringDataMWithComment:comment
//                                                      var:var
//                                                   factor:[NSString stringWithFormat:@"%d", factor]
//                                                    value:value
//                                                   length:[NSString stringWithFormat:@"%d", length]];
//    completion(hStr, mStr);
//}
NSMutableSet *typeSet;
NSMutableSet *funcSet;
NSMutableSet *varSet;
NSMutableSet *propSet;
NSMutableSet *argSet;

+ (void) reset
{
    [HYClangTool clearCache];
    typeSet = [NSMutableSet set];
    funcSet = [NSMutableSet set];
    varSet = [NSMutableSet set];
    propSet = [NSMutableSet set];
    argSet = [NSMutableSet set];
}

+ (void) write : (NSString *) folder
{
    NSString * globalClassPrefix = @"";
    if(arc4random() % 100 <= 30) {
        int cnt = arc4random() % 3 + 1;
        NSString *letters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        NSMutableString *string = [NSMutableString stringWithCapacity:cnt];
        for (int i = 0; i < cnt; i++) {
            uint32_t index = arc4random_uniform((uint32_t)letters.length);
            unichar c = [letters characterAtIndex:index];
            [string appendFormat:@"%C", c];
        }
        globalClassPrefix = string;
    }
    folder = [folder stringByStandardizingPath];
    [typeSet removeObject:@""];
    [funcSet removeObject:@""];
    [varSet removeObject:@""];
    [propSet removeObject:@""];
    [argSet removeObject:@""];
    NSMutableString *fileContent = [NSMutableString string];
    NSMutableArray *obfuscations = [NSMutableArray array];
    if([UserConfig sharedInstance].scanType && typeSet.count > 0){
        [fileContent appendString:@"// class begin\n"];
        for (NSString *token in typeSet) {
            NSString *obfuscation = [HYGenerateNameTool generateName:TypeName from:token typeName:nil cache:true globalClassPrefix:globalClassPrefix];
            [obfuscations addObject:obfuscation];
            [fileContent appendFormat:@"#ifndef %@\n#define %@ %@\n#endif\n", token, token, obfuscation];
        }
    }
    if([UserConfig sharedInstance].scanFunc && funcSet.count > 0){
        [fileContent appendString:@"// func begin\n"];
        for (NSString *token in funcSet) {
            NSString *obfuscation = [HYGenerateNameTool generateName:FuncName from:token typeName:nil cache:true globalClassPrefix:globalClassPrefix];
            [obfuscations addObject:obfuscation];
            [fileContent appendFormat:@"#ifndef %@\n#define %@ %@\n#endif\n", token, token, obfuscation];
        }
        
        if(argSet.count > 0) {
            [fileContent appendString:@"// arg begin\n"];
            for (NSString *token in argSet) {
                NSString *obfuscation = [HYGenerateNameTool generateName:ArgName from:token typeName:nil cache:false globalClassPrefix:globalClassPrefix];
                [obfuscations addObject:obfuscation];
                [fileContent appendFormat:@"#ifndef %@\n#define %@ %@\n#endif\n", token, token, obfuscation];
            }
        }
    }
    
    if([UserConfig sharedInstance].scanVar && varSet.count > 0){
        [fileContent appendString:@"// var begin\n"];
        for (NSString *token in varSet) {
            NSString *obfuscation = [HYGenerateNameTool generateName:VarName from:nil typeName:nil cache:false globalClassPrefix:globalClassPrefix];
            [obfuscations addObject:obfuscation];
            [fileContent appendFormat:@"#ifndef %@\n#define %@ %@\n#endif\n", token, token, obfuscation];
        }
    }
    
    if([UserConfig sharedInstance].scanProp && propSet.count > 0){
        [fileContent appendString:@"// prop begin\n"];
        for (NSString *token in propSet) {
            NSString *obfuscation = [HYGenerateNameTool generateName:VarName from:token typeName:nil cache:true globalClassPrefix:globalClassPrefix];
            [obfuscations addObject:obfuscation];
            [fileContent appendFormat:@"#ifndef %@\n#define %@ %@\n#endif\n", token, token, obfuscation];
        }
    }
    NSString * destFilepath = [folder stringByAppendingPathComponent:@"Obfuscation_PCH.h"];

    [fileContent writeToFile:destFilepath atomically:YES
                    encoding:NSUTF8StringEncoding error:nil];
    
}

+ (void) obfuscateWithFiles: (NSArray<NSString*> *) files
prefixes:(NSArray *)prefixes
{
    for (NSString *subpath in files) {
        NSString * dir = [subpath stringByDeletingLastPathComponent];
        if([HYGenerateNameTool isIgnoreFile:subpath]) continue;
        HYTokensClientData* data = [HYClangTool classesAndMethodsWithFile:subpath prefixes:prefixes searchPath:dir];
        [typeSet addObjectsFromArray:data.typeTokens.allObjects];
        [funcSet addObjectsFromArray:data.funcTokens.allObjects];
        [propSet addObjectsFromArray:data.propTokens.allObjects];
        [argSet addObjectsFromArray:data.argTokens.allObjects];
        [varSet addObjectsFromArray:data.varTokens.allObjects];
    }
}

+ (void)obfuscateAtDir:(NSArray<NSString*> *)dirs
                    prefixes:(NSArray *)prefixes
{
    for(NSString * dir in dirs)
    {
        if (dir.length == 0) continue;
        NSArray *subpaths = [NSFileManager hy_subpathsAtPath:dir extensions:@[@"c", @"cc", @"cpp", @"m", @"mm"]];
        for (NSString *subpath in subpaths) {
            if([HYGenerateNameTool isIgnoreFile:subpath]) continue;
            HYTokensClientData* data = [HYClangTool classesAndMethodsWithFile:subpath prefixes:prefixes searchPath:dir];
            [typeSet addObjectsFromArray:data.typeTokens.allObjects];
            [funcSet addObjectsFromArray:data.funcTokens.allObjects];
            [propSet addObjectsFromArray:data.propTokens.allObjects];
            [argSet addObjectsFromArray:data.argTokens.allObjects];
            [varSet addObjectsFromArray:data.varTokens.allObjects];
        }
    }
//    completion(fileContent);
}

@end
