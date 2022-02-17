//
//  ClangSourceOperator.h
//  HYCodeScan
//
//  Created by admin on 2020/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClangSourceOperator : NSObject

- (void) insert : (NSString*) file offset : (int) offset code :(NSString *) code;
- (void) replace : (NSString *) file range : (NSRange) range code: (NSString*) code;

@end

NS_ASSUME_NONNULL_END
