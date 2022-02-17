//
//  DFClangParserDelegate.h
//  DFGrok
//
//  Created by Sam Taylor on 12/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <clang-c/Index.h>

@protocol DFClangParserDelegate <NSObject>
@optional
- (void)onFoundDeclaration:(CXIdxDeclInfo const *)declaration;
- (void)onFoundEntityReference:(const CXIdxEntityRefInfo *)entityRef;
- (CXIdxClientFile)onIncludedFile:(const CXIdxIncludedFileInfo *)includedFile;
@end
