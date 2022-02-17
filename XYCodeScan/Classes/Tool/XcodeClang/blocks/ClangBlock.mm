//
//  ClangBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangBlock.h"
#import "ClangBlockMgr.h"
#import "ClangLine.h"
#import "ClangString.h"
#import "JunkCodeClientData.h"
#include "XCodeFactory.hpp"
#import "ClangCMethodBlock.h"

@interface ClangBlock()

@end

@implementation ClangBlock

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.childs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (bool) childBlockCanInsertCode {
    return false;
}

- (ClangCMethodBlock *) getSuperMethodBlock {
    ClangBlock * p = _parent;
    while(p) {
        if([p isKindOfClass:ClangCMethodBlock.class]) {
            return p;
        }
        p = p->_parent;
    }
    return nil;
}

- (enum CXChildVisitResult) enterBlock:(CXCursor) c parent: (CXCursor) p
{
    if(_parent && !clang_equalCursors(p, _cursor)) {
        [self onExit];
        return [_parent enterBlock:c parent:p];
    }
    Class cls = [[ClangBlockMgr sharedInstance] getClassByKind:c.kind];
    bool isExist = true;
    if(!cls) {
        cls = ClangLine.class;
        isExist = false;
    }
    if(!isExist) {
        ClangLine * line = [[ClangLine alloc] initWithCursor:_context cursor:c parent:self];
        if(lastChild) {
            line.preOffset = [lastChild getEndOffset];
        } else {
            firstChild = line;
        }
        lastChild = line;
        [self.childs addObject:line];
        __block unsigned cursor_begin = line.preOffset;
        __block unsigned cursor_end = line->_endOffset;
        
        NSMutableString * fcode = [NSMutableString string];
        clang_visitChildrenWithBlock(c, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
            if( cursor.kind == CXCursor_StringLiteral || cursor.kind == CXCursor_ObjCStringLiteral) {
                unsigned s, e;
                CXSourceRange range = clang_getCursorExtent(cursor);
                CXSourceLocation startLocation = clang_getRangeStart(range);
                CXSourceLocation endLocation = clang_getRangeEnd(range);
                clang_getFileLocation(startLocation, NULL, NULL, NULL, &s);
                clang_getSpellingLocation(endLocation, NULL, NULL, NULL, &e);
                
                NSData* data_str = [self->_context.fileData subdataWithRange:NSMakeRange(s, e-s)];
                NSString* str_value = [[NSString alloc] initWithData:data_str encoding:NSUTF8StringEncoding];
                // 这里可以做字符串是否要混淆的校验。
                
                [self->_context.stringArr addObject:str_value];
                ClangCMethodBlock * method = [self getSuperMethodBlock];
                if(method) {
                    method.needStrObf = true;
                }
                NSData* data_before = [self->_context.fileData subdataWithRange:NSMakeRange(cursor_begin, s-cursor_begin)];
                NSString* str_before = [[NSString alloc] initWithData:data_before encoding:NSUTF8StringEncoding];
                [fcode appendString: str_before];
                [fcode appendFormat:@"__STRING_VALUE_REF_%lu", (unsigned long)self->_context.stringArr.count];
                cursor_begin = e;
                return CXChildVisit_Continue;
            }
            return CXChildVisit_Recurse;
        });

        NSData* d1 = [_context.fileData subdataWithRange:NSMakeRange(cursor_begin, cursor_end-cursor_begin)];
        NSString* s = [[NSString alloc] initWithData:d1 encoding:NSUTF8StringEncoding];
        [fcode appendString:s];
        [line setRealCode:fcode];
    } else {

        ClangBlock * block = [[cls alloc] initWithCursor:_context cursor:c parent:self];
        if(lastChild) {
            block.preOffset = [lastChild getEndOffset];
        } else {
            firstChild = block;
        }
        lastChild = block;
        [_childs addObject:block];
        [block onEnter];
        _context.curBlock = block;
    }
    if(isExist) {
        return CXChildVisit_Recurse;
    } else {
        return CXChildVisit_Continue;
    }
}

- (NSString *) getBeforeCode
{
    if(!firstChild) {
        return @"";
    }
    unsigned startOffset = self.preOffset;
    unsigned endOffset = firstChild.preOffset;
    
    // 当前节点的内容描述
    NSData* cont = [_context.fileData subdataWithRange:NSMakeRange(startOffset, endOffset-startOffset)];
    NSString* declString = [[NSString alloc] initWithData:cont encoding:NSUTF8StringEncoding];
    return declString;
}

- (NSString *) getAfterCode
{
    unsigned startOffset = [self getEndOffset];
    if(lastChild) {
        startOffset = [lastChild getEndOffset];
    }
    unsigned endOffset = _context.file_int_data_length;
    if(!clang_Cursor_isNull(_cursor)) {
        endOffset = [self getEndOffset];
    }
    // 当前节点的内容描述
    NSData* cont = [_context.fileData subdataWithRange:NSMakeRange(startOffset, endOffset-startOffset)];
    NSString* declString = [[NSString alloc] initWithData:cont encoding:NSUTF8StringEncoding];
    return declString;
}

- (NSString*)updateContent
{
    if(_childs.count == 0) {
        return [self fullCode];
    }
    NSMutableString * code = [NSMutableString string];
    [code appendString:[self getBeforeCode]];
    for(ClangLine * line in self.childs) {
        if([line isKindOfClass:ClangBlock.class]) {
            [code appendFormat:@"%@", [line updateContent]];
        } else {
            [code appendString:[line updateContent]];
        }
    }
    [code appendFormat:@"%@", [self getAfterCode]];
    return code;
}

- (void) OBF : (DFModelBuilder*) modelBuilder{
    [self obfStart:modelBuilder];
    for(ClangLine * line in self.childs) {
        [line OBF:modelBuilder];
    }
    [self obfEnd:modelBuilder];
}

- (bool) isCanObf {
    return true;
}

- (void) obfStart: (DFModelBuilder*) modelBuilder{
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
    bool canWrapCode = _parent && [_parent childBlockCanInsertCode];
    if(factory->isStart()) {
        if(lastChild) {
            factory->insertCode([[self getBeforeCode] UTF8String], canWrapCode, canWrapCode);
            factory->resetTopParser();
        } else {
            factory->insertCode([[self fullCode] UTF8String], canWrapCode, canWrapCode);
        }
    }
}

- (void) obfEnd: (DFModelBuilder*) modelBuilder{
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
    if(factory->isStart()) {
        if(lastChild) {
            factory->insertCode([[self getAfterCode] UTF8String], false, false);
        }
    }
}

@end
