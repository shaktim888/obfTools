//
//  GEN_lua.h
//  HYCodeScan
//
//  Created by admin on 2020/6/2.
//  Copyright © 2020 Admin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GEN_lua : NSObject
+ (instancetype)sharedInstance;
- (void) enterBlock;
- (void) exitBlock;
- (NSString*) genOneCode;
- (void) clean;
@end

NS_ASSUME_NONNULL_END
