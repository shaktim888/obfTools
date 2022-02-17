//
//  ClangBlockMgr.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangBlockMgr.h"
#import "clang-c/Index.h"

#import "ClangOCInterfaceBlock.h"
#import "ClangOCImplementationBlock.h"
#import "ClangClassBlock.h"
#import "ClangOCMethodBlock.h"
#import "ClangCMethodBlock.h"
#import "ClangCXXMethodBlock.h"
#import "ClangIfBlock.h"
#import "ClangWhileBlock.h"
#import "ClangDoWhileBlock.h"
#import "ClangSwitchBlock.h"
#import "ClangCaseBlock.h"
#import "ClangCompoundBlock.h"
#import "ClangForBlock.h"

@interface ClangBlockMgr() {
    NSMutableDictionary * allBlockMap;
}

@end


@implementation ClangBlockMgr

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance registerAllBlock];
    });
    return instance;
}

-(void) registerAllBlock
{
    allBlockMap = [[NSMutableDictionary alloc] init];
    [allBlockMap setObject:ClangOCImplementationBlock.class forKey:@(CXCursor_ObjCImplementationDecl)];
    [allBlockMap setObject:ClangOCInterfaceBlock.class forKey:@(CXCursor_ObjCInterfaceDecl)];
    [allBlockMap setObject:ClangClassBlock.class forKey:@(CXCursor_ClassDecl)];
    
    [allBlockMap setObject:ClangCXXMethodBlock.class forKey:@(CXCursor_CXXMethod)];
    [allBlockMap setObject:ClangCMethodBlock.class forKey:@(CXCursor_FunctionDecl)];
    [allBlockMap setObject:ClangOCMethodBlock.class forKey:@(CXCursor_ObjCInstanceMethodDecl)];
    [allBlockMap setObject:ClangOCMethodBlock.class forKey:@(CXCursor_ObjCClassMethodDecl)];
    
    [allBlockMap setObject:ClangIfBlock.class forKey:@(CXCursor_IfStmt)];
    [allBlockMap setObject:ClangWhileBlock.class forKey:@(CXCursor_WhileStmt)];
    [allBlockMap setObject:ClangDoWhileBlock.class forKey:@(CXCursor_DoStmt)];
    [allBlockMap setObject:ClangSwitchBlock.class forKey:@(CXCursor_SwitchStmt)];
    [allBlockMap setObject:ClangCaseBlock.class forKey:@(CXCursor_CaseStmt)];
    [allBlockMap setObject:ClangForBlock.class forKey:@(CXCursor_ForStmt)];
    
    [allBlockMap setObject:ClangCompoundBlock.class forKey:@(CXCursor_CompoundStmt)];
}

- (Class) getClassByKind : (int) kind
{
    return [allBlockMap objectForKey:@(kind)];
}

@end
