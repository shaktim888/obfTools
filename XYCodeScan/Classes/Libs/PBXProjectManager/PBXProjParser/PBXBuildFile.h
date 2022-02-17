//
//  PBXBuildFile.h
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXObject.h"

#import "PBXFileReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBXBuildFile : PBXObject

@property (nonatomic, strong) PBXFileReference *fileRef;

@property (nonatomic, strong) NSDictionary * setting;

-(NSArray*) getCompileFlag;

@end

NS_ASSUME_NONNULL_END
