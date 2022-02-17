//
//  DFClassDefinition.m
//  DFGrok
//
//  Created by Sam Taylor on 12/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import "DFOCClassDefinition.h"

@implementation DFOCClassDefinition

- (BOOL)isSubclassOf:(DFOCClassDefinition*)parent {
    BOOL isId = [parent.name isEqualToString:@"id"];
    
    // Make sure that we implement all same protocols as parent
    __block NSMutableDictionary* searchProtocols = [NSMutableDictionary dictionaryWithDictionary:parent.protocols];
    [searchProtocols removeObjectsForKeys:self.protocols.allKeys];
    
    DFOCClassDefinition* def = self;
    while ((def = def.superclassDef)) {
        [searchProtocols removeObjectsForKeys:def.protocols.allKeys];
        
        if (def == parent || isId) {
            // Found all protocols?
            if (![searchProtocols count]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
