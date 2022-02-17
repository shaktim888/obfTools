//
//  ClangBlockMgr.h
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClangBlockMgr : NSObject

+ (instancetype)sharedInstance;

- (Class) getClassByKind : (int) kind;

@end

NS_ASSUME_NONNULL_END
