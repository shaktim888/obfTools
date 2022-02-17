#import <Foundation/Foundation.h>
#import "StringObf.h"
#import "HYGenerateNameTool.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

/**
 *  判断字符串中是否存在emoji
 * @param string 字符串
 * @return YES(含有表情)
 */
BOOL hasEmoji(NSString* string)
{
    NSString *pattern = @"[^\\u0020-\\u007E\\u00A0-\\u00BE\\u2E80-\\uA4CF\\uF900-\\uFAFF\\uFE30-\\uFE4F\\uFF00-\\uFFEF\\u0080-\\u009F\\u2000-\\u201f\r\n]";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isMatch = [pred evaluateWithObject:string];
    return isMatch;
}

NSString * decodeOC(char * contents, int key, BOOL hasEmoji) {
    if (contents != NULL) {
        int i = 0;
        char c = contents[i];
        while (true) {
            int v = c;
            v ^= key;
            v &= 0xff;
            if (v > 127) {
                v -= 256;
            }
            contents[i] = (char)v;
            i += 1;
            c = contents[i];
            if (v == 0) {
                break;
            }
        }
        if (hasEmoji) {
            return [NSString stringWithCString:contents encoding:NSNonLossyASCIIStringEncoding];
        }
        return [NSString stringWithUTF8String:contents];
    }
    return @"";
}

char * decodeC (char * contents, int key, bool hasEmoji) {
    if (contents != 0) {
        int i = 0;
        char c = contents[i];
        while (true) {
            int v = c;
            v ^= key;
            v &= 0xff;
            if (v > 127) {
                v -= 256;
            }
            contents[i] = (char)v;
            i += 1;
            c = contents[i];
            if (v == 0) {
                break;
            }
        }
        return contents;
    }
    return 0;
}

@implementation StringObf

NSString * _funcName = NULL;
NSString * _cfuncName = NULL;

+ (void) build
{
    if(!_funcName){
        _funcName = [HYGenerateNameTool generateByName:FuncName from:nil cache:true];
        _cfuncName = [HYGenerateNameTool generateByName:FuncName from:nil cache:true];
    }
}

+ (NSString *) getFileName
{
    return _funcName;
}

+ (void) save: (NSString *) folder
{
    NSString * content = [self genHeadFile];
    [content writeToFile:[folder stringByAppendingPathComponent:[_funcName stringByAppendingString:@".h"]] atomically:true encoding:NSUTF8StringEncoding error:nil];
    
    NSString * mContent = [self genMFile];
    [mContent writeToFile:[folder stringByAppendingPathComponent:[_funcName stringByAppendingString:@".m"]] atomically:true encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString *) getDecArr : (NSString*) str key : (int) key isEmoj : (bool) isEmoj
{
    char * sp;
    if(isEmoj)
    {
        sp = [str cStringUsingEncoding:NSNonLossyASCIIStringEncoding];
    } else {
        sp = [str UTF8String];
    }
    int len = strlen(sp);
    int rsize = arc4random() % 5;
    char * ret = malloc(sizeof(char) * (len + 1));
    memcpy(ret, sp, len);
    ret[len] = '\0';
    NSMutableString * s = [NSMutableString string];
    for(int i = 0; i <= len; i++) {
        int v = ret[i];
        v ^= key;
        v &= 0xff;
        if (v > 127) {
            v -= 256;
        }
        [s appendFormat:(i == 0 ? @"%d" : @",%d"), v];
    }
    for(int i = 0; i < rsize; i++) {
        int rv = (arc4random() % 0xff);
        if (rv > 127) {
            rv -= 256;
        }
        [s appendFormat:@",%d", rv];
    }
    return s;
}

+ (NSString *) ObfOC : (NSString*) str
{
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"File/ScanTemplate/HYEncryptStringOC" ofType:@"tpl"];
    
    int key = arc4random() % 0xFE + 1;
    bool isEmoj = hasEmoji(str);
    NSString * arr = [self getDecArr:str key:key isEmoj:isEmoj];

    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               _funcName, @"FuncName",
                               _cfuncName, @"CFuncName",
                               arr, @"data",
                               [NSString stringWithFormat:@"0x%x", key] ,@"key",
                               isEmoj ? @"true" : @"false" ,@"hasEmoji",
                               nil];
    NSString *result = [engine processTemplateInFileAtPath:templatePath withVariables:variables];
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *) ObfCPtr : (NSString*) str
{
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"File/ScanTemplate/HYEncryptStringC" ofType:@"tpl"];
    
    int key = arc4random() % 0xFE + 1;
    bool isEmoj = hasEmoji(str);
    NSString * arr = [self getDecArr:str key:key isEmoj:isEmoj];
    
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               _funcName, @"FuncName",
                               _cfuncName, @"CFuncName",
                               arr, @"data",
                               [NSString stringWithFormat:@"0x%x", key] ,@"key",
                               isEmoj ? @"1" : @"0" ,@"hasEmoji",
                               nil];
    NSString *result = [engine processTemplateInFileAtPath:templatePath withVariables:variables];
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *) importHead
{
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"File/ScanTemplate/HYEncryptStringImport" ofType:@"tpl"];
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               _funcName, @"FuncName",
                               _cfuncName, @"CFuncName",
                               nil];
    NSString *result = [engine processTemplateInFileAtPath:templatePath withVariables:variables];
    return [[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByAppendingString:@"\n"];
}

+ (NSString *) genHeadFile
{
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"File/ScanTemplate/HYEncryptStringH" ofType:@"tpl"];
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               _funcName, @"FuncName",
                               _cfuncName, @"CFuncName",
                               nil];
    NSString *result = [engine processTemplateInFileAtPath:templatePath withVariables:variables];
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *) genMFile
{
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"File/ScanTemplate/HYEncryptStringM" ofType:@"tpl"];
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               _funcName, @"FuncName",
                               _cfuncName, @"CFuncName",
                               nil];
    NSString *result = [engine processTemplateInFileAtPath:templatePath withVariables:variables];
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
