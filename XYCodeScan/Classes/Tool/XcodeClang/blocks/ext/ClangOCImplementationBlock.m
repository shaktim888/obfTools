//
//  ClangOCImplementationBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangOCImplementationBlock.h"
#import "JunkCodeClientData.h"
@interface ClangCustomProperty
{
    NSString * name;
    NSString * type;
}
@end


@implementation ClangOCImplementationBlock

- (void) adapterOffset
{
    unsigned startOffset = [self getEndOffset];
    unsigned endOffset = (unsigned)_context.file_int_data_length;
    // 当前节点的内容描述
    NSData* cont = [_context.fileData subdataWithRange:NSMakeRange(startOffset, endOffset-startOffset)];
    NSString* declString = [[NSString alloc] initWithData:cont encoding:NSUTF8StringEncoding];
    NSRange r = [declString rangeOfString:@"end"];
    _endOffset += r.location + r.length;
}

- (void) obfStart: (DFModelBuilder*) modelBuilder
{
    // 1. 添加属性
    
    
}

@end
