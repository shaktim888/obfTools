//
//  PBXTargetDependency.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXTargetDependency.h"

#import "PBXProject.h"

#import "PBXObjects.h"

#import "PBXProjParser.h"

@implementation PBXTargetDependency

- (instancetype)initWithObjectId:(PBXProjParser*)parser objId :(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        // target
        PBXProjParser* instance = parser;
        NSString *targetId = self.data[@"target"];
        
        for (PBXTarget *target in instance.project.targets)
        {
            if ([target.objectId isEqualToString:targetId])
            {
                self.target = target;
                break;
            }
        }
        
        // targetProxy
        NSString *targetProxyId = self.data[@"targetProxy"];
        if(targetProxyId) {
            self.targetProxy = [[PBXContainerItemProxy alloc] initWithObjectId:parser objId:targetProxyId data:instance.objects.data[targetProxyId]];
        }
    }
    return self;
}

@end
