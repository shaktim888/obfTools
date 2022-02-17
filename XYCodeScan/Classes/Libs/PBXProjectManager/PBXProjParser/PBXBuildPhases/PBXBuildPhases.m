//
//  PBXBuildPhases.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXBuildPhases.h"

#import "PBXBuildFile.h"

#import "PBXProjParser.h"

#import "PBXObjects.h"

@interface PBXBuildPhases ()


@end

@implementation PBXBuildPhases

- (instancetype)initWithObjectId:(PBXProjParser*)parser objId:(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        _files = [[NSMutableArray alloc] init];
        for (NSString *fileId in self.data[@"files"])
        {
            [_files addObject:[[PBXBuildFile alloc] initWithObjectId:parser objId:fileId data:parser.objects.data[fileId]]];
        }
    }
    return self;
}

- (void)addBuildFile:(PBXNavigatorItem *)fileRef
{
    if (!fileRef)
    {
        NSLog(@"addBuildFile error: fileRef is nil");
        return;
    }
    
    BOOL hasExists = NO;
    for (PBXBuildFile *buildFile in self.files)
    {
        if ([buildFile.fileRef.objectId isEqualToString:fileRef.objectId])
        {
            hasExists = YES;
            break;
        }
    }
    
    if (!hasExists)
    {
        NSMutableDictionary *buildFileInfo = [[NSMutableDictionary alloc] init];
        buildFileInfo[@"isa"] = @"PBXBuildFile";
        buildFileInfo[@"fileRef"] = fileRef.objectId;
        
        PBXBuildFile *buildFile = [[PBXBuildFile alloc] initWithObjectId:_parser objId:[self genObjectId] data:buildFileInfo];
        
        [self.files addObject:buildFile];
        [self.data[@"files"] addObject:buildFile.objectId];
        
        [_parser.objects setObject:buildFile];
    }
}

- (void)removeBuildFile:(PBXNavigatorItem *)fileRef
{
    NSMutableArray *needsDelBuildFiles = [[NSMutableArray alloc] init];
    for (PBXBuildFile *buildFile in self.files)
    {
        if ([buildFile.fileRef.objectId isEqualToString:fileRef.objectId])
        {
            [needsDelBuildFiles addObject:buildFile];
        }
    }
    
    for (PBXBuildFile *buildFile in needsDelBuildFiles)
    {
        [self.files removeObject:buildFile];
        [self.data[@"files"] removeObject:buildFile.objectId];
        
        [_parser.objects deleteObject:buildFile];
    }
}

- (NSString *)getBuildActionMask
{
    return self.data[@"buildActionMask"];
}

- (void)setBuildActionMask:(NSString *)buildActionMask
{
    self.data[@"buildActionMask"] = buildActionMask;
}

@end
