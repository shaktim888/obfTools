#import "HYCodeViewController.h"
#import "HYObfuscationTool.h"
#import "NSFileManager+Extension.h"
#import "NSString+Extension.h"
#import "HYDefineRenameTool.h"
#import "UserConfig.h"

@interface HYCodeViewController()
@property (weak) IBOutlet NSButton *openBtn;
@property (weak) IBOutlet NSButton *chooseBtn;
@property (weak) IBOutlet NSButton *startBtn;
@property (weak) IBOutlet NSTextField *filepathLabel;
@property (nonatomic, strong) NSMutableArray<NSString *> * filepath;
@property (copy) NSString *destFilepath;
@property (weak) IBOutlet NSTextField *destFilepathLabel;
@property (weak) IBOutlet NSTextField *tipLabel;
@property (weak) IBOutlet NSTextField *prefixFiled;
@end

@implementation HYCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.filepath = [[NSMutableArray alloc] init];
    self.tipLabel.stringValue = @"";
    self.filepathLabel.stringValue = @"";
    self.destFilepathLabel.stringValue = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.prefixFiled];
}

- (void)prefixDidChange {
//    NSString *text = [self.prefixFiled.stringValue hy_stringByRemovingSpace];
    self.startBtn.enabled = [self.filepath count] > 0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)chooseFile:(NSButton *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.prompt = @"选择";
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        
        [self.filepath addObject:openPanel.URLs.firstObject.path];
        self.filepathLabel.stringValue = [@"需要进行混淆的目录：\n" stringByAppendingString:[self.filepath description]];
        self.destFilepath = nil;
        self.destFilepathLabel.stringValue = @"";
        self.openBtn.enabled = YES;
        [self prefixDidChange];
    }];
}

- (IBAction)openFile:(NSButton *)sender {
    NSString *file = self.destFilepath ? self.destFilepath : [self.filepath firstObject];
    NSArray *fileURLs = @[[NSURL fileURLWithPath:file]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

- (IBAction)start:(NSButton *)sender {
    self.destFilepathLabel.stringValue = @"";
    self.startBtn.enabled = NO;
    self.chooseBtn.enabled = NO;
    self.prefixFiled.enabled = NO;
    
    // 获得前缀
    NSArray *prefixes = [self.prefixFiled.stringValue hy_componentsSeparatedBySpace];
    
    self.tipLabel.stringValue = @"扫描中";
    // 混淆
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [HYObfuscationTool reset];
        [UserConfig sharedInstance].scanType = true;
        [UserConfig sharedInstance].scanVar = true;
        [UserConfig sharedInstance].scanFunc = true;
        [UserConfig sharedInstance].scanProp = true;
        
        [HYObfuscationTool obfuscateAtDir:self.filepath
                                 prefixes:prefixes];
        [HYObfuscationTool write:[self.filepath firstObject]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.destFilepathLabel.stringValue = [@"混淆后的文件路径：\n" stringByAppendingString:[self.filepath firstObject]];
            
            // 恢复按钮
            self.startBtn.enabled = YES;
            self.chooseBtn.enabled = YES;
            self.prefixFiled.enabled = YES;
        });
    });
}

@end
