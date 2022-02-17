//
//  ClangCustomBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/24.
//

#import "ClangCustomBlock.h"

@implementation ClangCustomBlock

- (NSString*)updateContent
{
    NSMutableString * code = [NSMutableString string];
    [code appendString:self.codeBefore];
    for(ClangLine * line in self.childs) {
        if([line isKindOfClass:ClangBlock.class]) {
            [code appendFormat:@"%@\n", [line updateContent]];
        } else {
            [code appendString:[line updateContent]];
        }
    }
    [code appendFormat:@"%@", self.codeAfter];
    return code;
}

@end
