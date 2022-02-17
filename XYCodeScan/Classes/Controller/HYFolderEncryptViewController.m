//
//  HYLuaCompressViewController.m
//  HYCodeScan
//
//  Created by admin on 2019/12/18.
//  Copyright © 2019 Admin. All rights reserved.
//

#import "HYFolderEncryptViewController.h"
#import "ZipEncrypt.h"

@interface HYFolderEncryptViewController ()

@property (weak) IBOutlet NSTextField *inPath;
@property (weak) IBOutlet NSTextField *outPath;
@property (weak) IBOutlet NSTextField *fileName;
@property (weak) IBOutlet NSButton *startBtn;
@end

@implementation HYFolderEncryptViewController

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
    NSString *fileName = [self.fileName.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(fileName.length == 0) {
        fileName = @"folder.enc";
    }
    compressToZip([self.inPath.stringValue UTF8String], [[self.outPath.stringValue stringByAppendingPathComponent:fileName] UTF8String]);
}

@end
