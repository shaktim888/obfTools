#import <Foundation/Foundation.h>
#import "HYDefineRenameTool.h"
#import "HYGenerateNameTool.h"
#import "NSString+Extension.h"

@implementation HYDefineRenameTool

+(void) renameHeadFile : (NSArray<NSString*> *) fileList callback : (void (^)(NSString*)) call
{
    NSString * globalClassPrefix = @"";
    if(arc4random() % 100 <= 30) {
        int cnt = arc4random() % 3 + 1;
        globalClassPrefix = [NSString hy_randomStringWithLetters:cnt letters:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    }
    for(NSString * file in fileList)
    {
        NSMutableString *fileContent = [NSMutableString string];
        !call ? : call(file);
        NSString * textFileContents = [NSString hy_stringWithFile:file];
        NSArray *readArr = [textFileContents componentsSeparatedByString:@"\n"];
        int type = FuncName;
        for(NSString* line in readArr)
        {
            if([line containsString:@"// class begin"]) {
                type = TypeName;
            }else if([line containsString:@"// func begin"]) {
                type = FuncName;
            } else if([line containsString:@"// var begin"]) {
                type = VarName;
            } else if([line containsString:@"// arg begin"]) {
                type = ArgName;
            } else if([line containsString:@"// ignore begin"]) {
                type = Skip;
            }
            if(type == Skip)
            {
                [fileContent appendFormat:@"%@\n", line];
            }else{
                NSError *error = NULL;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*#\\s*define\\s+(\\w+)\\s+(\\w+)" options:NSRegularExpressionCaseInsensitive error:&error];
                NSTextCheckingResult *result = [regex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                if(result)
                {
                    NSString * obfuscation = [HYGenerateNameTool generateName:type from:[line substringWithRange:[result rangeAtIndex:1]] typeName:nil cache:true globalClassPrefix:globalClassPrefix];
                    [fileContent appendFormat:@"#define %@ %@\n", [line substringWithRange:[result rangeAtIndex:1]], obfuscation];
                }else{
                    [fileContent appendFormat:@"%@\n", line];
                }
            }
            
            
        }
        [fileContent writeToFile:file atomically:YES
                        encoding:NSUTF8StringEncoding error:nil];
    }
    !call ? : call(nil);
}

@end
