//
//  XCConfigurationList.m
//  PBXProjectManager
//
//  Created by lujh on 2019/2/15.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "XCConfigurationList.h"

#import "XCBuildConfiguration.h"

#import "PBXObjects.h"

#import "PBXProjParser.h"

@interface XCConfigurationList ()
{
    NSString* _defaultConfigurationName;
}

@property (nonatomic, strong) NSMutableDictionary *buildConfigs;

@end

@implementation XCConfigurationList

- (instancetype)initWithObjectId:(PBXProjParser*)parser objId:(NSString *)objId data:(NSDictionary *)data
{
    if (self = [super initWithObjectId:parser objId:objId data:data])
    {
        self.buildConfigurations = [[NSMutableArray alloc] init];
        
        NSArray *buildConfigIds = self.data[@"buildConfigurations"];
        
        for (NSString *confId in buildConfigIds)
        {
            XCBuildConfiguration *buildConfig = [[XCBuildConfiguration alloc] initWithObjectId:parser objId:confId data:parser.objects.data[confId]];
            
            [self.buildConfigurations addObject:buildConfig];
        }
        _defaultConfigurationName = self.data[@"defaultConfigurationName"];
    }
    return self;
}

// 获取编译配置
- (XCBuildConfiguration *)getBuildConfigs:(NSString *)scheme
{
    if (!self.buildConfigs[scheme])
    {
        for (XCBuildConfiguration *buildConfigs in self.buildConfigurations)
        {
            if ([[buildConfigs getName] isEqualToString:scheme])
            {
                self.buildConfigs[scheme] = buildConfigs;
                break;
            }
        }
    }
    return self.buildConfigs[scheme];
}

- (XCBuildConfiguration *)defaultConfiguration
{
    return [self getBuildConfigs:_defaultConfigurationName];
}

// 获取编译配置
- (id)getBuildSetting:(NSString *)scheme name:(NSString *)name
{
    return [[self getBuildConfigs:scheme] getBuildSetting:name];
}

// 设置编译配置
- (void)setBuildSetting:(NSString *)scheme name:(NSString *)name value:(id)value
{
    [[self getBuildConfigs:scheme] setBuildSetting:name settingValue:value];
}

// 设置所有的配置
- (void)setAllBuildSetting:(NSString *)name value:(id)value
{
    // 同步所有的scheme
    for (XCBuildConfiguration *buildConfigs in self.buildConfigurations)
    {
        if (!self.buildConfigs[[buildConfigs getName]])
        {
            self.buildConfigs[[buildConfigs getName]] = buildConfigs;
        }
    }
    
    for(NSString * scheme in self.buildConfigs) {
        [self.buildConfigs[scheme] setBuildSetting:name settingValue:value];
    }
}

- (NSMutableDictionary *)buildConfigs
{
    if (!_buildConfigs)
    {
        _buildConfigs = [[NSMutableDictionary alloc] init];
        for (XCBuildConfiguration *buildConfigs in self.buildConfigurations)
        {
            _buildConfigs[[buildConfigs getName]] = buildConfigs;
        }
    }
    return _buildConfigs;
}

- (NSDictionary<NSString *, XCBuildConfiguration *> *)getAllBuildConfigs {
    return self.buildConfigs;
}

@end
