#import <Foundation/Foundation.h>
#import "HYImageToolViewController.h"
#import "ImageObf.h"

@interface HYImageToolViewController()

@property (weak) IBOutlet NSTextField *jsonPath;
@property (weak) IBOutlet NSTextField *imagePath;
@property (weak) IBOutlet NSTextField *jsonContent;

@property (weak) IBOutlet NSButton *encodeBtn;
@property (weak) IBOutlet NSButton *decodeBtn;

@end

@implementation HYImageToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.jsonPath.stringValue = @"";
    self.imagePath.stringValue = @"";
    self.jsonContent.stringValue = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.jsonPath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.imagePath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixDidChange) name:NSControlTextDidChangeNotification object:self.jsonContent];
    [self prefixDidChange];
}

- (void)prefixDidChange {
    BOOL isJsonOK = [self.jsonPath.stringValue length] > 0;
    BOOL isImageOK = [self.imagePath.stringValue length] > 0;
    _encodeBtn.enabled = isJsonOK && isImageOK;
    _decodeBtn.enabled = isImageOK;
}

- (IBAction)startEncode:(NSButton *)sender {
    [ImageObf encodeImg:_jsonPath.stringValue img:_imagePath.stringValue];
}

- (IBAction)startDecode:(NSButton *)sender {
    NSString * str = [ImageObf decodeImg:_imagePath.stringValue];
    _jsonContent.stringValue = str;
}

@end
