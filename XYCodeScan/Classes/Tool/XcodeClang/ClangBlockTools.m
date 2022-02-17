//
//  ClangBlockTools.m
//  HYCodeScan
//
//  Created by admin on 2020/7/24.
//

#import "ClangBlockTools.h"
#import "ClangLine.h"
#import "ClangCustomBlock.h"
#import "JunkCodeClientData.h"
#import "ClangOCImplementationBlock.h"
#import "DFModelBuilder.h"
#import "DFOCClassDefinition.h"

@implementation ClangBlockTools

- (ClangCustomBlock *) createIfBlock : (JunkCodeClientData*) context
{
    ClangCustomBlock * block = [[ClangCustomBlock alloc] initWithCursor:context cursor:clang_getNullCursor() parent:nil];
    block.codeBefore = @"if() {";
    block.codeAfter = @"}";
    
    return block;
}

- (void) createNewMethod : (DFModelBuilder *) modelBuilder ocClass:(ClangOCImplementationBlock*) ocImp
{
    DFOCClassDefinition * def = (DFOCClassDefinition *)(modelBuilder.OCDefinitions[ocImp.className]);
    
}

@end
