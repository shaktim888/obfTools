#import "rcg.h"
#import "CodeTokenScan.h"
#import "NSString+Extension.h"
#import "HYGenerateNameTool.h"

@implementation CodeGenerator

+(void) rcg : (NSString*) input output : (NSString*) output prop: (int) prop
{
    input = [input stringByStandardizingPath];
    if([HYGenerateNameTool isIgnoreFile:input]) return;
    output = [output stringByStandardizingPath];
    Timer_start("rcg");
    rcgCode((char*)[input UTF8String], (char*)[output UTF8String], prop);
    Timer_end("rcg");
}

+ (void)insertCode:(NSString *)input output:(NSString *)output import:(NSString *)import code:(NSString *)code {
    input = [input stringByStandardizingPath];
    if([HYGenerateNameTool isIgnoreFile:input]) return;
    output = [output stringByStandardizingPath];
    Timer_start("rcg");
    insertCode((char*)[input UTF8String], (char*)[output UTF8String], (char*)[import UTF8String], (char*)[code UTF8String]);
    Timer_end("rcg");
}

@end
