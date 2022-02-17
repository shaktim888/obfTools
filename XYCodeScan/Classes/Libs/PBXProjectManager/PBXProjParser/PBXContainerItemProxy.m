//
//  PBXContainerItemProxy.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXContainerItemProxy.h"

#import "PBXProjParser.h"
#import "PBXProject.h"

@implementation PBXContainerItemProxy

- (instancetype)initWithObjectId:(PBXProjParser*)parser :(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        // containerPortal
//        PBXProjParser* parser = [PBXProjParser sharedInstance];
        if ([parser.project.objectId isEqualToString:self.data[@"containerPortal"]])
        {
            self.containerPortal = parser.project;
        }
        // proxyType
        self.proxyType = self.data[@"proxyType"];
        
        // remoteInfo
        self.remoteInfo = self.data[@"remoteInfo"];
        
        // remoteGlobalIDString
        self.remoteGlobalIDString = self.data[@"remoteGlobalIDString"];
    }
    return self;
}

@end
