#ifndef FileLogger_h
#define FileLogger_h

@interface FileLogger : NSObject

+ (void) loggerEnabled : (BOOL) val;
+(NSString *)defaultLogsDirectory;

@end

#endif /* FileLogger_h */
