//
//  ClangCXXMethodBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangCXXMethodBlock.h"
#include "XCodeFactory.hpp"


@implementation ClangCXXMethodBlock

- (hygen::CodeMode) getCodeMode {
    return hygen::CodeMode_CXX;
}

@end
