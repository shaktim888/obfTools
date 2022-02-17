//
//  GEN_lua.m
//  HYCodeScan
//
//  Created by admin on 2020/6/2.
//  Copyright © 2020 Admin. All rights reserved.
//

#import "GEN_lua.h"
#import "NSString+Extension.h"
#import "NameGeneratorExtern.h"
#import "UserConfig.h"

@interface GEN_lua(){
    NSMutableArray * allBlock;
    NSMutableArray * allHaveFuncTypes;
    NSMutableDictionary * luaCFG;
    int totalVarNum;
    int deep;
}
@end

@implementation GEN_lua

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void) clean
{
    [allBlock removeAllObjects];
    totalVarNum = 0;
    deep = 0;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        allBlock = [[NSMutableArray alloc] init];
        allHaveFuncTypes = [[NSMutableArray alloc] init];
        totalVarNum = 0;
        deep = 0;
        [self loadConfig];
    }
    return self;
}

- (void) loadConfig
{
    luaCFG = [[NSMutableDictionary alloc] init];
    NSString* jsonFile = [[NSBundle mainBundle] pathForResource:@"File/lua/lua.json" ofType:@""];
    NSString* jsonString = [NSString hy_stringWithFile:jsonFile];
    NSData  * jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError * err;
    NSArray * dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(dic) {
        for(NSDictionary * p in dic) {
            NSMutableDictionary * multCopy = [p mutableCopy];
            [luaCFG setObject:multCopy forKey:p[@"type"]];
        }
        for(NSDictionary * p in dic) {
            NSMutableDictionary * multCopy = luaCFG[p[@"type"]];
            NSMutableArray * funcs = [[NSMutableArray alloc] init];
            NSDictionary * itr = p;
            while(itr && (itr[@"func"] || itr[@"extern"])) {
                if(itr[@"allfunc"]) {
                    [funcs addObjectsFromArray:itr[@"allfunc"]];
                    break;
                } else {
                    if(itr[@"func"]) {
                        [funcs addObjectsFromArray:itr[@"func"]];
                    }
                }
                if(itr[@"extern"]) {
                    itr = luaCFG[itr[@"extern"]];
                } else {
                    itr = nil;
                }
            }
            if(funcs.count > 0) {
                [multCopy setObject:funcs forKey:@"allfunc"];
                [allHaveFuncTypes addObject:p[@"type"]];
            } else {
                [multCopy removeObjectForKey:@"allfunc"];
            }
        }
    }
}

- (void) enterBlock
{
    deep++;
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [allBlock addObject:dict];
}

- (void) exitBlock
{
    deep--;
    NSMutableDictionary * dict = [allBlock lastObject];
    totalVarNum -= dict.count;
    [allBlock removeLastObject];
}

- (NSString*) getOneVar
{
    int num = arc4random() % totalVarNum;
    int tn = 0;
    for(NSMutableDictionary* dict in allBlock) {
        if(tn + dict.count > num) {
            return [dict allKeys][num - tn];
        }
        tn += dict.count;
    }
    return nil;
}

- (NSString*) getSpaceCode
{
    NSMutableString * str = [NSMutableString string];
    [str appendString:@"\n"];
    for(int i = 0; i < deep - 1; i++) {
        [str appendString:@"    "];
    }
    return str;
}

- (NSString*) genOneCode
{
    if(deep <= 1) return @"";
    if(arc4random() % 100 > [UserConfig sharedInstance].prop) return @"";
    NSString * code;
    if(totalVarNum > 0 && arc4random() % 100 <= totalVarNum * 20) {
        code = [self genCallCode];
    } else {
        NSString * rtype = allHaveFuncTypes[arc4random() % allHaveFuncTypes.count];
        NSDictionary * d = [self genVarCreateCode:rtype needInit:true];
        if(d[@"precode"] && ![d[@"precode"] isEqualToString:@""]) {
            code = [d[@"precode"] stringByAppendingString:d[@"code"]];
        } else {
            code = [@"\n" stringByAppendingString:d[@"code"]];
        }
    }
    return [code stringByReplacingOccurrencesOfString:@"\n" withString:[self getSpaceCode]];
}

-(NSString *) genCallCode
{
    NSString * var = [self getOneVar];
    for(int pi = allBlock.count - 1; pi >= 0 ;pi --) {
        NSMutableDictionary* dict = allBlock[pi];
        NSString * t = [dict objectForKey:var];
        if(t) {
            NSDictionary* cfg = luaCFG[t];
            NSArray * funcs = cfg[@"allfunc"];
            if(funcs) {
                NSDictionary * f = funcs[arc4random() % funcs.count];
                NSMutableString * args = [NSMutableString string];
                NSArray* acfglist = f[@"args"];
                NSMutableString * preCode = [NSMutableString string];
                if(acfglist && [acfglist count] > 0) {
                    int index = 0;
                    for(NSString * atype in acfglist) {
                        NSDictionary * g = [self genVarCreateCode:atype needInit:false];
                        if(index > 0) {
                            [args appendString:@","];
                        }
                        if(g[@"precode"]){
                            [preCode appendString:g[@"precode"]];
                        }
                        // 替换名字
                        if(g[@"name"]) {
                            [args appendString:g[@"name"]];
                            [preCode appendString:@"\n"];
                            [preCode appendString:g[@"code"]];
                        } else {
                            // 替换成代码
                            [args appendString:g[@"code"]];
                        }
                        index++;
                    }
                }
                [preCode appendFormat:@"\nif not tolua.isnull(%@) then %@:%@(%@) end", var, var, f[@"name"], args];
                return preCode;
            }
        }
    }
    return @"";
}

-(NSString*) genVarName
{
    return [[NSString alloc] initWithFormat:@"GEN_%s", genNameForCplus(CVarName, false)];
}

static char randomOneChar()
{
    switch (arc4random() % 3) {
        case 0:
            return ('a' + arc4random() % 26);
            break;
        case 1:
            return ('A' + arc4random() % 26);
            break;
        default:
            return ('0' + arc4random() % 10);
            break;
    }
}

-(NSDictionary *) genVarCreateCode : (NSString *) typestr needInit : (BOOL) needInit
{
    NSString * typename;
    if([typestr containsString:@":"]) {
        NSArray * arr = [typestr componentsSeparatedByString:@":"];
        typename = arr.firstObject;
        if([typename isEqualToString:@"int"] || [typename isEqualToString:@"num"]) {
            int value = (arc4random() % ([arr[2] intValue] - [arr[1] intValue])) + [arr[1] intValue];
            return @{
                @"code" : [[NSString alloc] initWithFormat:@"%d", value]
            };
        }
        if([typename isEqualToString:@"float"] || [typename isEqualToString:@"double"]) {
            int minValue = [arr[1] floatValue] * 1000;
            int maxValue = [arr[2] floatValue] * 1000;
            int value = (arc4random() % (maxValue - minValue)) + minValue;
            return @{
                @"code" : [[NSString alloc] initWithFormat:@"%f", value / 1000.0f]
            };
        }
        if([typename isEqualToString:@"string"]) {
            int minlen = [arr[1] intValue];
            int maxlen = [arr[2] floatValue];
            int len = (arc4random() % (maxlen - minlen)) + minlen;
            NSMutableString * ret = [NSMutableString string];
            [ret appendString:@"\""];
            for(int i = 0; i < len; i ++ ) {
                [ret appendFormat:@"%c", randomOneChar()];
            }
            [ret appendString:@"\""];
            return @{
                @"code" : ret
            };
        }
    }
    else if([typestr containsString:@"|"]) {
        NSArray * types = [typestr componentsSeparatedByString:@"|"];
        return [self genVarCreateCode:types[arc4random() % types.count] needInit:needInit];
    } else {
        typename = typestr;
        NSDictionary * cfg = [luaCFG objectForKey:typename];
        if(cfg) {
            NSArray * creates = cfg[@"new"];
            NSString * name = nil;
            NSString * c = creates[arc4random() % creates.count];
            NSString *pattern = @"\\$\\{\\s*([\\w.:-]+)\\s*\\}";        //匹配规则
            NSMutableString * newCode = [NSMutableString string];
            NSMutableString * preCode = [NSMutableString string];
            NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
            {
                NSArray *result = [regx matchesInString:c options:0 range:NSMakeRange(0, c.length)];
                NSRange preRange = NSMakeRange(0, 0);
                for(NSTextCheckingResult * match in result) {
                    NSRange rg = match.range;
                    size_t startPos = preRange.location + preRange.length;
                    size_t midLen = rg.location - startPos;
                    [newCode appendString: [c substringWithRange:NSMakeRange(startPos, midLen)]];
                    
                    NSRange matchRange = [match rangeAtIndex:1];
                    NSString *str = [c substringWithRange:matchRange];
                    if([str isEqualToString:@"name"]) {
                        if(!name) {
                            name = [self genVarName];
                        }
                        [newCode appendString:name];
                    } else {
                        NSDictionary * g = [self genVarCreateCode:str needInit:false];
                        if(g[@"precode"]){
                            [preCode appendString:g[@"precode"]];
                        }
                        // 替换名字
                        if(g[@"name"]) {
                            [newCode appendString:g[@"name"]];
                            [preCode appendString:@"\n"];
                            [preCode appendString:g[@"code"]];
                        } else {
                            // 替换成代码
                            [newCode appendString:g[@"code"]];
                        }
                        
                    }
                    
                    preRange = rg;
                }
                [newCode appendString: [c substringWithRange:NSMakeRange(preRange.location + preRange.length, c.length - preRange.location - preRange.length)]];
            }
            if(needInit) {
                NSString * initcode = cfg[@"init"];
                if(initcode && ![initcode isEqualToString:@""]) {
                    NSString * c = initcode;
                    NSArray *result = [regx matchesInString:c options:0 range:NSMakeRange(0, c.length)];
                    NSRange preRange = NSMakeRange(0, 0);
                    [newCode appendString:@"\n"];
                    for(NSTextCheckingResult * match in result) {
                        NSRange rg = match.range;
                        size_t startPos = preRange.location + preRange.length;
                        size_t midLen = rg.location - startPos;
                        [newCode appendString: [c substringWithRange:NSMakeRange(startPos, midLen)]];
                        
                        NSRange matchRange = [match rangeAtIndex:1];
                        NSString *str = [c substringWithRange:matchRange];
                        if([str isEqualToString:@"name"]) {
                            if(!name) {
                                name = [self genVarName];
                            }
                            [newCode appendString:name];
                        } else {
                            NSDictionary * g = [self genVarCreateCode:str needInit:false];
                            if(g[@"precode"]){
                                [preCode appendString:g[@"precode"]];
                            }
                            // 替换名字
                            if(g[@"name"]) {
                                [newCode appendString:g[@"name"]];
                                [preCode appendString:@"\n"];
                                [preCode appendString:g[@"code"]];
                            } else {
                                // 替换成代码
                                [newCode appendString:g[@"code"]];
                            }
                            
                        }
                        
                        preRange = rg;
                    }
                    [newCode appendString: [c substringWithRange:NSMakeRange(preRange.location + preRange.length, c.length - preRange.location - preRange.length)]];
                }
            }
            
            if(name) {
                if(cfg[@"allfunc"]){
                    [self addVar:name type:typename];
                }
                return @{
                    @"name" : name,
                    @"code" : newCode,
                    @"precode": preCode
                };
            } else {
                return @{
                    @"code" : newCode,
                    @"precode": preCode
                };
            }
            
        }
    }
    return nil;
}

- (void) addVar : (NSString*) varname type:(NSString *) type
{
    NSMutableDictionary * dict = [allBlock lastObject];
    if(dict) {
        totalVarNum -= dict.count;
        [dict setObject:type forKey:varname];
        totalVarNum += dict.count;
    }
}


@end
