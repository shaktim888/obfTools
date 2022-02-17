//
//  ClangFunctionBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangOCMethodBlock.h"
#import "JunkCodeClientData.h"
#include "XCodeFactory.hpp"

@implementation ClangOCMethodBlock

-(NSString*) getMethodDeclare {
    // 当前节点的内容描述
    int endset = _endOffset;
    if(firstChild) {
        endset = firstChild.preOffset;
    }
    NSData* cont = [_context.fileData subdataWithRange:NSMakeRange(_startOffset, endset - _startOffset)];
    NSString* declString = [[NSString alloc] initWithData:cont encoding:NSUTF8StringEncoding];
    return declString;
}

-(void) onExit
{
    CXCursor from = clang_getCursorSemanticParent(_cursor);
    
    CXType tt = clang_getCursorType(from);
    CXCursor from2 = clang_getTypeDeclaration(tt);
    NSString * ct = [self getMethodDeclare];
    int num = clang_Cursor_getNumArguments(_cursor);
    for(int i = 0 ; i < num ; i++ ) {
        clang_Cursor_getArgument(_cursor, i);
    }          
}

- (hygen::CodeMode) getCodeMode {
    return hygen::CodeMode_OC;
}

@end
