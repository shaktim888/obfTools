#import <Foundation/Foundation.h>

#import "HYDefineNameViewController.h"
#import "HYDefineRenameTool.h"


@interface HYDefineNameViewController()

@property (weak) IBOutlet NSButton *chooseBtn;
@property (weak) IBOutlet NSButton *startBtn;
@property (weak) IBOutlet NSTextField *tipLabel;
@property (weak) IBOutlet NSTextField *stateLabel;

@property (nonatomic, strong) NSMutableArray<NSString *> * filepath;

@end

@implementation HYDefineNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.filepath = [[NSMutableArray alloc] init];
    self.tipLabel.stringValue = @"请先选择需要处理的文件。";
    self.stateLabel.stringValue = @"";
    self.startBtn.enabled = NO;
}

- (IBAction)start:(NSButton *)sender {
    [HYDefineRenameTool renameHeadFile:self.filepath callback:^(NSString* name) {
         if(name) {
             self.stateLabel.stringValue = [@"处理中:" stringByAppendingString:name];
         }else{
             self.stateLabel.stringValue = @"处理完成";
         }
     }];
}

- (IBAction)chooseFile:(NSButton *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.prompt = @"选择";
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        
        [self.filepath addObject:openPanel.URLs.firstObject.path];
        self.tipLabel.stringValue = [@"需要进行重定义的文件列表：\n" stringByAppendingString:[self.filepath description]];
        self.startBtn.enabled = YES;
    }];
}
@end
