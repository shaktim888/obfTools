#import <Foundation/Foundation.h>
#import "HYGenerateNameTool.h"
#import "NSString+Extension.h"
#import "NameGeneratorExtern.h"
#import "UserConfig.h"
#import "NSString+Extension.h"
#include <regex>
#include <string>

@interface HYGenerateNameTool(){
    NSMutableDictionary * nameCache;
    NSMutableDictionary * dict;
    NSArray * wordArr;
    NSMutableDictionary * _defaultForbiddenDict;
    NSMutableDictionary * _customForbiddenDict;
}
@end

@implementation HYGenerateNameTool

+ (HYGenerateNameTool* )sharedInstance {
    static HYGenerateNameTool * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _defaultForbiddenDict = [[NSMutableDictionary alloc] init];
        _customForbiddenDict = [[NSMutableDictionary alloc] init];
        [self buildDefaultCfg];
        nameCache = [[NSMutableDictionary alloc] init];
        dict = [[NSMutableDictionary alloc] init];
        NSMutableSet * wordSet = [[NSMutableSet alloc] init];
        NSArray* types = @[@"Func", @"Type", @"Var", @"Arg", @"Res"];
        NSArray* tpls = @[@"prefix", @"suffix", @"template"];
        for(NSString* t in types)
        {
            NSMutableDictionary * childDict = [[NSMutableDictionary alloc] init];
            for(NSString * tpl in tpls)
            {
                NSString * content = [NSString hy_stringWithFilename:[NSString stringWithFormat:@"File/NameTemplate/%@/%@", t, tpl] extension:@"list"];
                content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSMutableSet * ss = [NSMutableSet setWithArray:[content componentsSeparatedByString:@"\n"]];
                [ss removeObject:@""];
                [childDict setObject:[ss allObjects] forKey:tpl];
            }
            [dict setObject:childDict forKey:t];
        }
        NSString * wordContent = [NSString hy_stringWithFilename:@"File/NameTemplate/cet4" extension:@"list"];
        wordContent = [wordContent stringByReplacingOccurrencesOfString:@" " withString:@""];
        [wordSet addObjectsFromArray:[wordContent componentsSeparatedByString:@"\n"]];
        [wordSet removeObject:@""];
        wordArr = wordSet.allObjects;
    }
    return self;
}


- (void) buildDefaultCfg
{
    NSError *error;
    NSString *textFileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"File/ScanTemplate/ignore" ofType:@"list"] encoding:NSUTF8StringEncoding error: &error];
    if (textFileContents == nil) {
        NSLog(@"Error reading text file. %@", [error localizedFailureReason]);
    }
    NSArray *readArr = [textFileContents componentsSeparatedByString:@"\n"];
    for(NSString * line in readArr) {
        [self addIgnoreConfig:line dict:_defaultForbiddenDict];
    }
}

- (void) addIgnoreConfig : (NSString*) info dict : (NSMutableDictionary * ) dict
{
    info = [info stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * ext = [info pathExtension];
    if(ext.length > 0){
        NSDictionary * map = @{
                               @"folder" : @(Ignore_Folder),
                               @"group" : @(Ignore_Group),
                               @"func" : @(Ignore_Func),
                               @"var" : @(Ignore_Var),
                               @"arg" : @(Ignore_Arg),
                               @"type" : @(Ignore_Type)
                               };
        NSNumber * num = [map objectForKey:ext];
        if(!num) {
            num = @(Ignore_File);
        } else {
            info = [info stringByDeletingPathExtension];
        }
        NSMutableSet * d = dict[num];
        if(!d)
        {
            d = [[NSMutableSet alloc] init];
            [dict setObject:d forKey:num];
        }
        [d addObject:info];
        
    } else {
        NSMutableSet * d = dict[@(Ignore_ALL)];
        if(!d)
        {
            d = [[NSMutableSet alloc] init];
            [dict setObject:d forKey:@(Ignore_ALL)];
        }
        [d addObject:info];
    }
}

-(BOOL) checkNameOK : (NSString *) name type : (IgnoreEnumType) type scanAll : (BOOL) scanAll{
    Timer_start("filterName");
    if(scanAll) {
        if(_defaultForbiddenDict[@(Ignore_ALL)] && [_defaultForbiddenDict[@(Ignore_ALL)] containsObject:name]) {
            Timer_end("filterName");
            return false;
        }
        if(_customForbiddenDict[@(Ignore_ALL)] && [_customForbiddenDict[@(Ignore_ALL)] containsObject:name]) {
            Timer_end("filterName");
            return false;
        }
    }
    if(!scanAll || type != Ignore_ALL) {
        if(_defaultForbiddenDict[@(type)] && [_defaultForbiddenDict[@(type)] containsObject:name]) {
            Timer_end("filterName");
            return false;
        }
        if(_customForbiddenDict[@(type)] && [_customForbiddenDict[@(type)] containsObject:name]) {
            Timer_end("filterName");
            return false;
        }
    }
    Timer_end("filterName");
    return true;
}


+ (bool) isIgnoreFile : (NSString *) filePath
{
    NSString * fileName = [filePath lastPathComponent];
    NSArray * components = [filePath pathComponents];
    if(components.count > 1){
        NSString * fileFolder = components[components.count - 2];
        if(![[self sharedInstance] checkNameOK:fileFolder type:Ignore_Folder scanAll:false]){
            return true;
        }
    }
    if([UserConfig sharedInstance].isUnity){
        NSArray * ignoreFiles = @[
                                  @"^Il2Cpp.*",
                                  @"^Bulk_.*",
                                  @"^mscorlib_.*",
                                  @"^AssemblyU2DCSharp_.*",
                                  @"^DOTween.*",
                                  @"^Mono_.*",
                                  @"^System_Core_.*",
                                  @"^Unity.*",
                                  @"^System_System_.*",
                                  @"^System_Core_.*",
                                  @"^GenericMethods.*",
                                  @"^DeviceSettings\\..*"
                                  ];
        for(NSString * pattern in ignoreFiles)
        {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *result = [regex matchesInString:fileName options:0 range:NSMakeRange(0, fileName.length)];
            if(result.count > 0)
            {
                return true;
            }
        }
    }
    return ![[self sharedInstance] checkNameOK:fileName type:Ignore_File scanAll:false];
}

- (void)resetCustomIgnoreFile
{
    [_customForbiddenDict removeAllObjects];
    NSString * ignoreFile = [UserConfig sharedInstance].customIgnoreFile;
    if(ignoreFile && ![ignoreFile isEqualToString:@""]) {
//        NSString *textFileContents = [NSString hy_stringWithFile:ignoreFile];
//        if (textFileContents) {
//            NSArray *readArr = [textFileContents componentsSeparatedByString:@"\n"];
//            for(NSString * line in readArr) {
//                [self addIgnoreConfig:line dict:_customForbiddenDict];
//            }
//        }
        
        //修复忽略文件不生效问题
        NSArray *readArr = [ignoreFile componentsSeparatedByString:@"\n"];
        for(NSString * line in readArr) {
            [self addIgnoreConfig:line dict:_customForbiddenDict];
        }
    }
}

- (void)addCustomForbiddenName : (NSString*) name
{
    [self addIgnoreConfig:name dict:_customForbiddenDict];
}

+(void)addCustomForbiddenName : (NSString*) name
{
    [[self sharedInstance] addCustomForbiddenName:name];
}

+(void)buildCustomForbiddenName
{
    [[self sharedInstance] resetCustomIgnoreFile];
}

+(BOOL)checkNameOK: (NSString *) name type : (IgnoreEnumType) type scanAll : (BOOL) scanAll{
    if(type == Ignore_NONE) { return true;}
    if([UserConfig sharedInstance].isUnity && [name hasPrefix:@"Unity"]) {
        return false;
    }
    auto isOk = [[self sharedInstance] checkNameOK:name type:type scanAll:scanAll];
    if(isOk && [name hasPrefix:@"_"]){
        isOk = [[self sharedInstance] checkNameOK:[name substringFromIndex:1] type:type scanAll:scanAll];
    }
    return isOk;
}

+ (BOOL) checkGroupOK: (NSString *) name {
    return [[self sharedInstance] checkNameOK:name type:Ignore_Group scanAll:false];
}
//--------------------------------------------------------

- (NSString*) solveTpl : (NSString *) tpl prefixs:( NSArray* )prefixs suffixs:( NSArray *) suffixs from: (NSString*) fromTypeName
{
    NSString * prefix = [prefixs count] > 0 ? prefixs[arc4random() % [prefixs count]] : @"";
    NSString * prefix2 = [prefixs count] > 0 ? prefixs[arc4random() % [prefixs count]] : @"";
    NSString * suffix = [suffixs count] > 0 ? suffixs[arc4random() % [suffixs count]] : @"";
    NSString * suffix2 = [suffixs count] > 0 ? suffixs[arc4random() % [suffixs count]] : @"";
    if(fromTypeName)
    {
        bool needAddPrefix = false;
        bool needAddSuffix = false;
        if([fromTypeName hasPrefix:@"init"]){
            prefix = @"init";
            prefix2 = @"init";
            needAddPrefix = true;
        }
        NSArray * arr = splitWord(fromTypeName);
        if(arr.count >= 3) {
            if(arc4random() % 3 == 1) {
                suffix2 = [[arr objectAtIndex:arr.count - 2] stringByAppendingString:[arr objectAtIndex:arr.count - 1]];
                suffix = suffix2;
                needAddSuffix = true;
            } else {
                suffix = [arr objectAtIndex:arr.count - 1];
//                if(arc4random() % 100 <= 30) {
//                    unsigned long len = arc4random() % 3 + 4;
//                    if(len > suffix.length) len = suffix.length;
//                    suffix = [suffix substringWithRange:NSMakeRange(0, len)];
//                }
                suffix2 = suffix;
                needAddSuffix = true;
            }
        } else {
            if(arr.count == 1) {
                if([[arr lastObject] isEqualToString:@"int"]
                   || [[arr lastObject] isEqualToString:@"float"]
                   ) {
                    NSArray * arr = @[@"len", @"cnt", @"ratio", @"num", @"number", @"scale", @"size", @"length", @"offset", @"height", @"w", @"width", @"height"];
                    NSString * word = arr[arc4random() % arr.count];
                    
                    if(arc4random() % 100 < 20) {
                        word = [suffix stringByAppendingString:[word hy_firstCharUppercase]];
                    }
                    return word;
                }
                if([[arr lastObject] isEqualToString:@"bool"]
                   || [[arr lastObject] isEqualToString:@"BOOL"]) {
                    prefix = @"is";
                    prefix2 = @"is";
                    needAddPrefix = true;
                }
            }
            if(arr.count == 2) {
                if([[arr objectAtIndex:0] isEqualToString:@"NS"] and
                   [[arr objectAtIndex:1] isEqualToString:@"String"]) {
                    NSArray * arr = @[@"title", @"str", @"url", @"name", @"content", @"txt", @"text", @"desc", @"description",@"path",@"info",@"tip",@"message",@"msg"];
                    NSString * word = arr[arc4random() % arr.count];
                                      
                    if(arc4random() % 100 < 20) {
                        word = [suffix stringByAppendingString:[word hy_firstCharUppercase]];
                    }
                    return word;
                }
                
                suffix = [arr lastObject];
                suffix2 = suffix;
            }
        }
        
        if(needAddPrefix) {
            if(![tpl containsString:@"${Prefix}"] && ![tpl containsString:@"${prefix}"]) {
                tpl = [@"${prefix}" stringByAppendingString:tpl];
            }
        }
        if(needAddSuffix) {
            if(![tpl containsString:@"${Suffix}"] && ![tpl containsString:@"${suffix}"]) {
                tpl = [tpl stringByAppendingString:@"${Suffix}"];
            }
        }

    }
    if([tpl containsString:@"${prefix}"]) {
        tpl = [tpl stringByReplacingOccurrencesOfString:@"${prefix}" withString:[prefix hy_firstCharLowercase]];
    }
    if([tpl containsString:@"${Prefix}"]) {
        tpl = [tpl stringByReplacingOccurrencesOfString:@"${Prefix}" withString:[prefix2 hy_firstCharUppercase]];
    }
    if([tpl containsString:@"${suffix}"]) {
        tpl = [tpl stringByReplacingOccurrencesOfString:@"${suffix}" withString:[suffix hy_firstCharLowercase]];
    }
    if([tpl containsString:@"${Suffix}"]) {
        tpl = [tpl stringByReplacingOccurrencesOfString:@"${Suffix}" withString:[suffix2 hy_firstCharUppercase]];
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\$\\{[wW]ord\\d*\\}" options: 0 error: nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:tpl options: NSMatchingReportCompletion range: NSMakeRange(0, [tpl length])];
    if (matches.count != 0) {
        NSString* backup = [[NSString alloc] initWithString:tpl];
        for(NSTextCheckingResult * match in matches)
        {
            NSString * m = [backup substringWithRange:match.range];
            NSString * word = wordArr[arc4random() % [wordArr count]];
            if([m containsString:@"word"])
            {
                tpl = [tpl stringByReplacingOccurrencesOfString:m withString:[word hy_firstCharLowercase]];
            }else{
                tpl = [tpl stringByReplacingOccurrencesOfString:m withString:[word hy_firstCharUppercase]];
            }
        }
    }
    return tpl;
}

- (NSString*) generateTypeName: (HYNameType) type from: (NSString*) from cache : (BOOL) cache globalClassPrefix: (NSString*) globalClassPrefix
{
    NSString * key;
    IgnoreEnumType t = Ignore_NONE;
    switch (type) {
        case FuncName:
            key = @"Func";
            t = Ignore_Func;
            break;
        case TypeName:
            key = @"Type";
            t = Ignore_Type;
            break;
        case VarName:
            key = @"Var";
            t = Ignore_Var;
            break;
        case ArgName:
            key = @"Arg";
            t = Ignore_Arg;
            break;
        case ResName:
        {
            key = @"Res";
            cache = false;
            break;
        }
        case WordName:
        {
            return wordArr[arc4random() % [wordArr count]];
            break;
        }
        default:
            t = Ignore_ALL;
            break;
    }
    NSDictionary * childDict = [dict objectForKey:key];
    NSArray* prefixs = [childDict objectForKey:@"prefix"];
    NSArray* suffixs = [childDict objectForKey:@"suffix"];
    NSArray* templates = [childDict objectForKey:@"template"];
    int template_index = arc4random() % [templates count];
    NSString * tpl = templates[template_index];
    NSString * ret = [self solveTpl:tpl prefixs:prefixs suffixs:suffixs from:from];
    NSMutableSet * dict = [nameCache objectForKey:@(type)];
    while(![HYGenerateNameTool checkNameOK:ret type:t scanAll:false] || (cache && dict && [dict containsObject:ret]))
    {
        ret = [self solveTpl:tpl prefixs:prefixs suffixs:suffixs from:from];
    }
    if(type == TypeName) {
        if(![globalClassPrefix isEqualToString:@""]) {
            ret = [globalClassPrefix stringByAppendingString:ret];
        }
    }
    if(cache)
    {
        if(!dict) {
            dict = [[NSMutableSet alloc] init];
            [nameCache setObject:dict forKey:@(type)];
        }
        [dict addObject:ret];
    }
    return ret;
}

static NSArray * splitWord(NSString * str)
{
    std::smatch m;
    std::string s([str UTF8String]);
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    // NSObject Object CNT ATFloat
    std::regex reg("_?(([A-Z]+)[A-Z][a-z0-9])|([A-Za-z0-9][a-z0-9]*)|([A-Z][A-Z]*)");
    std::string::const_iterator start = s.begin();
    std::string::const_iterator end = s.end();
    while (std::regex_search(start, end, m, reg))
    {
        if(m[2]!="") {
            [arr addObject:[NSString stringWithUTF8String:m.str(2).c_str()]];
            start = m[2].second;
        } else if(m[3] != "") {
            [arr addObject:[NSString stringWithUTF8String:m.str(3).c_str()]];
            start = m[3].second;
        } else if(m[4] != "") {
            [arr addObject:[NSString stringWithUTF8String:m.str(4).c_str()]];
            start = m[4].second;
        }
    }
    return arr;
}

-(NSString*) solveByOrigin :(NSMutableArray*) words from : (NSString*) from  prefixs : (NSArray*) prefixs suffixs: (NSArray*) suffixs
{
    NSString * prefix = [prefixs count] > 0 ? prefixs[arc4random() % [prefixs count]] : @"";
    NSString * suffix = [suffixs count] > 0 ? suffixs[arc4random() % [suffixs count]] : @"";
    if([from hasPrefix:@"init"]){
        prefix = @"init";
    }
    
    // 删除空白的内容
    for(int i = words.count - 1; i >= 0 ; i--) {
        if([words[i] isEqualToString:@""]) {
            [words removeObjectAtIndex:i];
        }
    }
    
    for(int i = words.count - 1; i >= 0 ; i--) {
        NSString *curWord = [words[i] hy_firstCharLowercase];
        // 去掉敏感词
        if([curWord hasPrefix:@"obf"]
           || [curWord hasPrefix:@"cocock"]
           || [curWord hasPrefix:@"check"]
           || [curWord hasPrefix:@"encode"]
           || [curWord hasPrefix:@"remote"]
           || [curWord hasPrefix:@"jump"]
           || [curWord hasPrefix:@"goto"]
           || [curWord hasPrefix:@"open"]
           || [curWord hasPrefix:@"wait"]
           || [curWord hasPrefix:@"decode"]) {
            NSString * word = wordArr[arc4random() % [wordArr count]];
            if(i == 0) {
                [words replaceObjectAtIndex:i withObject:[word hy_firstCharLowercase]];
            } else {
                [words replaceObjectAtIndex:i withObject:[word hy_firstCharUppercase]];
            }
        }
    }
    
    // >=3 个时， 保留前后缀， 中间随机替换单词。
    if (words.count >= 3) {
        int ended = (arc4random() % 2) + 1;
        for(int i = 0; i < words.count - ended; i++) {
            NSString * word = wordArr[arc4random() % [wordArr count]];
            [words replaceObjectAtIndex:i withObject:[word hy_firstCharUppercase]];
        }
    }
    // =2 个时， 保留后缀或者前缀。看前后缀的意义
    else if (words.count == 2) {
        int type = arc4random() % 5;
        switch (type) {
            case 0:
                if([prefix isEqualToString:@""]) goto randomAddWord;
                [words replaceObjectAtIndex:0 withObject:[prefix hy_firstCharLowercase]];
                break;
            case 1:
                if([suffix isEqualToString:@""]) goto randomAddWord;
                [words replaceObjectAtIndex:words.count - 1 withObject:[suffix hy_firstCharUppercase]];
                break;
            default:
            {
            randomAddWord:
                int cnt = arc4random() % 2 + 1;
                for(int i = 0; i < cnt ; i++) {
                    NSString * word = wordArr[arc4random() % [wordArr count]];
                    [words insertObject:[word hy_firstCharUppercase] atIndex:1];
                }
                break;
            }
        }
    }
    // =1 个时， 加前缀
    else if (words.count == 1) {
        // 看情况改个名字吧
        if(arc4random() % 100 <= 50) {
            NSString * word = wordArr[arc4random() % [wordArr count]];
            [words replaceObjectAtIndex:0 withObject:[word hy_firstCharLowercase]];
        }
        int type = arc4random() % 3;
        switch (type) {
            case 0:
                if([prefix isEqualToString:@""]) goto randomAddWord2;
                [words insertObject:[prefix hy_firstCharLowercase] atIndex:0];
                break;
            case 2:
                if([suffix isEqualToString:@""]) goto randomAddWord2;
                [words insertObject:[suffix hy_firstCharUppercase] atIndex:words.count - 1];
                break;
            default:
            randomAddWord2:
                NSString * word = wordArr[arc4random() % [wordArr count]];
                [words insertObject:[word hy_firstCharLowercase] atIndex:0];
                break;
        }
    }
    return [words componentsJoinedByString:@""];
}

-(NSString*) generateNameByOrigin : (HYNameType) type from: (NSString*) from cache : (BOOL) cache addGlobalPrefix : (NSString*) globalPrefix
{
    NSString * key;
    IgnoreEnumType t = Ignore_NONE;
    switch (type) {
        case FuncName:
            key = @"Func";
            t = Ignore_Func;
            break;
        case TypeName:
            key = @"Type";
            t = Ignore_Type;
            break;
        case VarName:
            key = @"Var";
            t = Ignore_Var;
            break;
        case ArgName:
            key = @"Arg";
            t = Ignore_Arg;
            break;
        case ResName:
        {
            key = @"Res";
            cache = false;
            break;
        }
        case WordName:
        {
            return wordArr[arc4random() % [wordArr count]];
            break;
        }
        default:
            t = Ignore_ALL;
            break;
    }
    NSDictionary * childDict = [dict objectForKey:key];
    NSArray* prefixs = [childDict objectForKey:@"prefix"];
    NSArray* suffixs = [childDict objectForKey:@"suffix"];
    
    NSMutableArray * words = [splitWord(from) mutableCopy];
    
    NSString * ret = [self solveByOrigin:words from:from prefixs:prefixs suffixs:suffixs];
    NSMutableSet * dict = [nameCache objectForKey:@(type)];
    while(![HYGenerateNameTool checkNameOK:ret type:t scanAll:t == Ignore_Type || t == Ignore_Func] || (cache && dict && [dict containsObject:ret]))
    {
        ret = [self solveByOrigin:words from:from prefixs:prefixs suffixs:suffixs];
    }
    if(type == TypeName) {
        if(![globalPrefix isEqualToString:@""]) {
            ret = [globalPrefix stringByAppendingString:ret];
        }
    }
    
    if(cache)
    {
        if(!dict) {
            dict = [[NSMutableSet alloc] init];
            [nameCache setObject:dict forKey:@(type)];
        }
        [dict addObject:ret];
    }
    return ret;
}

+(NSString*) generateName : (HYNameType) type from: (NSString*) from typeName: (NSString*) typeName cache : (BOOL) cache globalClassPrefix : (NSString*) globalClassPrefix
{
    if(from && ![from isEqualToString:@""]) {
        return [[HYGenerateNameTool sharedInstance] generateNameByOrigin:type from:from cache:cache addGlobalPrefix:globalClassPrefix];
    } else {
        return [[HYGenerateNameTool sharedInstance] generateTypeName: type from:typeName cache:cache globalClassPrefix:globalClassPrefix];
    }
}

-(void) clearCache : (HYNameType) type
{
    NSMutableSet * dict = [nameCache objectForKey:@(type)];
    if(dict) {
        [dict removeAllObjects];
    }
}

+ (void) clearCache : (HYNameType) type
{
    [[self sharedInstance] clearCache:type];
}

+ (void)resolveWord:(NSString *)path { 
    NSString * content = [NSString hy_stringWithFile:path];
    NSArray * arr = [content componentsSeparatedByString:@"\n"];
    NSMutableSet * s = [[NSMutableSet alloc] init];
    for(NSString * line in arr) {
        NSString * line2 = [[[[line stringByReplacingOccurrencesOfString:@"-" withString:@" "] stringByReplacingOccurrencesOfString:@"/" withString:@" "] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@"(" withString:@""];
        NSArray * words = [line2 componentsSeparatedByString:@" "];
        for(NSString * word in words) {
            if([word containsString:@"'"] || [word containsString:@"("] || [word containsString:@"（"] || [word containsString:@"."]) {
                continue;
            }
            [s addObject:word];
        }
    }
    NSComparator finderSort = ^(id string1,id string2){
        return [string1 compare:string2];
    };
    
    NSArray * ss = [s.allObjects sortedArrayUsingComparator:finderSort];
    NSString * ret = [ss componentsJoinedByString:@"\n"];
    [ret writeToFile:path atomically:true encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString *)generateByName:(HYNameType)type from:(NSString *)from cache:(BOOL)cache {
    return [self generateName:type from:from typeName:nil cache:cache globalClassPrefix:@""];
}

+ (NSString *)generateByTypeName:(HYNameType)type from:(NSString *)from cache:(BOOL)cache {
    return [self generateName:type from:nil typeName:from cache:cache globalClassPrefix:@""];
}

@end

const char * genNameForCplus(int t, bool needCache)
{
    return [[HYGenerateNameTool generateName:(HYNameType)t from:nil typeName:nil cache:needCache globalClassPrefix:@""] UTF8String];
}

void genNameClearCache(int t)
{
    [HYGenerateNameTool clearCache:(HYNameType)t];
}
