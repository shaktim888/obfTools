#import <Foundation/Foundation.h>
#import "ImageTools.h"
#include "ImageSaltNoiseTools.h"
#import "NSFileManager+Extension.h"
#import "UserConfig.h"
#import "mmd5.h"

static void addSingleSaltNoice(NSString * file , NSString * outfile)
{
    float rd = (arc4random() % 10) * 1.0f / 15000.0f;
//    float rd = 0.0005;
    ImageSaltNoiseTools::solve((char*)[file UTF8String], rd, (char*)[outfile UTF8String]);
}

@implementation ImageTools

+ (void) addNoice : (NSString*) file outfile: (NSString*) outfile
{
    file = [file stringByStandardizingPath];
    outfile = [outfile stringByStandardizingPath];
    BOOL isDirectory = NO;
    bool isExist = [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
    if(isExist) {
        if(isDirectory)
        {
            NSArray * arr = [NSFileManager hy_subpathsAtPath:file extensions:@[@"png", @"jpg", @"jpeg"]];
            for(NSString * cf in arr)
            {
                addSingleSaltNoice(cf, [outfile stringByAppendingString:[cf stringByReplacingOccurrencesOfString:file withString:@""]]);
            }
        }
        else {
            addSingleSaltNoice(file, outfile);
        }
    } else {
        NSLog(@"%@ 不存在。", file);
    }
}

+ (void)pngquant:(int)speed file:(NSString *)file {
    NSLog(@"正在pngquant压缩图片：%@", file);
    NSTask *myTask = [[NSTask alloc] init];
    myTask.launchPath = @"/bin/sh";
    NSString * pngquant = [[NSBundle mainBundle] pathForResource:@"File/pngquant/pngquant" ofType:nil];

    NSMutableArray * args = [[NSMutableArray alloc] init];
    [args addObject:@" --speed"];
    
    [args addObject:@(speed)];
    [args addObject:file];
    [args addObject:@"--force"];
    [args addObject:@"--output"];
    [args addObject:file];
    NSString * cmd = [pngquant stringByAppendingString:[args componentsJoinedByString:@" "]];
    [myTask setArguments:@[@"-c", cmd]];
    [myTask launch];
    [myTask waitUntilExit];
}

+ (void)solveOneFile:(NSString *)file {
    NSLog(@"正在处理图片：%@", file);
    file = [file stringByStandardizingPath];
    switch ([UserConfig sharedInstance].imageMode) {
        case ImageSolveType::WhiteBlack:
        case ImageSolveType::Mask:
        case ImageSolveType::Mix:
        {
            addSingleSaltNoice(file, file);
            break;
        }
        case ImageSolveType::PngQuant:
        {
            [self pngquant:[UserConfig sharedInstance].pngquantSpeed file:file];
            break;
        }
        case ImageSolveType::MMD5:
        {
            [mmd5 mmd5File:file outDir:file];
            break;
        }
        default:
        {
            break;
        }
    }
}

+ (void)solveImage:(NSString *)file {
    file = [file stringByStandardizingPath];
    BOOL isDirectory = NO;
    bool isExist = [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
    if(isExist) {
        if(isDirectory)
        {
            NSArray * arr = [NSFileManager hy_subpathsAtPath:file extensions:@[@"png", @"jpg", @"jpeg"]];
            for(NSString * cf in arr)
            {
                [self solveOneFile:cf];
            }
        }
        else {
            [self solveOneFile:file];
        }
    } else {
        NSLog(@"%@ 不存在。", file);
    }
}

@end
