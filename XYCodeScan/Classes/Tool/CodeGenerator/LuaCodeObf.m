#import <Foundation/Foundation.h>
#import "LuaCodeObf.h"
#import "HYGenerateNameTool.h"
#import "NSString+Extension.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"
#import "UserConfig.h"

NSString * generateDeclareVar(NSMutableSet * set)
{
    NSString * name = [HYGenerateNameTool generateName:VarName from:nil typeName:nil cache:false globalClassPrefix:@""];
    while([set containsObject:name])
    {
        name = [HYGenerateNameTool generateName:VarName from:nil typeName:nil cache:false globalClassPrefix:@""];
    }
    [set addObject:name];
    return [NSString stringWithFormat:@"local %@;\n", name];
}


@implementation LuaCodeObf

+ (NSString*) generateOneLineCode :(int) deep funcs : (NSMutableArray*) funcs args: (NSArray *) args customFuncs : (NSMutableArray *) customFuncs
{
    NSString * arg1;
    NSString * space = @"";
    for(int i = 0; i < deep; i++)
    {
        space = [space stringByAppendingString:@"    "];
    }
    NSMutableString * ret = [NSMutableString string];
    if(args.count > 0) {
        arg1 = args[0];
    } else {
        arg1 = [HYGenerateNameTool generateByName:VarName from:nil cache:false];
        [ret appendString:[NSString stringWithFormat:@"%@local %@ = %d;\n", space, arg1, arc4random() % 5000]];
    }
    
    NSString * arg2;
    if(args.count > 1) {
        arg2 = args[1];
    } else {
        arg2 = [HYGenerateNameTool generateByName:VarName from:nil cache:false];
        [ret appendString:[NSString stringWithFormat:@"%@local %@ = %d;\n", space, arg2, arc4random() % 5000]];
    }
    
    NSString * arg3;
    if(args.count > 2) {
        arg3 = args[2];
    } else {
        arg3 = [HYGenerateNameTool generateByName:VarName from:nil cache:false];
        [ret appendString:[NSString stringWithFormat:@"%@local %@ = %d;\n", space, arg3, arc4random() % 5000]];
    }
    
    NSArray * types = @[@"+", @"-" ,@"*", @"/", @"%", @".."];
    NSArray * compares = @[@">", @"<", @"==", @"~=", @">=", @"<="];
    int type = (deep > 3) ? (arc4random() % 2) : (arc4random() % 5);
    switch (type) {
        case 1:
        {
            int tt = arc4random() % 5;
            switch (tt) {
                case 1:
                    [ret appendString:[NSString stringWithFormat:@"%@%@ = %@ %@ %@;\n",space, arg1, arg2, types[arc4random() % types.count], arg3]];
                    break;
                case 2:
                    [ret appendString:[NSString stringWithFormat:@"%@%@ = (%@ %@ %@) %@ %@;\n", space, arg1, arg1, types[arc4random() % types.count], arg2, types[arc4random() % types.count], arg3]];
                    break;
                case 3:
                    [ret appendString:[NSString stringWithFormat:@"%@%@ = %@ %@ (%@ %@ %@);\n",space, arg1, arg1, types[arc4random() % types.count], arg2, types[arc4random() % types.count], arg3]];
                    break;
                case 4:
                {
                    NSString * innerArg = [HYGenerateNameTool generateByName:VarName from:nil cache:false];
                    [ret appendString:[NSString stringWithFormat:@"%@local %@ = %d;\n", space, innerArg, arc4random() % 5000]];
                    break;
                }
                default:
                {
                    NSString * innerArg = [HYGenerateNameTool generateByName:VarName from:nil cache:false];
                    [ret appendString:[NSString stringWithFormat:@"%@local %@ = %d;\n", space, innerArg, arc4random()]];
                    [ret appendString:[NSString stringWithFormat:@"%@%@ = %@ %@ %@;\n",space, innerArg, innerArg, types[arc4random() % types.count], arg1]];
                    break;
                }
            }
            break;
        }
        case 2:
        {
            if(arc4random() % 100 <= funcs.count * 5)
            {
                int tt = arc4random() % 4;
                NSString * f = funcs[arc4random() % funcs.count];
                switch (tt) {
                    case 1:
                        [ret appendString:[NSString stringWithFormat:@"%@%@(%@, %@)\n",space, f, arg1, arg2]];
                        break;
                    case 2:
                        [ret appendString:[NSString stringWithFormat:@"%@%@(%@, %@, %@);\n", space, f, arg1, arg2, arg3]];
                        break;
                    default:
                        [ret appendString:[NSString stringWithFormat:@"%@%@(%@);\n",space, f, arg1]];
                        break;
                }
            }
            else
            {
                if(arc4random() % 100 >= customFuncs.count * 10)
                {
                    NSString * f = [HYGenerateNameTool generateByName:FuncName from:nil cache:false];
                    [customFuncs addObject:f];
                    [ret appendString:[self genFunction:deep funcName:f funcs:funcs belong:nil customFuncs:customFuncs]];
                }
                else
                {
                    NSString * f = customFuncs[arc4random() % customFuncs.count];
                    int tt = arc4random() % 4;
                    switch (tt) {
                        case 1:
                            [ret appendString:[NSString stringWithFormat:@"%@%@(%@, %@)\n",space, f, arg1, arg2]];
                            break;
                        case 2:
                            [ret appendString:[NSString stringWithFormat:@"%@%@(%@, %@, %@);\n", space, f, arg1, arg2, arg3]];
                            break;
                        default:
                            [ret appendString:[NSString stringWithFormat:@"%@%@(%@);\n",space, f, arg1]];
                            break;
                    }
                }
            }
            break;
        }
        case 3:
        {
            [ret appendString:[NSString stringWithFormat:@"%@if(%@ %@ %@) {\n%@%@}\n", space, arg2, compares[arc4random() % compares.count], arg3, [self generateOneLineCode:deep + 1 funcs: funcs args:args customFuncs:customFuncs], space]];
            break;
        }
        case 4:
        {
            [ret appendString:[NSString stringWithFormat:@"%@while(%@ %@ %@) {\n%@%@}\n", space, arg2, compares[arc4random() % compares.count], arg3, [self generateOneLineCode:deep + 1 funcs: funcs args:args customFuncs:customFuncs], space]];
            break;
        }
        default:
            [ret appendString:[NSString stringWithFormat:@"%@print(%@);\n", space, arg2]];
            break;
    }
    return ret;
}


+ (NSString*) genFunction : (int) deep funcName:(NSString*) funcName funcs : (NSMutableArray *) funcs belong : (NSString *) belong customFuncs:(NSMutableArray*) customFuncs
{
    int backupLen = (int)funcs.count;
    for(int i = 0; i < customFuncs.count; i++)
    {
        [funcs insertObject:customFuncs[i] atIndex:backupLen + i];
    }
    
    NSString * space = @"";
    for(int i = 0; i < deep; i++)
    {
        space = [space stringByAppendingString:@"    "];
    }
    NSMutableString * ret = [NSMutableString string];
    if(belong && belong.length > 0) {
        [ret appendFormat:@"%@function %@:%@(",space, belong, funcName];
    } else {
        [ret appendFormat:@"%@local function %@(",space, funcName];
    }
    int argsNum =  arc4random() % 4;
    NSMutableArray * args = [[NSMutableArray alloc] init];
    for(int i = 0; i < argsNum; i++)
    {
        NSString * argName = [HYGenerateNameTool generateByName:VarName from:nil cache:false];
        [args addObject:argName];
        [ret appendString:i == 0 ? argName : [@", " stringByAppendingString:argName]];
    }
    [ret appendString:@")\n"];
    int lines = arc4random() % 3 + 2;
    for(int i = 0; i < lines; i++){
        [ret appendString:[self generateOneLineCode:deep + 1 funcs: funcs args:args customFuncs:[NSMutableArray new]]];
    }
    [ret appendFormat:@"%@end\n", space];
    while(funcs.count > backupLen)
    {
        [funcs removeLastObject];
    }
    return ret;
}

+ (NSMutableArray*) genFuncsArray : (NSString*) className
{
    int funcsNumber = (arc4random() % 8) + 5;
    NSMutableArray * funcs = [NSMutableArray new];
    NSMutableArray * funcNames = [NSMutableArray new];
    NSMutableArray * paramsArray = [NSMutableArray new];
    
    for (int i = 0; i < funcsNumber; i ++) {
        NSString *funcName = [HYGenerateNameTool generateByName:FuncName from:nil cache:false];
        [funcNames addObject:funcName];
        [funcs addObject:[@"self:" stringByAppendingString:funcName]];
    }
    for (int i = 0; i < funcsNumber; i ++) {
        NSString *funcName = [funcNames objectAtIndex:i];
        NSMutableArray * args = [[NSMutableArray alloc] init];
        int argsNum =  arc4random() % 4;
        for(int i = 0; i < argsNum; i++)
        {
            [args addObject:[HYGenerateNameTool generateByName:VarName from:nil cache:false]];
        }
        [paramsArray addObject:[self genFunction:0 funcName:funcName funcs:[funcs mutableCopy] belong:className customFuncs:[NSMutableArray new]]];
    }
    return paramsArray;
}

+(void) generateLuaFile : (NSString *) folder num : (int) num
{
    folder = [folder stringByStandardizingPath];
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"File/CodeGenerator/CodeFileTemplate/Generate_lua" ofType:@"txt"];
    for(int i = 0; i < num; i++)
    {
        NSString * className = [HYGenerateNameTool generateByName:TypeName from:nil cache:true];
        
        NSString* path = [folder stringByAppendingPathComponent:[className stringByAppendingString:@".lua"]];
        while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            className = [HYGenerateNameTool generateByName:TypeName from:nil cache:true];
            path = [folder stringByAppendingPathComponent:[className stringByAppendingString:@".lua"]];
        }
        
        NSMutableArray * funcs = [self genFuncsArray:className];
        NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                                   funcs, @"funcs",
                                   className, @"ClassName",
                                   nil];
        NSString *result = [engine processTemplateInFileAtPath:templatePath withVariables:variables];
        [result writeToFile:path atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
}

+(void) rcg : (NSString*) input output : (NSString*) output
{
    if([[input pathExtension] isEqualToString:@"lua"]) {
        NSMutableSet * nameSet = [[NSMutableSet alloc] init];
        int line = arc4random() % 10 + 10;
        NSMutableString * ret = [NSMutableString string];
        for(int i = 0; i < line; i++)
        {
            [ret appendString:generateDeclareVar(nameSet)];
        }
        NSString * file = [NSString hy_stringWithFile:input];
        [ret appendString:file];
        [ret writeToFile:output atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
}

@end
