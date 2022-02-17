#import <Foundation/Foundation.h>
#import "HYXXTEAViewController.h"
#import "NSFileManager+Extension.h"
#import "xxteaTools.h"

@interface HYXXTEAViewController()

@property (weak) IBOutlet NSTextField *inPath;
@property (weak) IBOutlet NSTextField *outPath;
@property (weak) IBOutlet NSTextField *xxteaKey;
@property (weak) IBOutlet NSTextField *xxteaSign;

@property (weak) IBOutlet NSButton *startBtn;

@end


@implementation HYXXTEAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.inPath.stringValue = @"";
    self.outPath.stringValue = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.xxteaKey];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.xxteaSign];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.inPath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.outPath];
    [self prefixDidChange];
}

- (void)prefixDidChange {
    BOOL ok1 = [self.xxteaKey.stringValue length] > 0;
    BOOL ok2 = [self.xxteaSign.stringValue length] > 0;
    BOOL ok3 = [self.inPath.stringValue length] > 0;
    BOOL ok4 = [self.outPath.stringValue length] > 0;
    self.startBtn.enabled = ok1 && ok2 && ok3 && ok4;
}

- (IBAction)startDecode:(NSButton *)sender {
    NSArray* arr = [NSFileManager hy_subpathsAtPath:[self.inPath stringValue] extensions:nil];
    for(NSString * file in arr)
    {
        [xxteaTools decodeFile:[[self.inPath stringValue] stringByAppendingPathComponent:file] output:[[self.outPath stringValue]stringByAppendingPathComponent:file] key:self.xxteaKey.stringValue sign:self.xxteaSign.stringValue];
    }
}

@end
