//
//  XcodeTools.h
//  HYCodeScan
//
//  Created by admin on 2020/7/10.
//

#import <Foundation/Foundation.h>
#import "PBXProjectManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface XcodeTools : NSObject

+ (NSString *) genObjectId;
+ (void) deepModifyChildProjectConfig: (PBXGroup *) group root:(NSString *) root pPath:(NSString *) pPath func : (void(^)(PBXProject *, NSString*)) func needSave:(BOOL) needSave;
+ (bool) deepForEachXcodeGroup:(bool) needFilter group:(PBXGroup *)group extensions:(NSArray *) extensions root:(NSString *) root pPath:(NSString *) pPath func:(void(^)(NSString*))func findOne:(bool)findOne;
+ (void) deepForEachWithFileTypeInXcode:(bool) needFilter group:(PBXGroup *) group root:(NSString *) root pPath:(NSString *) pPath fileTypes:(NSArray *) fileTypes func:(void(^)(NSString*, NSString*)) func;
+ (NSArray *) scanXibFile : (nullable NSString *) parentName dict:(id) dict arr:(NSMutableArray *) arr;
+ (void) addPchFile : (NSString*) dir project:(PBXProject *) project targets : (NSArray*) targets;
+ (void) obfXcodeprojUDID : (NSString*) path isTopProj: (BOOL) isTop;
+ (void) setKiwiObf : (PBXProject*) project targets : (NSArray*) targets;
+ (void) addFileRedefineToTarget : (nullable PBXProject*) project targets : (nullable NSArray*) targets;
+ (void) addFileToTarget : (NSString*) file project: (PBXProject*) project group :(PBXGroup*) group targets : (NSArray*) targets;
+ (void) replaceConfigInnerConfigPath : (XCBuildConfiguration*) config root:(NSString *) root key:(NSString *) key dict:(NSDictionary *) dict;
+ (void) reNameProjectGroup :(NSString *) projectPath;
@end

NS_ASSUME_NONNULL_END
