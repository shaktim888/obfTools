//
//  PBXBuildFile.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXBuildFile.h"

#import "PBXProjParser.h"

#import "PBXObjects.h"

@implementation PBXBuildFile

- (instancetype)initWithObjectId:(PBXProjParser*)parser objId:(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        NSString *fileRefId = self.data[@"fileRef"];
        _fileRef = [[PBXFileReference alloc] initWithObjectId:parser objId:fileRefId data:parser.objects.data[fileRefId]];
        _setting = self.data[@"setting"];
    }
    return self;
}

-(NSArray*) getCompileFlag {
    if(_setting) {
        id data = _setting[@"COMPILER_FLAGS"];
        if([data isKindOfClass:NSString.class]) {
            return @[data];
        } else {
            return data;
        }
    }
    return nil;
}
@end
