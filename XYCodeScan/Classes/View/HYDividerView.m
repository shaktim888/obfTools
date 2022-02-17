//
//  HYDividerView.m
//  HYCodeObfuscation
//
//  Created by HY admin on 2019/8/18.
//  Copyright © 2019年 HY admin. All rights reserved.
//

#import "HYDividerView.h"

@implementation HYDividerView

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder]) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    }
    return self;
}

@end
