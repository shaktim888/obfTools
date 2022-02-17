#import <Foundation/Foundation.h>
#import "CodeFileGenerator.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"
#import "HYGenerateNameTool.h"

@implementation CodeFileGenerator

+ (NSSet*) genCodeFile : (NSString *) outputFolder count : (unsigned int) count
{
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSFileManager * fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:outputFolder withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *templatePath_h = [[NSBundle mainBundle] pathForResource:@"File/CodeGenerator/CodeFileTemplate/DummyClass_h" ofType:@"txt"];
    NSString *templatePath_m = [[NSBundle mainBundle] pathForResource:@"File/CodeGenerator/CodeFileTemplate/DummyClass_m" ofType:@"txt"];

    NSMutableSet * classSet = [[NSMutableSet alloc] init];
    for(int i = 0; i < count; i++) {
        NSString *className = [HYGenerateNameTool generateName:TypeName from:nil typeName:nil cache:true globalClassPrefix:@""];
        NSLog(@"正在生成垃圾代码文件：%@", className);
        className = [className stringByAppendingString:[self genRandomSuffix]];
        NSArray * firstParamsArray = [self genParamArray:(arc4random() % 3) + 2];
        NSArray * secondParamsArray = [self genParamArray:(arc4random() % 3) + 2];
        NSString * retFuncName = [HYGenerateNameTool generateName:ArgName from:nil typeName:nil cache:false globalClassPrefix:@""];
        NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                                   firstParamsArray, @"firstMethodParams",
                                   secondParamsArray, @"secondMethodParams",
                                   className, @"ClassName",
                                   retFuncName ,@"returnCallfunc",
                                   nil];
        NSString *resultH = [engine processTemplateInFileAtPath:templatePath_h withVariables:variables];
        NSString *resultM = [engine processTemplateInFileAtPath:templatePath_m withVariables:variables];
        
        NSString *deskTopLocation = outputFolder;
        NSString *pathH = [deskTopLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.h", className]];
        NSString *pathM = [deskTopLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.m", className]];
        BOOL isSuccessH = [resultH writeToFile:pathH atomically:YES encoding:NSUTF8StringEncoding error:nil];
        BOOL isSuccessM = [resultM writeToFile:pathM atomically:YES encoding:NSUTF8StringEncoding error:nil];
//        NSLog(@"%@:%@", isSuccessH ? @"success" : @"fail" , pathH);
//        NSLog(@"%@:%@", isSuccessM ? @"success" : @"fail" , pathM);
        if(isSuccessH && isSuccessM)
        {
            [classSet addObject:className];
        }
    }
    [self generateImport:classSet outputFolder:outputFolder];
    return classSet;
}


+(void)generateImport : (NSMutableSet *) classSet outputFolder : (NSString *) outputFolder{
    NSString *className = [HYGenerateNameTool generateName:TypeName from:nil typeName:nil cache:true globalClassPrefix:@""];
    NSLog(@"正在生成垃圾代码文件：%@", className);
    className = [className stringByAppendingString:[self genRandomSuffix]];
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    
    NSString *templatePath_h = [[NSBundle mainBundle] pathForResource:@"File/CodeGenerator/CodeFileTemplate/ImportClass_h" ofType:@"txt"];
    NSString *templatePath_m = [[NSBundle mainBundle] pathForResource:@"File/CodeGenerator/CodeFileTemplate/ImportClass_m" ofType:@"txt"];
    NSArray *nameArray = [classSet allObjects];
    NSMutableArray *nameMutableArray = [NSMutableArray new];
    for (NSString * param in nameArray) {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:param, @"key", @"NSString", @"value", nil];
        [nameMutableArray addObject:dic];
    }
    NSDictionary *variable = [NSDictionary dictionaryWithObjectsAndKeys:
                              nameMutableArray, @"ClassName",
                              className, @"ImportClass",
                              nil];
    
    NSString *resultH = [engine processTemplateInFileAtPath:templatePath_h withVariables:variable];
    NSString *resultM = [engine processTemplateInFileAtPath:templatePath_m withVariables:variable];
    
    NSString *deskTopLocation = outputFolder;
    NSString *pathH = [deskTopLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.h", @"HYImportClass"]];
    NSString *pathM = [deskTopLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.m", @"HYImportClass"]];
    BOOL isSuccessH = [resultH writeToFile:pathH atomically:YES encoding:NSUTF8StringEncoding error:nil];
    BOOL isSuccessM = [resultM writeToFile:pathM atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    NSLog(@"%@:%@", isSuccessH ? @"success" : @"fail" , pathH);
//    NSLog(@"%@:%@", isSuccessM ? @"success" : @"fail" , pathM);
    if(isSuccessH && isSuccessM)
    {
        [classSet addObject:@"HYImportClass"];
    }
}

+ (NSString *) genRandomSuffix
{
    NSString *sourceStr = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    int kNumber = rand() % 2 + 1;
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

+ (NSMutableArray*) genParamArray : (int) paramsNumber
{
    NSMutableArray * paramsArray = [NSMutableArray new];
    for (int i = 0; i < paramsNumber; i ++) {
        NSString *param;
        if( i > 0) {
            param = [HYGenerateNameTool generateName:ArgName from:nil typeName:nil cache:false globalClassPrefix:@""];
        } else {
            param = [HYGenerateNameTool generateName:FuncName from:nil typeName:nil cache:false globalClassPrefix:@""];
        }
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:param, @"key", @"NSString", @"value", nil];
        [paramsArray addObject:dic];
    }
    return paramsArray;
}



@end
