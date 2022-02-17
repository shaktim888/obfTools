//
//  DFModelBuilder.h
//  DFGrok
//
//  Created by Sam Taylor on 22/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "clang-c/Index.h"
#import "DFClangParserDelegate.h"

@interface DFModelBuilder : NSObject<DFClangParserDelegate>

@property (nonatomic, assign) CXTranslationUnit translationUnit;
@property (nonatomic, readonly) NSMutableDictionary* OCDefinitions;

@end
