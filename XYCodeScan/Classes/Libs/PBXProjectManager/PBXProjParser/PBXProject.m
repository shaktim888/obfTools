//
//  PBXProject.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXProject.h"

#import "PBXNativeTarget.h"

#import "PBXAggregateTarget.h"

#import "PBXGroup.h"

#import "XCConfigurationList.h"

#import "PBXObjects.h"

#import "PBXProjParser.h"

#import "PBXTargetDependency.h"

@interface PBXProject ()
{
    NSMutableArray * _folders;
}
@end

@implementation PBXProject

- (instancetype)initWithObjectId:(PBXProjParser*)parser objId:(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        _pathMap = [[NSMutableDictionary alloc] init];
        _folders = [[NSMutableArray alloc]init];
        [self _parseProjectWithObjectId:objId data:data];
    }
    return self;
}

- (void)_parseProjectWithObjectId:(NSString *)objId data:(NSDictionary *)data
{
    _parser.project = self;
    // objects
    NSDictionary *objects = _parser.objects.data;

    // targets
    NSArray *targetIds = data[@"targets"];
    
    self.targets = [[NSMutableArray alloc] init];
    
    for (NSString *targetId in targetIds)
    {
        PBXTarget *target = [self _createTarget:targetId];
        [self.targets addObject:target];
    }
    for(PBXTarget * target in self.targets) {
        [target buildDeps];
    }
    
    // mainGroup
    NSString *mainGroupId = data[@"mainGroup"];
    self.mainGroup = [[PBXGroup alloc] initWithObjectId:_parser objId:mainGroupId data:objects[mainGroupId]];
    
    // product ref group
    NSString *productRefGroupId = data[@"productRefGroup"];
    self.productRefGroup = [[PBXGroup alloc] initWithObjectId:_parser objId:productRefGroupId data:objects[productRefGroupId]];
    
    // buildConfigurationList
    NSString *configListId = data[@"buildConfigurationList"];
    self.buildConfigurationList = [[XCConfigurationList alloc] initWithObjectId:_parser objId:configListId data:objects[configListId]];
    
    [self buildAllPath];
}

- (PBXTarget *)_createTarget:(NSString *)targetId
{
    if (targetId && targetId.length > 0)
    {
        NSDictionary *obj = _parser.objects.data[targetId];
        NSString *isa = obj[@"isa"];
        
        if ([isa isEqualToString:@"PBXNativeTarget"])
        {
            NSDictionary *targetAttrs = self.data[@"attributes"][@"TargetAttributes"][targetId];
            
            return [[PBXNativeTarget alloc] initWithObjectId:_parser objId:targetId data:obj targetAttrs:targetAttrs];
        }
        else if ([isa isEqualToString:@"PBXAggregateTarget"])
        {
            return [[PBXAggregateTarget alloc] initWithObjectId:_parser objId:targetId data:obj];
        }
        NSLog(@"这里出错了");
    }
    return nil;
}

- (PBXTarget *) getTargetByName: (NSString*) name
{
    for(PBXTarget* target in self.targets) {
        if([[target getName] isEqualToString:name]) {
            return target;
        }
    }
    return nil;
}

- (PBXTarget *) getMobileTarget {
    NSMutableSet * collect = [[NSMutableSet alloc] init];
    
    for(PBXTarget* target in self.targets) {
        NSArray * deps = [target dependencies];
        for(PBXTargetDependency * dep in deps) {
            [collect addObject:dep.target];
        }
    }
    
    for(PBXTarget* target in self.targets) {
        if([collect containsObject:target]) {
            continue;
        }
        
        id platforms = [target getBuildSetting:@"Release" name:@"SDKROOT"];
        if([platforms isKindOfClass:NSString.class] && [platforms containsString:@"iphoneos"]) {
            return target;
        }
        if([platforms isKindOfClass:NSArray.class]) {
            if([[platforms componentsJoinedByString:@" "] containsString:@"iphoneos"]) {
                return target;
            }
        }
    }
    return nil;
}

- (void) buildAllPath {
    [_pathMap removeAllObjects];
    void(^__block solvePath)(PBXGroup * group, NSString * root, NSString * curPath) = ^(PBXGroup * group, NSString * root, NSString * curPath){
        for(PBXNavigatorItem * item in group.children) {
            NSString * p = [item getPath];
            if(![p hasPrefix:@"/"])
            {
                NSString * st = [item getSourceTree];
                if([st isEqualToString:PBXSourceTree_GROUP]){
                    p = [curPath stringByAppendingPathComponent:p];
                }
                else if([st isEqualToString:PBXSourceTree_ROOT]) {
                    p = [root stringByAppendingPathComponent:p];
                } else {
                    p = [NSString stringWithFormat:@"$(%@)/%@", st, p];
                }
            }
            p = [self->_parser formatPath:p];
            [self.pathMap setObject:p forKey:item.objectId];
            if([item isKindOfClass:[PBXGroup class]])
            {
                [self->_folders addObject:p];
                solvePath((PBXGroup*)item, root, p);
            }
        }
    };
    NSString * dir = [[_parser.pbxprojPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    solvePath(self.mainGroup, dir, dir);
}

- (NSString*) getFilePath:(PBXObject *) obj
{
    return _pathMap[obj.objectId];
}

- (NSString*) getFilePathById:(NSString *) objId
{
    return _pathMap[objId];
}

-(NSArray*) getAllFolder
{
    return _folders;
}

@end
