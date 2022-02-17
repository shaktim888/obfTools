//
//  HYGenAutoBuildShellViewController.m
//  HYCodeScan
//
//  Created by admin on 2020/2/28.
//  Copyright © 2020 Admin. All rights reserved.
//

#import "HYGenAutoBuildShellViewController.h"

@interface AddVarView : NSView
    
@end

@implementation AddVarView

- (void)viewDidLoad {
    [self setFrameSize:NSMakeSize(500, 40)];
    NSTextField * name = [[NSTextField alloc] init];
    [self addSubview:name];
    
}

@end

@interface HYGenAutoBuildShellViewController ()

@end

@implementation HYGenAutoBuildShellViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self addAllButton];
}

- (void) clickBtn:(id) sender
{
    NSLog(@"123");
}

- (void) addAllButton
{
    
    NSScrollView *tableContainerView = [[NSScrollView alloc] initWithFrame:CGRectMake(5, 5, 300, 300)];
    
    NSTableCellView * table = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 300, 200)];
    table.autoresizingMask = NSViewHeightSizable;
    for(int i = 0; i < 20; i++) {
        NSTableRowView * row = [[NSTableRowView alloc] init];
        
        NSButton * btn = [[NSButton alloc] initWithFrame:NSMakeRect(0, i * 25 + 5, 100 , 20 )];

        [btn setTitle:@"设置URL"];
        [btn setTarget:self];
        [btn setAction:@selector(clickBtn:)];
        [table addSubview:btn];
//        [table addTableColumn:]
    }
    
    [tableContainerView setDocumentView:table];
    
//    [_buttonPanel.contentView setFrameSize:NSMakeSize(200, 10000)];
    [self.view addSubview:tableContainerView];
}


- (void) addViewByType
{
    
}

@end
