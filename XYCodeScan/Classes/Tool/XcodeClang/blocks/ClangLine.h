//
//  ClangLine.h
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import <Foundation/Foundation.h>
#import "clang-c/Index.h"
#import "DFModelBuilder.h"

NS_ASSUME_NONNULL_BEGIN
@class ClangBlock;
@class JunkCodeClientData;

@interface ClangLine : NSObject
{
    __weak ClangBlock * _parent;
    __weak JunkCodeClientData* _context;
    CXCursor _cursor;
    unsigned _startOffset;
    unsigned _endOffset;
}

@property (nonatomic, assign) unsigned preOffset;

- (void) adapterOffset;
- (instancetype) initWithCursor:(JunkCodeClientData*) context cursor: (CXCursor) cur parent:(nullable ClangBlock * ) block;
- (unsigned) getEndOffset;
- (NSString *)updateContent;
- (NSString *) fullCode;
- (void) OBF : (DFModelBuilder*) modelBuilder;

- (void) setRealCode : (NSString*) str;

- (enum CXCursorKind) getKind;
- (void) onEnter;
- (void) onExit;

@end

NS_ASSUME_NONNULL_END
