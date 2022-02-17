//
//  XcodeClang.h
//  HYCodeScan
//
//  Created by admin on 2020/7/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClangXcode : NSObject

+ (instancetype)sharedInstance;
- (void)obfWithXcode;

@end

NS_ASSUME_NONNULL_END
