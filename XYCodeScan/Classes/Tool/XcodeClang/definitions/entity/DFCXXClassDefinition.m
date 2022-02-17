//
//  DFCXXClassDefinition.m
//  HYCodeScan
//
//  Created by admin on 2020/7/24.
//

#import "DFCXXClassDefinition.h"
@interface DFCXXClassDefinition()

@property (nonatomic, readwrite) NSMutableDictionary* methods;

@end

@implementation DFCXXClassDefinition

- (id)initWithName:(NSString *)name {
    self = [super initWithName:name];
    if (self) {
        self.methods = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
