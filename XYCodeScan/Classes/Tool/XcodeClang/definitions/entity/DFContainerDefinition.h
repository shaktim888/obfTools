//
//  DFEntityDefinition.h
//  DFGrok
//
//  Created by Sam Taylor on 21/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import "DFDefinition.h"

@class DFProtocolDefinition;

@interface DFContainerDefinition : DFDefinition
@property (nonatomic, readonly) NSMutableDictionary* childDefinitions;
@property (nonatomic, readonly) NSMutableDictionary* protocols;
@property (nonatomic, readonly) NSMutableDictionary* methods;

- (BOOL)implementsProtocolDefinition:(DFProtocolDefinition*)protoDef;

@end
