//
//  XCConfigurationList.h
//  PBXProjectManager
//
//  Created by lujh on 2019/2/15.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXObject.h"

@class XCBuildConfiguration;
NS_ASSUME_NONNULL_BEGIN

@interface XCConfigurationList : PBXObject

/**
 XCBuildConfiguration 的数组
 */
@property (nonatomic, strong) NSMutableArray<XCBuildConfiguration *> *buildConfigurations;

// 获取编译配置
- (XCBuildConfiguration *)getBuildConfigs:(NSString *)scheme;
- (NSDictionary<NSString *, XCBuildConfiguration *> *)getAllBuildConfigs;

// 获取编译配置
- (id)getBuildSetting:(NSString *)scheme name:(NSString *)name;

// 设置编译配置
- (void)setBuildSetting:(NSString *)scheme name:(NSString *)name value:(id)value;

- (void)setAllBuildSetting:(NSString *)name value:(id)value;

- (XCBuildConfiguration *) defaultConfiguration;
@end

NS_ASSUME_NONNULL_END
