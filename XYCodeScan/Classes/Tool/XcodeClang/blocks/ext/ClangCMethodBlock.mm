//
//  ClangCMethodBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangCMethodBlock.h"
#include "XCodeFactory.hpp"
@interface ClangCMethodBlock()
{
    NSString * obfCode;
}

@end

@implementation ClangCMethodBlock

- (instancetype) init
{
    self = [super init];
    if (self) {
        obfCode = nil;
        _needStrObf = false;
    }
    return self;
}

- (hygen::CodeMode) getCodeMode {
    return hygen::CodeMode_C;
}

- (void) obfStart : (DFModelBuilder*) modelBuilder {
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
    factory->start([self getCodeMode], true);
}

- (void) obfEnd : (DFModelBuilder*) modelBuilder {
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
//    NSString * fullCode = [self fullCode];
    std::string code = factory->finish();
    obfCode = [NSString stringWithUTF8String:code.c_str()];
}

- (NSString *)updateContent
{
    NSMutableString * code = [NSMutableString string];
    [code appendString:[self getBeforeCode]];
    [code appendFormat:@"%@\n", obfCode];
    [code appendFormat:@"%@", [self getAfterCode]];
    return code;
}

@end
