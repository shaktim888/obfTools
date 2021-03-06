//
//  DFPropertyDefinition.m
//  DFGrok
//
//  Created by Sam Taylor on 18/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import "DFPropertyDefinition.h"

@interface DFPropertyDefinition ( /* Private */ )
{
    BOOL isWaitGetterName;
    BOOL isWaitSetterName;
}
@property (nonatomic, readwrite, getter = isWeak) BOOL weak;
@property (nonatomic, readwrite, getter = isReadOnly) BOOL readOnly;
@property (nonatomic, readwrite) NSMutableArray* protocolNames;
@property (nonatomic, readwrite) NSString* typeName;
@property (nonatomic, readwrite) NSString* customGetter;
@property (nonatomic, readwrite) NSString* customSetter;
@property (nonatomic) NSMutableArray* tokens;
@end

@implementation DFPropertyDefinition

- (id)initWithName:(NSString*)name andTokens:(NSArray*)tokens {
    
    self = [super initWithName:name];
    if (self) {
        // Setup
        self.protocolNames = [NSMutableArray array];
        self.tokens = [NSMutableArray arrayWithArray:tokens];
        
        isWaitGetterName = false;
        isWaitSetterName = false;
        // Parse
        [self consumeTokens];
    }
    return self;
}

- (void)consumeTokens {
    [self consumePropertyDeclaration];
    [self consumeAttributes];
    [self consumeProtocols];
    
    // Whatever is left is the classname and the property name. We already have the property name.
    [self.tokens enumerateObjectsUsingBlock:^(NSString* token, NSUInteger idx, BOOL *stop) {
        if ([token isEqualToString:@";"] || [token isEqualToString:@"*"] || [token isEqualToString:self.name]) {
            // Ignore
        } else {
            self.typeName = token;
            *stop = YES;
        }
    }];
    
    self.tokens = nil;
}

- (void)consumePropertyDeclaration {
    __block NSRange consumeRange;
    consumeRange.location = NSNotFound;
    [self.tokens enumerateObjectsUsingBlock:^(NSString* token, NSUInteger idx, BOOL *stop) {
        if ([token isEqualToString:@"@"]) {
            consumeRange.location = idx;
        } else if ([token isEqualToString:@"property"]) {
            consumeRange.length = (idx+1) - consumeRange.location;
            *stop = YES;
        }
    }];
    if (consumeRange.location != NSNotFound) {
        [self.tokens removeObjectsInRange:consumeRange];
    }
}

- (void)consumeAttributes {
    __block NSRange consumeRange;
    consumeRange.location = NSNotFound;
    
    [self.tokens enumerateObjectsUsingBlock:^(NSString* token, NSUInteger idx, BOOL *stop) {
        if ([token isEqualToString:@"("]) {
            consumeRange.location = idx;
        } else if ([token isEqualToString:@")"]) {
            consumeRange.length = (idx+1) - consumeRange.location;
            *stop = YES;
        } else {
            if (consumeRange.location != NSNotFound) {
                if (![token isEqualToString:@","] && ![token isEqualToString:@"="]) {
                    // OK so we're expecting attributes here, eg, weak, nonatomic, readonly etc.
                    [self attributeFound:token];
                }
            }
        }
    }];
    if (consumeRange.location != NSNotFound) {
        [self.tokens removeObjectsInRange:consumeRange];
    }
}

- (void)consumeProtocols {
    __block NSRange consumeRange;
    consumeRange.location = NSNotFound;
    consumeRange.length = 0;
    
    [self.tokens enumerateObjectsUsingBlock:^(NSString* token, NSUInteger idx, BOOL *stop) {
        if ([token isEqualToString:@"<"]) {
            consumeRange.location = idx;
        } else if ([token isEqualToString:@">"]) {
            consumeRange.length = (idx+1) - consumeRange.location;
            *stop = YES;
        } else if (consumeRange.location != NSNotFound) {
            [self protocolFound:token];
        }
    }];
    if (consumeRange.location != NSNotFound) {
        [self.tokens removeObjectsInRange:consumeRange];
    }
}

- (void)protocolFound:(NSString*)protocolName {
    [self.protocolNames addObject:[NSString stringWithFormat:@"<%@>", protocolName]];
}


- (void)attributeFound:(NSString*)name {
    if ([name isEqualToString:@"weak"]) {
        self.weak = YES;
    } else if([name isEqualToString:@"readonly"]) {
        self.readOnly = YES;
    } else if([name isEqualToString:@"setter"]) {
       isWaitSetterName = true;
    } else if([name isEqualToString:@"getter"]) {
        isWaitGetterName = true;
    } else {
        if(isWaitSetterName) {
            self.customSetter = name;
        }
        if(isWaitGetterName) {
            self.customGetter = name;
        }
    }
}

#pragma mark - DFPropertyDefinitionInterface
- (BOOL)isMultiple {
    return NO;
}

@end
