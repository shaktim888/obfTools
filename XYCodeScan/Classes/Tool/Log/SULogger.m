#import "SULogger.h"
#import "SULogboard.h"
#import "FileLogger.h"

@interface SULogger ()
@property (nonatomic , strong) NSWindow * popWindow;
@property (nonatomic, strong) SULogboard * logboard;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation SULogger

+ (instancetype)logger {
    static SULogger * logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[SULogger alloc]init];
    });
    return logger;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupWithFrame:NSMakeRect([NSScreen mainScreen].frame.size.width / 2 - 75, 200, 200, 200)];
    }
    return self;
}

-(void)setupWithFrame:(NSRect)frame {
    self.popWindow = [[NSWindow alloc]initWithContentRect:frame styleMask:NSWindowStyleMaskFullSizeContentView backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]];
    SULogboard *vc = [[SULogboard alloc] init];
    self.popWindow.contentViewController = vc;
    self.popWindow.backgroundColor = [NSColor blackColor];
    self.popWindow.opaque = NO;
    self.popWindow.hasShadow = NO;
    [self.popWindow setReleasedWhenClosed:NO];
}

- (void)startSaveLog {

    //file path

//    NSString * logPath = [FileLogger defaultLogsDirectory];
    //delete exisist file
//    [[NSFileManager defaultManager]removeItemAtPath:logPath error:nil];
    
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"SIMULATOR DEVICE");
#else
    //export log to file
//    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout); //c printf
//    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr); //oc  NSLog
#endif
    
}

- (void)loadLog {
    //file path
    NSString * logPath = [FileLogger defaultLogsDirectory];
    //load data
    NSData * logData = [NSData dataWithContentsOfFile:logPath];
    NSString * logText = [[NSString alloc]initWithData:logData encoding:NSUTF8StringEncoding];
    //update text
    [self.logboard updateLog:logText];
}


- (void)show {
    [self.popWindow orderFront:nil];
    //add timer to update log
    [self loadLog];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadLog) userInfo:nil repeats:YES];
}

- (void)hide {
    //animation hide
    [self.popWindow.animator close];
    //release timer
    [self.timer invalidate];
    self.timer = nil;
}

+ (void)start {
    [[SULogger logger] startSaveLog];
}

+ (void)visibleChange {
    SULogger * logger = [SULogger logger];
    logger.timer ? [logger hide] : [logger show];
}

@end
