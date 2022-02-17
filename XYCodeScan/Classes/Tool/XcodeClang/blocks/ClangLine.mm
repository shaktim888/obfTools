//
//  ClangLine.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangLine.h"
#import "ClangBlock.h"
#import "JunkCodeClientData.h"
#include "XCodeFactory.hpp"
#import "ClangCompoundBlock.h"

@interface ClangLine()
{
    NSString * realCode;
}

@end

@implementation ClangLine

- (instancetype) initWithCursor:(JunkCodeClientData*) context cursor: (CXCursor) cur parent:(ClangBlock * ) block {
    self = [self init];
    if (self) {
        _parent = block;
        _cursor = cur;
        _context = context;
        realCode = nil;
        CXSourceRange range = clang_getCursorExtent(_cursor);
        CXSourceLocation startLocation = clang_getRangeStart(range);
        CXSourceLocation endLocation = clang_getRangeEnd(range);
        
        clang_getFileLocation(startLocation, NULL, NULL, NULL, &_startOffset);
        clang_getSpellingLocation(endLocation, NULL, NULL, NULL, &_endOffset);
        
        _preOffset = _startOffset;
        [self adapterOffset];
    }
    return self;
}

// 用于继承，进行自定义修改
- (void) adapterOffset {
    unsigned startOffset = [self getEndOffset];
    unsigned endOffset = (unsigned)_context.file_int_data_length;
    const char *bytes = (const char*)[_context.fileData bytes];
    for (int i = startOffset; i < endOffset; i++)
    {
        char c = bytes[i];
        if(!isspace(c)) {
            if(c == ';')
            {
                _endOffset = i + 1;
            }
            break;
        }
        
    }
    
}

- (void) OBF: (DFModelBuilder*) modelBuilder{
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
    if(factory->isStart()) {
        if([_parent isKindOfClass:ClangCompoundBlock.class] && [_parent isCanObf]) {
            bool isCanWrap = [self getKind] != CXCursor_VarDecl && [self getKind] != CXCursor_ReturnStmt;
            if(!isCanWrap) {
                factory->popCodeStack();
            }
            factory->insertCode([[self fullCode] UTF8String], isCanWrap);
        } else {
            factory->insertCode([[self fullCode] UTF8String], false, false);
        }
    }
}

- (enum CXCursorKind) getKind {
    return _cursor.kind;
}

- (void) onEnter {
    
}

- (void) onExit {
    
}

- (unsigned) getEndOffset
{
    return _endOffset;
}

- (void) setRealCode : (NSString*) str {
    realCode = str;
}

- (NSString *) fullCode
{
    if(realCode) {
        return realCode;
    }
    // 当前节点的内容描述
    NSData* cont = [_context.fileData subdataWithRange:NSMakeRange(_preOffset, _endOffset-_preOffset)];
    NSString* declString = [[NSString alloc] initWithData:cont encoding:NSUTF8StringEncoding];
    return declString;
}

- (NSString *)updateContent
{
    return [self fullCode];
}

@end
