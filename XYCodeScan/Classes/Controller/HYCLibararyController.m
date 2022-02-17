#import "HYCLibararyController.h"
#import "HYObfuscationTool.h"
#import "NSFileManager+Extension.h"
#import "NSString+Extension.h"
#import "HYDefineRenameTool.h"
#import "SULogger.h"

@interface HYCLibararyController()
@property (weak) IBOutlet NSButton *startBtn;
@property (weak) IBOutlet NSTextField *numberOfFuncOnBranch;
@property (weak) IBOutlet NSTextField *numberOfBranch;
@property (weak) IBOutlet NSTextField *numberOfLib;
@property (weak) IBOutlet NSTextField *folderPath;
@end

@implementation HYCLibararyController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [SULogger start];
    self.numberOfFuncOnBranch.stringValue = @"10000";
    self.numberOfBranch.stringValue = @"3";
    self.numberOfLib.stringValue = @"1";
    self.folderPath.stringValue = @"";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.numberOfFuncOnBranch];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.numberOfBranch];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.numberOfLib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.folderPath];
    
}

- (void)prefixDidChange {
    BOOL OK1 = self.numberOfFuncOnBranch.stringValue.length > 0;
    BOOL OK2 = self.numberOfBranch.stringValue.length > 0;
    BOOL OK3 = self.numberOfLib.stringValue.length > 0;
    BOOL OK4 = self.folderPath.stringValue.length > 0;
    self.startBtn.enabled = OK1 && OK2 && OK3 && OK4;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)start:(NSButton *)sender {
    
}

@end
