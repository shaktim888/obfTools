#import <Foundation/Foundation.h>
#import "ResGenerator.h"
#import "CodeGenerator.h"
#import "UserConfig.h"
#import "HYGenerateNameTool.h"
#import "CodeGenerator.h"
#import "mmd5.h"

enum RubbishFileType {
    Rubbish_JS,
    Rubbish_Lua,
    Rubbish_Image,
    Rubbish_TFT,
    Rubbish_Text,
};

@implementation ResGenerator

+ (NSString *) genString : (int) size
{
    NSMutableString * ret = [NSMutableString string];
    int i = size / 5;
    while(i > 0) {
        int j = 5;
        while(j > 0) {
            [ret appendString:[HYGenerateNameTool generateName:WordName from:nil typeName:nil cache:false globalClassPrefix:@""]];
            [ret appendString:@" "];
            j--;
        }
        i--;
        if(i > 0) {
            [ret appendString:@","];
        }
    }
    return ret;
}

+ (NSString *) base64String: (NSString *) string {
    //1、先转换成二进制数据
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    //2、对二进制数据进行base64编码，完成后返回字符串
    return [data base64EncodedStringWithOptions:0];
}

+ (void) genFile : (NSString*) folder  num:(int) num type : (NSString*) type
{
    if([type isEqualToString:@"lua"]) {
        genClassToFolder(Gen_Lua, num, [folder UTF8String]);
    } else if([type isEqualToString:@"js"]) {
        genClassToFolder(Gen_Js, num, [folder UTF8String]);
    } else {
        for(int i = 0;i < num; i++) {
            NSString * path;
            NSString * fileName = [HYGenerateNameTool generateName:ResName from:nil typeName:nil cache:false globalClassPrefix:@""];
            path = [folder stringByAppendingPathComponent:[fileName stringByAppendingFormat:@".%@", type]];
            if([type isEqualToString:@"jpg"]) {
                [mmd5 genAJpgPic:path];
            } else if([type isEqualToString:@"png"]) {
                [mmd5 genAPngPic:path];
            } else {
                NSString * str = [self base64String: [self genString:arc4random() % 1000 + 100]];
                [str writeToFile:path atomically:true encoding:NSUTF8StringEncoding error:nil];
            }
        }
    }
}

+ (NSArray*) genRubishType : (int) count
{
    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:@[@"png",@"jpg",@"ini",@"tft",@"mp3",@"txt"]];
    if([UserConfig sharedInstance].genjs) {
        [arr addObject:@"js"];
    }
    if([UserConfig sharedInstance].genlua) {
        [arr addObject:@"lua"];
    }
    NSMutableArray * ret = [[NSMutableArray alloc] init];
    for(int i = 0; i < count; i++) {
        int pos = arc4random() % (arr.count - i);
        NSString * temp = [arr objectAtIndex:pos];
        [ret addObject: temp];
        [arr replaceObjectAtIndex:pos withObject:[arr objectAtIndex:arr.count - i - 1]];
        [arr replaceObjectAtIndex:arr.count - i - 1 withObject:temp];
    }
    return ret;
}

+ (void)genRubishFile:(NSString *)folder typeNum:(int)typeNum minNum:(int) minNum maxNum:(int)maxNum
{
    folder = [folder stringByStandardizingPath];
    NSArray * types = [self genRubishType:typeNum];
    for(NSString * typeName in types) {
        [self genFile: folder num : minNum + arc4random() % (maxNum - minNum) type:typeName];
    }
}

@end
