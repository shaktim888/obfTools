//
//  PBXTarget.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXTarget.h"

#import "XCConfigurationList.h"
#import "PBXTargetDependency.h"

#import "PBXSourcesBuildPhase.h"
#import "PBXFrameworksBuildPhase.h"
#import "PBXResourcesBuildPhase.h"
#import "PBXShellScriptBuildPhase.h"

#import "XCBuildConfiguration.h"

#import "PBXObjects.h"

#import "PBXProjParser.h"

@implementation PBXTarget

- (instancetype)initWithObjectId:(PBXProjParser*)parser objId:(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        NSArray *buildPhasesIds = self.data[@"buildPhases"];
        self.buildPhases = [[NSMutableArray alloc] init];
        for (NSString *buildPhasesId in buildPhasesIds)
        {
            NSDictionary *buildPhases = parser.objects.data[buildPhasesId];
            NSString *buildPhasesType = buildPhases[@"isa"];
            
            PBXBuildPhases *buildPhaseObj = nil;
            
            if ([buildPhasesType isEqualToString:@"PBXSourcesBuildPhase"])
            {
                self.sourcesBuildPhase = [[PBXSourcesBuildPhase alloc] initWithObjectId:parser objId:buildPhasesId data:buildPhases];
                buildPhaseObj = self.sourcesBuildPhase;
            }
            else if ([buildPhasesType isEqualToString:@"PBXFrameworksBuildPhase"])
            {
                self.frameworkBuildPhase = [[PBXFrameworksBuildPhase alloc] initWithObjectId:parser objId:buildPhasesId data:buildPhases];
                buildPhaseObj = self.frameworkBuildPhase;
            }
            else if ([buildPhasesType isEqualToString:@"PBXResourcesBuildPhase"])
            {
                self.resourceBuildPhase = [[PBXResourcesBuildPhase alloc] initWithObjectId:parser objId:buildPhasesId data:buildPhases];
                buildPhaseObj = self.resourceBuildPhase;
            }
            else if ([buildPhasesType isEqualToString:@"PBXShellScriptBuildPhase"])
            {
                buildPhaseObj = [[PBXShellScriptBuildPhase alloc] initWithObjectId:parser objId:buildPhasesId data:buildPhases];
            }
            else
            {
                buildPhaseObj = [[PBXBuildPhases alloc] initWithObjectId:parser objId:buildPhasesId data:buildPhases];
            }
            [self.buildPhases addObject:buildPhaseObj];
        }

        NSString *configListId = self.data[@"buildConfigurationList"];
        self.buildConfigurationList = [[XCConfigurationList alloc] initWithObjectId:parser objId:configListId data:parser.objects.data[configListId]];

    }
    return self;
}

- (void)buildDeps
{
    NSArray *dependencyIds = self.data[@"dependencies"];
    self.dependencies = [[NSMutableArray alloc] init];
    for (NSString *dependencyId in dependencyIds)
    {
        NSDictionary *dependency = _parser.objects.data[dependencyId];
        NSString *dependencyISA = dependency[@"isa"];
        if ([dependencyISA isEqualToString:@"PBXTargetDependency"])
        {
            [self.dependencies addObject:[[PBXTargetDependency alloc] initWithObjectId:_parser objId:dependencyId data:dependency]];
        }
    }
}

// 获取Target名字
- (NSString *)getName
{
    return self.data[@"name"];
}

// 获取编译配置
- (id)getBuildSetting:(NSString *)scheme name:(NSString *)name {
    id info = [self.buildConfigurationList getBuildSetting:scheme name:name];
    if(info == nil) {
        return [_parser.project.buildConfigurationList getBuildSetting:scheme name:name];
    }
    else {
        if([info isKindOfClass:(NSString.class)]) {
            if([info containsString:@"inherited"]) {
                return [_parser.project.buildConfigurationList getBuildSetting:scheme name:name];
            }
        } else if([info isKindOfClass:NSArray.class]){
            bool isInherited = false;
            for(NSString* item in info) {
                if([item containsString:@"inherited"]) {
                    isInherited = true;
                }
            }
            if(isInherited) {
                NSMutableArray * arr = [info mutableCopy];
                id parentInfo = [_parser.project.buildConfigurationList getBuildSetting:scheme name:name];
                if([parentInfo isKindOfClass:(NSString.class)]) {
                    [arr addObject:parentInfo];
                } else {
                    [arr addObjectsFromArray:parentInfo];
                }
                return arr;
            }
        }
    }
    return info;
}

// 设置Target名字
- (void)setName:(NSString *)name
{
    self.data[@"name"] = name;
}

// 获取产品名称
- (NSString *)getProductName
{
    return self.data[@"productName"];
}

// 设置产品名称
- (void)setProductName:(NSString *)productName
{
    self.data[@"productName"] = productName;
}

/**
 添加Shell脚本编译设置
 
 @param shellScript shell 脚本
 @param path shell路径，传nil则默认"/bin/sh".
 */
- (void)addShellScriptBuildPhase:(NSString *)shellScript path:(NSString *)path
{
    if (!shellScript) return;
    
    shellScript = [shellScript stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    shellScript = [shellScript stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    NSMutableDictionary *info = [@{} mutableCopy];
    info[@"isa"] = @"PBXShellScriptBuildPhase";
    info[@"buildActionMask"] = [self.buildPhases[0] getBuildActionMask];
    info[@"files"] = [@[] mutableCopy];
    info[@"inputPaths"] = [@[] mutableCopy];
    info[@"outputPaths"] = [@[] mutableCopy];
    info[@"runOnlyForDeploymentPostprocessing"] = @"0";
    info[@"shellPath"] = path;
    info[@"shellScript"] = [NSString stringWithFormat:@"\"%@\"", shellScript];
    
    PBXShellScriptBuildPhase *buildPhase = [[PBXShellScriptBuildPhase alloc] initWithObjectId:_parser objId:[self genObjectId] data:info];
    
    [_parser.objects setObject:buildPhase];
    [self.buildPhases addObject:buildPhase];
    [self.data[@"buildPhases"] addObject:buildPhase.objectId];
}

- (NSString*) getPchFile :(NSString*) scheme {
    NSString * file = [self getBuildSetting:scheme name:@"GCC_PREFIX_HEADER"];
    if(file && ![file isEqualToString:@""])
        return [_parser formatPath:file];
    return nil;
}

- (NSArray*) getSearchPaths :(NSString*) scheme
{
    NSMutableSet * searchPaths = [[NSMutableSet alloc] init];
    NSArray * keys = @[@"SYSTEM_HEADER_SEARCH_PATHS", @"USER_HEADER_SEARCH_PATHS"];
    for(NSString * keyname in keys)
    {
        id searchPath = [self getBuildSetting:scheme name:keyname];
        if([searchPath isKindOfClass:NSString.class]) {
            [searchPaths addObject:[_parser formatPath:searchPath]];
        } else {
            for(NSString * p in searchPath) {
                [searchPaths addObject:[_parser formatPath:p]];
            }
        }
    }
    
    void(^__block solvePath)(NSString * dir)= ^(NSString * dir){
        NSDirectoryEnumerator *myDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
        BOOL isDir = NO;
        BOOL isExist = NO;
        NSArray * arr = myDirectoryEnumerator.allObjects;
        for (NSString *path in arr) {
            isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
            if (!isDir) continue;
            if([[path pathExtension] isEqualToString:@"xcodeproj"]
               || [[path pathExtension] isEqualToString:@"xcassets"]){
                continue;
            }
            [searchPaths addObject:path];
            solvePath(path);
        }
    };
    NSString * dir = [_parser getProjFolder];
    solvePath(dir);
    [searchPaths addObjectsFromArray: [_parser.project getAllFolder]];
    return [searchPaths allObjects];
}

- (NSArray *) getDefine :(NSString*) scheme
{
    NSMutableArray * arr = [NSMutableArray alloc];
    id defines = [self getBuildSetting:scheme name:@"GCC_PREPROCESSOR_DEFINITIONS"];
    if([defines isKindOfClass:NSString.class]) {
        return @[defines];
    } else {
        return defines;
    }
}

@end
