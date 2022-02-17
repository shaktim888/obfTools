//
//  PBXProjParser.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/13.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXProjParser.h"

@interface PBXProjParser ()


@end

@implementation PBXProjParser

//+ (instancetype)sharedInstance
//{
//    static id instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        instance = [[self alloc] init];
//    });
//    return instance;
//}

- (instancetype) init {
    self = [super init];
    if (self) {
        self.remoteIDS = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)setPbxprojPath:(NSString *)pbxprojPath
{
    [self parseProjectWithPath:pbxprojPath];
}

- (void)parseProjectWithPath:(NSString *)projPath
{
    [_remoteIDS removeAllObjects];
    projPath = [projPath stringByStandardizingPath];
    //检验projPath格式是否正确，如果是.xcodeproj后缀则拼接上 @"/project.pbxproj"
    if ([projPath.pathExtension isEqualToString:@"xcodeproj"])
    {
        projPath = [projPath stringByAppendingPathComponent:@"project.pbxproj"];
    }
    
    NSError *error = nil;
    NSData *projData = [NSData dataWithContentsOfFile:projPath];
    if(!projData) return;
    // 将 project.pbxproj 格式转换成字典格式 __NSCFDictionary 为 NSMutableDictionary的子类
    NSDictionary *projectDict = [NSPropertyListSerialization propertyListWithData:projData options:NSPropertyListMutableContainersAndLeaves format:nil error:&error];
    
    if (!error)
    {
        NSLog(@"读取project.pbxproj成功");
        
        _pbxprojPath = projPath;
        // 解析 project 字典
        self.pbxprojDictionary = projectDict;
        
        self.rawDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:projectDict]];
        
        // objects
        self.objects = [[PBXObjects alloc] initWithObjectId:self objId:@"objects" data:projectDict[@"objects"]];
        for(NSDictionary * item in self.objects.rawData.allValues) {
            
            if ([item isKindOfClass:[NSDictionary class]])
            {
                if(item[@"remoteRef"]) {
                    [_remoteIDS addObject:item[@"remoteRef"]];
                }
                
                if(item[@"remoteGlobalIDString"]) {
                    [_remoteIDS addObject:item[@"remoteGlobalIDString"]];
                }
                
                if(item[@"productReference"]) {
                    [_remoteIDS addObject:item[@"productReference"]];
                }
            }
            
        }
        // 将 rootObject 的值作为 Key 在 objects 对应的字典中找到根对象 rootObject
        NSString *rootObjectId = projectDict[@"rootObject"];
        
        self.project = [self.objects createPBXProjectWithRootObjectId:self rootObjectId:rootObjectId data:self.objects.data[rootObjectId]];
    }
    else
    {
        NSLog(@"pbxproj无法解析！！");
        self.project = nil;
        self.pbxprojDictionary = nil;
        _pbxprojPath = nil;
        return;
    }
}

- (NSData *)_fixEncodingInData:(NSData *)data
{
    NSString *source = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableString *destination = @"".mutableCopy;
    for(int i = 0; i < source.length; i++) {
        unichar c = [source characterAtIndex:i];
        if(c < 128) {
            [destination appendFormat:@"%c", c];
        } else {
            [destination appendFormat:@"&#%u;", c];
        }
    }
    
    return [destination dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) save:(NSString *) path
{
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:[self pbxprojDictionary] format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListMutableContainersAndLeaves error:NULL];
    data = [self _fixEncodingInData:data];
    if(![path.pathExtension isEqualToString:@"pbxproj"])
    {
        path = [path stringByAppendingPathComponent:@"project.pbxproj"];
    }
    [data writeToFile:path atomically:true];
}

- (NSString*) formatPath:(NSString*) p
{
    NSString * root = [self getProjFolder];
    p = [p stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
    p = [p stringByReplacingOccurrencesOfString:@"$(PROJECT_DIR)" withString:root];
    if(![p hasPrefix:@"/"]) {
        p = [root stringByAppendingPathComponent:p];
    }
    p = [p stringByStandardizingPath];
    return p;
}

- (NSString *)getProjFolder
{
    return [[_pbxprojPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
}

@end
