//
//  DFClassDefinition.h
//  DFGrok
//
//  Created by Sam Taylor on 12/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFContainerDefinition.h"

@interface DFOCClassDefinition : DFContainerDefinition
@property (nonatomic) DFOCClassDefinition* superclassDef;

- (BOOL)isSubclassOf:(DFOCClassDefinition*)parent;
@end
