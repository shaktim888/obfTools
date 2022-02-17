//
//  JunkCodeClientData.h
//  HYCodeScan
//
//  Created by admin on 2020/7/22.
//

#import <Foundation/Foundation.h>
#import "ClangBlock.h"
#import "DFModelBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface JunkCodeClientData : NSObject

@property (nonatomic, strong) ClangBlock* rootBlock;
@property (nonatomic, strong) ClangBlock* curBlock;

@property (nonatomic, copy) NSString *file;
@property (nonatomic, strong, readonly) NSData* fileData;
@property (nonatomic, assign, readonly) NSInteger file_int_data_length;
@property (nonatomic, copy) NSString* fileContent;
@property (nonatomic, strong) NSMutableArray * stringArr;

- (instancetype) initWithFile:(NSString *) file;

- (enum CXChildVisitResult) enterCursor : (CXCursor) current parent:(CXCursor) parent;
/** 更新文本内容 */
- (NSString*)updateContent;

- (const char *) getObfMethodCall;
- (NSString *) getStringObfCode;

- (void) obfAll : (DFModelBuilder*) modelBuilder;
@end

NS_ASSUME_NONNULL_END
