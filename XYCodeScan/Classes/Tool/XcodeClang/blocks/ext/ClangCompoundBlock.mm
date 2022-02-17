//
//  ClangCompoundBlock.m
//  HYCodeScan
//
//  Created by admin on 2020/7/23.
//

#import "ClangCompoundBlock.h"
#include "XCodeFactory.hpp"
#import "ClangCMethodBlock.h"
#import "JunkCodeClientData.h"

@implementation ClangCompoundBlock
- (bool) isCanObf
{
    if(_parent && ![_parent isKindOfClass:ClangCompoundBlock.class]) {
        return [_parent isCanObf];
    }
    return true;
}

- (void) obfStart : (DFModelBuilder*) modelBuilder {
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
    if(!factory->isStart()) return;
    if(self.childs.count > 0) {
        factory->enterBlock([[self getBeforeCode] UTF8String]);
        if([_parent isKindOfClass:ClangCMethodBlock.class]) {
            if(((ClangCMethodBlock *)_parent).needStrObf) {
                factory->insertCode([_context getObfMethodCall], true);
            }
        }
    } else {
        factory->insertCode([[self fullCode] UTF8String], false, false);
    }
}

- (void) obfEnd : (DFModelBuilder*) modelBuilder {
    hygen::CodeFactory * factory = hygen::CodeFactory::factory();
    if(!factory->isStart()) return;
    if(self.childs.count > 0) {
        factory->exitBlock([[self getAfterCode] UTF8String]);
    }
}

- (bool) childBlockCanInsertCode {
    return true;
}

@end
