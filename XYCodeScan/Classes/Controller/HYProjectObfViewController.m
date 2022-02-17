#import <Foundation/Foundation.h>
#import "HYProjectObfViewController.h"
#import "NSFileManager+Extension.h"
#import "ProjectObf.h"
#import "ImageTools.h"
#import "LuaCodeObf.h"
#import "rcg.h"
#import "HYGenerateNameTool.h"
#import "UserConfig.h"
#import "mmd5.h"
#import "FileLogger.h"
#import "ImageToolsConstants.h"

@interface HYProjectObfViewController()

@property (weak) IBOutlet NSTextField *xcodePath;
@property (weak) IBOutlet NSTextField *codePath;
@property (weak) IBOutlet NSTextField *targets;
@property (weak) IBOutlet NSTextField *prob;
@property (weak) IBOutlet NSButton *scanProjectCode;
@property (weak) IBOutlet NSTextField *backupFolder;
@property (weak) IBOutlet NSTextField *luaFolder;
@property (weak) IBOutlet NSButton *luaCode;
@property (weak) IBOutlet NSButton *isUglifyLua;
@property (weak) IBOutlet NSButton *isMinifyLua;
@property (weak) IBOutlet NSTextField *resFolder;
@property (weak) IBOutlet NSPopUpButton *imgMode;
@property (weak) IBOutlet NSTextField *ignoreFile;

@property (weak) IBOutlet NSButton *encodeNSStr;
@property (weak) IBOutlet NSButton *encodeCStr;
@property (weak) IBOutlet NSButton *insertFunc;
@property (weak) IBOutlet NSButton *insertCode;
@property (weak) IBOutlet NSButton *addProp;
@property (weak) IBOutlet NSButton *scanType;
@property (weak) IBOutlet NSButton *scanFunc;
@property (weak) IBOutlet NSButton *scanVar;
@property (weak) IBOutlet NSButton *scanProp;
@property (weak) IBOutlet NSButton *addRubbishRes;
@property (weak) IBOutlet NSButton *groupRename;
@property (weak) IBOutlet NSButton *jsObf;
@property (weak) IBOutlet NSButton *mmd5;
@property (weak) IBOutlet NSButton *backUp;
@property (weak) IBOutlet NSButton *renameDefine;
@property (weak) IBOutlet NSButton *scanXib;
@property (weak) IBOutlet NSButton *log;
@property (weak) IBOutlet NSTextField *numOfFunc;

@property (weak) IBOutlet NSButton * isAddCpp;
@property (weak) IBOutlet NSButton * isAddOC;
@property (weak) IBOutlet NSButton * skipOptimize;

@property (weak) IBOutlet NSTextField *addCppNum;
@property (weak) IBOutlet NSTextField *addOCNum;
@property (weak) IBOutlet NSButton *isUnity;
@property (weak) IBOutlet NSButton *isAddFileReDefine;

@property (weak) IBOutlet NSTextField *statusLabel;

@property (weak) IBOutlet NSButton *useKiwi;
@property (weak) IBOutlet NSButton *udid;

@property (weak) IBOutlet NSButton *genjs;
@property (weak) IBOutlet NSButton *genlua;

@property (weak) IBOutlet NSTextField *stringWeight;
@property (weak) IBOutlet NSTextField *OCWeight;
@property (weak) IBOutlet NSTextField *stringWordMin;
@property (weak) IBOutlet NSTextField *stringWordMax;

@property (weak) IBOutlet NSTextField *rubbishResMin;
@property (weak) IBOutlet NSTextField *rubbishResMax;

@property (weak) IBOutlet NSLevelIndicator * pngquantSpeed;

@property (weak) IBOutlet NSButton *startBtn;
@property (weak) IBOutlet NSButton *insertLuaCocos;

@end


@implementation HYProjectObfViewController
bool isInProcess = false;

- (void) setToCurrentCfg
{
    UserConfig * cfg = [UserConfig sharedInstance];
    cfg.xcodePath = [self.xcodePath.stringValue copy];
    cfg.codePath = [self.codePath.stringValue copy];
    cfg.targets = [self.targets.stringValue copy];
    if(self.prob.integerValue > 100) self.prob.integerValue = 100;
    if(self.prob.integerValue < 0) self.prob.integerValue = 0;
    cfg.prop = self.prob.intValue;
    cfg.scanProjectCode = self.scanProjectCode.state == NSOnState;
    cfg.backupPath = [self.backupFolder.stringValue copy];
    cfg.luaFolder = [self.luaFolder.stringValue copy];
    cfg.isLuaCode = self.luaCode.state == NSOnState;
    cfg.isUglifyLua = self.isUglifyLua.state == NSOnState;
    cfg.isMinifyLua = self.isMinifyLua.state == NSOnState;
    cfg.resFolder = [self.resFolder.stringValue copy];
    cfg.imageMode = self.imgMode.indexOfSelectedItem;
    cfg.customIgnoreFile = [self.ignoreFile.stringValue copy];
    cfg.encodeNSString = self.encodeNSStr.state == NSOnState;
    cfg.encodeCString = self.encodeCStr.state == NSOnState;
    cfg.insertFunction = self.insertFunc.state == NSOnState;
    cfg.insertCode = self.insertCode.state == NSOnState;
    cfg.addProperty = self.addProp.state == NSOnState;
    cfg.scanType = self.scanType.state == NSOnState;
    cfg.scanFunc = self.scanFunc.state == NSOnState;
    cfg.scanVar = self.scanVar.state == NSOnState;
    cfg.scanProp = self.scanProp.state == NSOnState;
    cfg.addRubishRes = self.addRubbishRes.state == NSOnState;
    cfg.groupRename = self.groupRename.state == NSOnState;
    cfg.jsObf = self.jsObf.state == NSOnState;
    cfg.mmd5 = self.mmd5.state == NSOnState;
    cfg.backup = self.backUp.state == NSOnState;
    cfg.autoRenameDefine = self.renameDefine.state == NSOnState;
    cfg.scanXib = self.scanXib.state == NSOnState;
    if(self.numOfFunc.intValue < 0) self.numOfFunc.intValue = 0;
    cfg.addMethodNum = self.numOfFunc.intValue;
    cfg.isAddOC = self.isAddOC.state == NSOnState;
    cfg.isAddCpp = self.isAddCpp.state == NSOnState;
    cfg.addOCNum = self.addOCNum.intValue;
    cfg.addCppNum = self.addCppNum.intValue;
    cfg.isUnity = self.isUnity.state == NSOnState;
    
    cfg.stringWeight = self.stringWeight.intValue;
    cfg.OCWeight = self.OCWeight.intValue;
    cfg.stringWordMin = self.stringWordMin.intValue;
    cfg.stringWordMax = self.stringWordMax.intValue;
    cfg.skipOptimize = self.skipOptimize.state == NSOnState;
    cfg.isAddFileReDefine = self.isAddFileReDefine.state == NSOnState;
    if(self.pngquantSpeed.intValue < 1) self.pngquantSpeed.intValue = 1;
    cfg.pngquantSpeed = self.pngquantSpeed.intValue;
    cfg.useKiwi = self.useKiwi.state == NSOnState;
    cfg.udid = self.udid.state == NSOnState;
    
    cfg.rubbishResMin = self.rubbishResMin.intValue;
    cfg.rubbishResMax = self.rubbishResMax.intValue;
    
    cfg.genjs = self.genjs.state == NSOnState;
    cfg.genlua = self.genlua.state == NSOnState;
    cfg.insertLuaCocos = self.insertLuaCocos.state == NSOnState;
}

- (void) loadFromCfg
{
    UserConfig * cfg = [UserConfig sharedInstance];
    self.xcodePath.stringValue = cfg.xcodePath;
    self.codePath.stringValue = cfg.codePath;
    self.targets.stringValue = cfg.targets;
    self.prob.stringValue = [@(cfg.prop) stringValue];
    self.scanProjectCode.state = cfg.scanProjectCode ? NSOnState : NSOffState;
    self.backupFolder.stringValue = cfg.backupPath;
    self.luaFolder.stringValue = cfg.luaFolder;
    self.luaCode.state = cfg.isLuaCode ? NSOnState : NSOffState;
    self.isUglifyLua.state = cfg.isUglifyLua ? NSOnState : NSOffState;
    self.isMinifyLua.state = cfg.isMinifyLua ? NSOnState : NSOffState;
    self.resFolder.stringValue = cfg.resFolder;
    [self.imgMode selectItemAtIndex:cfg.imageMode];
    self.ignoreFile.stringValue = cfg.customIgnoreFile;
    self.encodeCStr.state = cfg.encodeCString ? NSOnState : NSOffState;
    self.encodeNSStr.state = cfg.encodeNSString ? NSOnState : NSOffState;
    self.insertFunc.state = cfg.insertFunction  ? NSOnState : NSOffState;
    self.insertCode.state = cfg.insertCode ? NSOnState : NSOffState;
    self.addProp.state = cfg.addProperty  ? NSOnState : NSOffState;
    self.scanType.state = cfg.scanType  ? NSOnState : NSOffState;
    self.scanFunc.state = cfg.scanFunc ? NSOnState : NSOffState;
    self.scanVar.state = cfg.scanVar ? NSOnState : NSOffState;
    self.scanProp.state = cfg.scanProp ? NSOnState : NSOffState;
    self.addRubbishRes.state = cfg.addRubishRes  ? NSOnState : NSOffState;
    self.groupRename.state = cfg.groupRename ? NSOnState : NSOffState;
    self.jsObf.state = cfg.jsObf ? NSOnState : NSOffState;
    self.mmd5.state = cfg.mmd5 ? NSOnState : NSOffState;
    self.backUp.state = cfg.backup ? NSOnState : NSOffState;
    self.renameDefine.state = cfg.autoRenameDefine ? NSOnState : NSOffState;
    self.scanXib.state = cfg.scanXib ? NSOnState : NSOffState;
    self.log.state = cfg.saveLog ? NSOnState : NSOffState;
    self.isUnity.state = cfg.isUnity ? NSOnState : NSOffState;
    self.numOfFunc.stringValue = [@(cfg.addMethodNum) stringValue];
    self.isAddOC.state = cfg.isAddOC ? NSOnState : NSOffState;
    self.isAddCpp.state = cfg.isAddCpp ? NSOnState : NSOffState;
    self.skipOptimize.state = cfg.skipOptimize ? NSOnState : NSOffState;
    self.isAddFileReDefine.state = cfg.isAddFileReDefine ? NSOnState : NSOffState;
    self.addOCNum.stringValue = cfg.addOCNum > 0 ? [@(cfg.addOCNum) stringValue] : @"";
    self.addCppNum.stringValue = cfg.addCppNum > 0 ? [@(cfg.addCppNum) stringValue] : @"";
    
    self.stringWeight.stringValue = [@(cfg.stringWeight) stringValue];
    self.OCWeight.stringValue = [@(cfg.OCWeight) stringValue];
    self.stringWordMin.stringValue = [@(cfg.stringWordMin) stringValue];
    self.stringWordMax.stringValue = [@(cfg.stringWordMax) stringValue];
    self.pngquantSpeed.intValue = cfg.pngquantSpeed;
    self.useKiwi.state = cfg.useKiwi ? NSOnState : NSOffState;
    self.udid.state = cfg.udid ? NSOnState : NSOffState;
    
    self.rubbishResMin.stringValue = [@(cfg.rubbishResMin) stringValue];
    self.rubbishResMax.stringValue = [@(cfg.rubbishResMax) stringValue];
    
    self.genjs.state = cfg.genjs ? NSOnState : NSOffState;
    self.genlua.state = cfg.genlua ? NSOnState : NSOffState;
    self.insertLuaCocos.state = cfg.insertLuaCocos ? NSOnState : NSOffState;
}

- (void) saveCfg
{
    [self setToCurrentCfg];
    UserConfig * cfg = [UserConfig sharedInstance];
    [cfg save];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadFromCfg];
    [self refreshImageMode];
    self.log.toolTip =[NSString stringWithFormat:@"日志存储目录:%@", [FileLogger defaultLogsDirectory]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onXcodePathChanged) name:NSControlTextDidChangeNotification object:self.xcodePath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.codePath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.luaFolder];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.resFolder];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.prob];
    [self prefixDidChange];
}

- (IBAction)onLogChanged:(NSButton *)sender {
    [UserConfig sharedInstance].saveLog = self.log.state == NSOnState;
    [FileLogger loggerEnabled:[UserConfig sharedInstance].saveLog];
}

- (IBAction)on__FILE__Changed:(NSButton *)sender {
    BOOL isOpen = self.isAddFileReDefine.state == NSOnState;
    if(isOpen) {
        self.useKiwi.state = NSOffState;
    }
}

- (IBAction)onKiwiChanged:(NSButton *)sender {
    BOOL isOpen = self.useKiwi.state == NSOnState;
    if(isOpen) {
        self.isAddFileReDefine.state = NSOffState;
    }
}

- (void) onXcodePathChanged {
    self.backupFolder.stringValue = [self.xcodePath.stringValue stringByDeletingLastPathComponent];
    [self prefixDidChange];
}

- (void) refreshImageMode {
    switch (self.imgMode.indexOfSelectedItem) {
        case PngQuant:
            [self.pngquantSpeed setHidden:false];
            break;
        default:
            [self.pngquantSpeed setHidden:true];
            break;
    }
}

- (IBAction)imageModeChanged:(NSButton *)sender {
    [self refreshImageMode];
}

- (void)prefixDidChange {
    BOOL isXcodeOK = [self.xcodePath.stringValue length] > 0;
    BOOL isCodeOK1 = [self.codePath.stringValue length] > 0;
    BOOL isCodeOK2 = [self.luaFolder.stringValue length] > 0;
    BOOL isCodeOK3 = [self.resFolder.stringValue length] > 0;
    BOOL isProbOK = [self.prob.stringValue length] > 0;
    self.statusLabel.textColor = [NSColor greenColor];
    self.startBtn.enabled = isProbOK && (isXcodeOK || isCodeOK1 || isCodeOK2 || isCodeOK3);
    if(!isInProcess){
        self.statusLabel.stringValue = self.startBtn.enabled ? @"可以进行混淆了" : @"等待设置完成";
        self.statusLabel.textColor = self.startBtn.enabled ? [NSColor greenColor] : [NSColor redColor];
    }
}
- (IBAction)onClickOpenLogFolder:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openFile:[FileLogger defaultLogsDirectory]];
}

- (IBAction)onClickRevertConfig:(NSButton *)sender {
    [[UserConfig sharedInstance] revertToDefaultConfig];
    [self loadFromCfg];
}

- (IBAction)onClickLoadConfig:(NSButton *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.prompt = @"选择";
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        if([[UserConfig sharedInstance] loadFromJson:openPanel.URLs.firstObject.path]) {
            [self loadFromCfg];
        } else {
            self.statusLabel.stringValue = @"加载配置错误。";
        }
    }];
}

- (IBAction)onClickSaveConfig:(NSButton *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.prompt = @"保存";
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        [self setToCurrentCfg];
        NSString * fileName = [openPanel.URLs.firstObject.path stringByAppendingPathComponent:@"appConfig.json"];
        [[UserConfig sharedInstance] saveToFile:fileName];
    }];
}

- (IBAction)startObf:(NSButton *)sender {
    [self saveCfg];
    isInProcess = true;
    self.startBtn.enabled = false;
    self.statusLabel.stringValue = @"正在处理中...";
    self.statusLabel.textColor = [NSColor redColor];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [ProjectObf obf];
        dispatch_async(dispatch_get_main_queue(), ^{
            isInProcess = false;
            self.startBtn.enabled = true;
            self.statusLabel.stringValue = @"处理完成";
            self.statusLabel.textColor = [NSColor greenColor];
        });
    });
    
}

@end
