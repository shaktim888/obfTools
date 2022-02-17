//
//  ClangCustomBlock.h
//  HYCodeScan
//
//  Created by admin on 2020/7/24.
//

#import "ClangBlock.h"

NS_ASSUME_NONNULL_BEGIN

@interface ClangCustomBlock : ClangBlock

@property (nonatomic, copy) NSString * codeBefore;
@property (nonatomic, copy) NSString * codeAfter;

@end

NS_ASSUME_NONNULL_END
