//
//  ClangBlock.h
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import <Foundation/Foundation.h>
#import "clang-c/Index.h"
#import "ClangLine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ClangBlock : ClangLine
{
    __weak ClangLine * firstChild;
    __weak ClangLine * lastChild;
}

@property (nonatomic, strong) NSMutableArray<ClangLine*> * childs;

- (enum CXChildVisitResult) enterBlock:(CXCursor) c parent: (CXCursor) parent;
- (NSString*)updateContent;

- (bool) isCanObf;
- (bool) childBlockCanInsertCode;

- (NSString *) getBeforeCode;
- (NSString *) getAfterCode;

- (void) obfStart : (DFModelBuilder*) modelBuilder;
- (void) obfEnd : (DFModelBuilder*) modelBuilder;
@end

NS_ASSUME_NONNULL_END
