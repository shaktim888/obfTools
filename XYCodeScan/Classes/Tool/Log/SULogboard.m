#import "SULogboard.h"

@interface SULogboard ()

@property (nonatomic, strong) NSTextView * logTextView;

@end

@implementation SULogboard

- (void)viewDidLoad {
    self.logTextView = [[NSTextView alloc]initWithFrame:self.view.bounds];
    self.logTextView.backgroundColor = [NSColor darkGrayColor];
    self.logTextView.textColor = [NSColor whiteColor];
    self.logTextView.font = [NSFont systemFontOfSize:15.0];
    self.logTextView.editable = NO;
    self.logTextView.layoutManager.allowsNonContiguousLayout = NO; //default is YES  will reset scoll contentoffset
    [self.view addSubview:self.logTextView];
}

- (void)updateLog:(NSString *)logText {
    if (self.logTextView.frame.size.height - (self.logTextView.frame.origin.y + CGRectGetHeight(self.view.bounds)) <= 30 ) {
        self.logTextView.string = logText;
        [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.textContainer.size.height, 1)];
    }else {
        self.logTextView.string = logText;
    }
}


@end
