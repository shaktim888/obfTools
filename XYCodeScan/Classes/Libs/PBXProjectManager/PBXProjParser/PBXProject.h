//
//  PBXProject.h
//  PBXProjectManager
//
//  Created by lujh on 2019/2/14.
//  Copyright © 2019 lujh. All rights reserved.
//

#import "PBXObject.h"

@class PBXGroup;
@class XCConfigurationList;
@class PBXTarget;

NS_ASSUME_NONNULL_BEGIN

@interface PBXProject : PBXObject

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString*> * pathMap;
@property (nonatomic, strong) NSMutableArray<PBXTarget *> *targets;

-(NSArray*) getAllFolder;

- (NSString*) getFilePath:(PBXObject *) obj;
- (NSString*) getFilePathById:(NSString *) objId;

@property (nonatomic, strong) PBXGroup *mainGroup;

@property (nonatomic, strong) PBXGroup *productRefGroup;

@property (nonatomic, strong) XCConfigurationList *buildConfigurationList;

- (PBXTarget *) getTargetByName: (NSString*) name;
- (PBXTarget *) getMobileTarget;

@end

NS_ASSUME_NONNULL_END
