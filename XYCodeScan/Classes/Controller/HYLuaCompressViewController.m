//
//  HYLuaCompressViewController.m
//  HYCodeScan
//
//  Created by admin on 2019/12/18.
//  Copyright © 2019 Admin. All rights reserved.
//

#import "HYLuaCompressViewController.h"
#import "LuaObf.h"

@interface HYLuaCompressViewController ()

@property (weak) IBOutlet NSTextField *inPath;
@property (weak) IBOutlet NSTextField *outPath;
@property (weak) IBOutlet NSTextField *prefix;
@property (weak) IBOutlet NSButton *startBtn;
@end

@implementation HYLuaCompressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.inPath.stringValue = @"";
    self.outPath.stringValue = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.inPath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.outPath];
}

- (void)prefixDidChange {
    BOOL isInPathOK = [self.inPath.stringValue length] > 0;
    BOOL isOutPathOK = [self.outPath.stringValue length] > 0;
    _startBtn.enabled = isInPathOK && isOutPathOK;
}

- (IBAction)start:(NSButton *)sender {
    [LuaObf compressLuaFile:self.inPath.stringValue output:self.outPath.stringValue prefix:self.prefix.stringValue];
}

@end
