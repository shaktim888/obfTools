#import <Foundation/Foundation.h>
#import "FileLogger.h"
#import <sys/xattr.h>

unsigned long long const kDDDefaultLogMaxFileSize      = 1024 * 1024;      // 1 MB
NSTimeInterval     const kDDDefaultLogRollingFrequency = 60 * 60 * 24;     // 24 Hours
NSUInteger         const kDDDefaultLogMaxNumLogFiles   = 5;                // 5 Files
unsigned long long const kDDDefaultLogFilesDiskQuota   = 20 * 1024 * 1024; // 20 MB

@interface LogFileInfo : NSObject

@property (strong, nonatomic, readonly) NSString *filePath;
@property (strong, nonatomic, readonly) NSString *fileName;

#if FOUNDATION_SWIFT_SDK_EPOCH_AT_LEAST(8)
@property (strong, nonatomic, readonly) NSDictionary<NSFileAttributeKey, id> *fileAttributes;
#else
@property (strong, nonatomic, readonly) NSDictionary<NSString *, id> *fileAttributes;
#endif

@property (strong, nonatomic, readonly) NSDate *creationDate;
@property (strong, nonatomic, readonly) NSDate *modificationDate;

@property (nonatomic, readonly) unsigned long long fileSize;

@property (nonatomic, readonly) NSTimeInterval age;

@property (nonatomic, readwrite) BOOL isArchived;

+ (instancetype)logFileWithPath:(NSString *)filePath NS_SWIFT_UNAVAILABLE("Use init(filePath:)");

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

- (void)reset;
- (void)renameFile:(NSString *)newFileName NS_SWIFT_NAME(renameFile(to:));

#if TARGET_IPHONE_SIMULATOR

// So here's the situation.
// Extended attributes are perfect for what we're trying to do here (marking files as archived).
// This is exactly what extended attributes were designed for.
//
// But Apple screws us over on the simulator.
// Everytime you build-and-go, they copy the application into a new folder on the hard drive,
// and as part of the process they strip extended attributes from our log files.
// Normally, a copy of a file preserves extended attributes.
// So obviously Apple has gone to great lengths to piss us off.
//
// Thus we use a slightly different tactic for marking log files as archived in the simulator.
// That way it "just works" and there's no confusion when testing.
//
// The difference in method names is indicative of the difference in functionality.
// On the simulator we add an attribute by appending a filename extension.
//
// For example:
// "mylog.txt" -> "mylog.archived.txt"
// "mylog"     -> "mylog.archived"

- (BOOL)hasExtensionAttributeWithName:(NSString *)attrName;

- (void)addExtensionAttributeWithName:(NSString *)attrName;
- (void)removeExtensionAttributeWithName:(NSString *)attrName;

#else /* if TARGET_IPHONE_SIMULATOR */

// Normal use of extended attributes used everywhere else,
// such as on Macs and on iPhone devices.

- (BOOL)hasExtendedAttributeWithName:(NSString *)attrName;

- (void)addExtendedAttributeWithName:(NSString *)attrName;
- (void)removeExtendedAttributeWithName:(NSString *)attrName;

#endif /* if TARGET_IPHONE_SIMULATOR */

- (NSComparisonResult)reverseCompareByCreationDate:(LogFileInfo *)another;
- (NSComparisonResult)reverseCompareByModificationDate:(LogFileInfo *)another;

@end

#if TARGET_IPHONE_SIMULATOR
static NSString * const kDDXAttrArchivedName = @"archived";
#else
static NSString * const kDDXAttrArchivedName = @"lumberjack.log.archived";
#endif

@interface LogFileInfo () {
    __strong NSString *_filePath;
    __strong NSString *_fileName;
    
    __strong NSDictionary *_fileAttributes;
    
    __strong NSDate *_creationDate;
    __strong NSDate *_modificationDate;
    
    unsigned long long _fileSize;
}

@end

@implementation LogFileInfo

@synthesize filePath;

@dynamic fileName;
@dynamic fileAttributes;
@dynamic creationDate;
@dynamic modificationDate;
@dynamic fileSize;
@dynamic age;

@dynamic isArchived;


#pragma mark Lifecycle

+ (instancetype)logFileWithPath:(NSString *)aFilePath {
    return [[self alloc] initWithFilePath:aFilePath];
}

- (instancetype)initWithFilePath:(NSString *)aFilePath {
    if ((self = [super init])) {
        filePath = [aFilePath copy];
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Standard Info
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)fileAttributes {
    if (_fileAttributes == nil && filePath != nil) {
        NSError *error = nil;
        _fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        
        if (error) {
            NSLog(@"LogFileInfo: Failed to read file attributes: %@", error);
        }
    }
    
    return _fileAttributes ?: @{};
}

- (NSString *)fileName {
    if (_fileName == nil) {
        _fileName = [filePath lastPathComponent];
    }
    
    return _fileName;
}

- (NSDate *)modificationDate {
    if (_modificationDate == nil) {
        _modificationDate = self.fileAttributes[NSFileModificationDate];
    }
    
    return _modificationDate;
}

- (NSDate *)creationDate {
    if (_creationDate == nil) {
        _creationDate = self.fileAttributes[NSFileCreationDate];
    }
    
    return _creationDate;
}

- (unsigned long long)fileSize {
    if (_fileSize == 0) {
        _fileSize = [self.fileAttributes[NSFileSize] unsignedLongLongValue];
    }
    
    return _fileSize;
}

- (NSTimeInterval)age {
    return -[[self creationDate] timeIntervalSinceNow];
}

- (NSString *)description {
    return [@{ @"filePath": self.filePath ? : @"",
               @"fileName": self.fileName ? : @"",
               @"fileAttributes": self.fileAttributes ? : @"",
               @"creationDate": self.creationDate ? : @"",
               @"modificationDate": self.modificationDate ? : @"",
               @"fileSize": @(self.fileSize),
               @"age": @(self.age),
               @"isArchived": @(self.isArchived) } description];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Archiving
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isArchived {
#if TARGET_IPHONE_SIMULATOR
    
    // Extended attributes don't work properly on the simulator.
    // So we have to use a less attractive alternative.
    // See full explanation in the header file.
    
    return [self hasExtensionAttributeWithName:kDDXAttrArchivedName];
    
#else
    
    return [self hasExtendedAttributeWithName:kDDXAttrArchivedName];
    
#endif
}

- (void)setIsArchived:(BOOL)flag {
#if TARGET_IPHONE_SIMULATOR
    
    // Extended attributes don't work properly on the simulator.
    // So we have to use a less attractive alternative.
    // See full explanation in the header file.
    
    if (flag) {
        [self addExtensionAttributeWithName:kDDXAttrArchivedName];
    } else {
        [self removeExtensionAttributeWithName:kDDXAttrArchivedName];
    }
    
#else
    
    if (flag) {
        [self addExtendedAttributeWithName:kDDXAttrArchivedName];
    } else {
        [self removeExtendedAttributeWithName:kDDXAttrArchivedName];
    }
    
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Changes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)reset {
    _fileName = nil;
    _fileAttributes = nil;
    _creationDate = nil;
    _modificationDate = nil;
}

- (void)renameFile:(NSString *)newFileName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.
    
    if (![newFileName isEqualToString:[self fileName]]) {
        NSString *fileDir = [filePath stringByDeletingLastPathComponent];
        NSString *newFilePath = [fileDir stringByAppendingPathComponent:newFileName];
        
#ifdef DEBUG
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fileDir isDirectory:&directory];
        NSAssert(directory, @"Containing directory must exist.");
#endif
        
        NSError *error = nil;
        
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:newFilePath error:&error];
        if (!success && error.code != NSFileNoSuchFileError) {
            NSLog(@"LogFileInfo: Error deleting archive (%@): %@", self.fileName, error);
        }
        
        success = [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newFilePath error:&error];
        
        // When a log file is deleted, moved or renamed on the simulator, we attempt to rename it as a
        // result of "archiving" it, but since the file doesn't exist anymore, needless error logs are printed
        // We therefore ignore this error, and assert that the directory we are copying into exists (which
        // is the only other case where this error code can come up).
#if TARGET_IPHONE_SIMULATOR
        if (!success && error.code != NSFileNoSuchFileError)
#else
            if (!success)
#endif
            {
                NSLog(@"LogFileInfo: Error renaming file (%@): %@", self.fileName, error);
            }
        
        filePath = newFilePath;
        [self reset];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Attribute Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_IPHONE_SIMULATOR

// Extended attributes don't work properly on the simulator.
// So we have to use a less attractive alternative.
// See full explanation in the header file.

- (BOOL)hasExtensionAttributeWithName:(NSString *)attrName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.
    
    // Split the file name into components. File name may have various format, but generally
    // structure is same:
    //
    // <name part>.<extension part> and <name part>.archived.<extension part>
    // or
    // <name part> and <name part>.archived
    //
    // So we want to search for the attrName in the components (ignoring the first array index).
    
    NSArray *components = [[self fileName] componentsSeparatedByString:@"."];
    
    // Watch out for file names without an extension
    
    for (NSUInteger i = 1; i < components.count; i++) {
        NSString *attr = components[i];
        
        if ([attrName isEqualToString:attr]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)addExtensionAttributeWithName:(NSString *)attrName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.
    
    if ([attrName length] == 0) {
        return;
    }
    
    // Example:
    // attrName = "archived"
    //
    // "mylog.txt" -> "mylog.archived.txt"
    // "mylog"     -> "mylog.archived"
    
    NSArray *components = [[self fileName] componentsSeparatedByString:@"."];
    
    NSUInteger count = [components count];
    
    NSUInteger estimatedNewLength = [[self fileName] length] + [attrName length] + 1;
    NSMutableString *newFileName = [NSMutableString stringWithCapacity:estimatedNewLength];
    
    if (count > 0) {
        [newFileName appendString:components.firstObject];
    }
    
    NSString *lastExt = @"";
    
    NSUInteger i;
    
    for (i = 1; i < count; i++) {
        NSString *attr = components[i];
        
        if ([attr length] == 0) {
            continue;
        }
        
        if ([attrName isEqualToString:attr]) {
            // Extension attribute already exists in file name
            return;
        }
        
        if ([lastExt length] > 0) {
            [newFileName appendFormat:@".%@", lastExt];
        }
        
        lastExt = attr;
    }
    
    [newFileName appendFormat:@".%@", attrName];
    
    if ([lastExt length] > 0) {
        [newFileName appendFormat:@".%@", lastExt];
    }
    
    [self renameFile:newFileName];
}

- (void)removeExtensionAttributeWithName:(NSString *)attrName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.
    
    if ([attrName length] == 0) {
        return;
    }
    
    // Example:
    // attrName = "archived"
    //
    // "mylog.archived.txt" -> "mylog.txt"
    // "mylog.archived"     -> "mylog"
    
    NSArray *components = [[self fileName] componentsSeparatedByString:@"."];
    
    NSUInteger count = [components count];
    
    NSUInteger estimatedNewLength = [[self fileName] length];
    NSMutableString *newFileName = [NSMutableString stringWithCapacity:estimatedNewLength];
    
    if (count > 0) {
        [newFileName appendString:components.firstObject];
    }
    
    BOOL found = NO;
    
    NSUInteger i;
    
    for (i = 1; i < count; i++) {
        NSString *attr = components[i];
        
        if ([attrName isEqualToString:attr]) {
            found = YES;
        } else {
            [newFileName appendFormat:@".%@", attr];
        }
    }
    
    if (found) {
        [self renameFile:newFileName];
    }
}

#else /* if TARGET_IPHONE_SIMULATOR */

- (BOOL)hasExtendedAttributeWithName:(NSString *)attrName {
    const char *path = [filePath UTF8String];
    const char *name = [attrName UTF8String];
    
    ssize_t result = getxattr(path, name, NULL, 0, 0, 0);
    
    return (result >= 0);
}

- (void)addExtendedAttributeWithName:(NSString *)attrName {
    const char *path = [filePath UTF8String];
    const char *name = [attrName UTF8String];
    
    int result = setxattr(path, name, NULL, 0, 0, 0);
    
    if (result < 0) {
        NSLog(@"LogFileInfo: setxattr(%@, %@): error = %s",
              attrName,
              filePath,
              strerror(errno));
    }
}

- (void)removeExtendedAttributeWithName:(NSString *)attrName {
    const char *path = [filePath UTF8String];
    const char *name = [attrName UTF8String];
    
    int result = removexattr(path, name, 0);
    
    if (result < 0 && errno != ENOATTR) {
        NSLog(@"LogFileInfo: removexattr(%@, %@): error = %s",
              attrName,
              self.fileName,
              strerror(errno));
    }
}

#endif /* if TARGET_IPHONE_SIMULATOR */

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Comparisons
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        LogFileInfo *another = (LogFileInfo *)object;
        
        return [filePath isEqualToString:[another filePath]];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return [filePath hash];
}

- (NSComparisonResult)reverseCompareByCreationDate:(LogFileInfo *)another {
    __auto_type us = [self creationDate];
    __auto_type them = [another creationDate];
    return [them compare:us];
}

- (NSComparisonResult)reverseCompareByModificationDate:(LogFileInfo *)another {
    __auto_type us = [self modificationDate];
    __auto_type them = [another modificationDate];
    return [them compare:us];
}

@end

@interface FileLogger() {
    NSUInteger _maximumNumberOfLogFiles;
    unsigned long long _logFilesDiskQuota;
    NSString *_logsDirectory;
#if TARGET_OS_IPHONE
    NSFileProtectionType _defaultFileProtectionLevel;
#endif
    
    NSTimeInterval _rollingFrequency;
    
    unsigned long long _maximumFileSize;
    FILE * _stdoutHandler;
    FILE * _stderrHandler;
}

@property (readwrite, assign, atomic) NSUInteger maximumNumberOfLogFiles;

@property (readwrite, assign, atomic) unsigned long long logFilesDiskQuota;

@end

@implementation FileLogger



@synthesize maximumNumberOfLogFiles = _maximumNumberOfLogFiles;
@synthesize logFilesDiskQuota = _logFilesDiskQuota;

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithLogsDirectory:nil];
    });
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _maximumFileSize = kDDDefaultLogMaxFileSize;
        _rollingFrequency = kDDDefaultLogRollingFrequency;
    }
    return self;
}

- (void) setLoggerEnabled : (BOOL) val {
    if(val) {
        if(_stdoutHandler || _stderrHandler) {
            return;
        }
        NSString * logFilePath = [self getLogFile];
        _stdoutHandler = freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
        _stderrHandler = freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
        NSLog(@"日志记录开启。");
    } else {
        if(_stdoutHandler || _stderrHandler) {
            NSLog(@"日志记录关闭。");
            if(_stdoutHandler) {
                fclose(_stdoutHandler);
                _stdoutHandler = NULL;
            }
            if(_stderrHandler){
                fclose(_stderrHandler);
                _stderrHandler = NULL;
            }
        }
    }
}

- (NSString *) getLogFile {
    
    // Check if we're resuming and if so, get the first of the sorted log file infos.
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
    LogFileInfo * newCurrentLogFile = sortedLogFileInfos.firstObject;
    
    // Check if the file we've found is still valid. Otherwise create a new one.
    if (newCurrentLogFile != nil && [self shouldUseLogFile:newCurrentLogFile]) {
        return newCurrentLogFile.filePath;
    } else {
        return [self createNewLogFile];
    }
}

- (NSString *)defaultLogsDirectory {
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];
#else
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    NSString *logsDirectory = [[basePath stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:appName];
#endif
    NSLog(@"日志存储地址:%@", logsDirectory);
    return logsDirectory;
}

- (instancetype)initWithLogsDirectory:(NSString * __nullable)aLogsDirectory {
    if ((self = [self init])) {
        _maximumNumberOfLogFiles = kDDDefaultLogMaxNumLogFiles;
        _logFilesDiskQuota = kDDDefaultLogFilesDiskQuota;
        
        if (aLogsDirectory.length > 0) {
            _logsDirectory = [aLogsDirectory copy];
        } else {
            _logsDirectory = [[self defaultLogsDirectory] copy];
        }
        
        NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
        
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(maximumNumberOfLogFiles)) options:kvoOptions context:nil];
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(logFilesDiskQuota)) options:kvoOptions context:nil];
        
        NSLog(@"FileLogger: logsDirectory:\n%@", [self logsDirectory]);
        NSLog(@"FileLogger: sortedLogFileNames:\n%@", [self sortedLogFileNames]);
    }
    
    return self;
}

- (NSString *)newLogFileName {
    NSString *appName = [self applicationName];
    
    NSDateFormatter *dateFormatter = [self logFileDateFormatter];
    NSString *formattedDate = [dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat:@"%@ %@.log", appName, formattedDate];
}

- (NSArray *)sortedLogFileNames {
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
    
    NSMutableArray *sortedLogFileNames = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];
    
    for (LogFileInfo *logFileInfo in sortedLogFileInfos) {
        [sortedLogFileNames addObject:[logFileInfo fileName]];
    }
    
    return sortedLogFileNames;
}

- (NSString *)logsDirectory {
    // We could do this check once, during initialization, and not bother again.
    // But this way the code continues to work if the directory gets deleted while the code is running.
    
    NSAssert(_logsDirectory.length > 0, @"Directory must be set.");
    
    NSError *err = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:_logsDirectory
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&err];
    if (success == NO) {
        NSLog(@"FileLogger: Error creating logsDirectory: %@", err);
    }
    
    return _logsDirectory;
}

- (NSString * __nullable)logFileHeader {
    return nil;
}

- (NSData *)logFileHeaderData {
    NSString *fileHeaderStr = [self logFileHeader];
    
    if (fileHeaderStr.length == 0) {
        return nil;
    }
    
    if (![fileHeaderStr hasSuffix:@"\n"]) {
        fileHeaderStr = [fileHeaderStr stringByAppendingString:@"\n"];
    }
    
    return [fileHeaderStr dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)shouldLogFileBeArchived:(LogFileInfo *)mostRecentLogFileInfo {
    if (mostRecentLogFileInfo.isArchived) {
        return NO;
    } else if (_maximumFileSize > 0 && mostRecentLogFileInfo.fileSize >= _maximumFileSize) {
        return YES;
    } else if (_rollingFrequency > 0.0 && mostRecentLogFileInfo.age >= _rollingFrequency) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldUseLogFile:(nonnull LogFileInfo *)logFileInfo  {
    
    // Check if the log file is archived. We must not use archived log files.
    if (logFileInfo.isArchived) {
        return NO;
    }
    
    // If we're resuming, we need to check if the log file is allowed for reuse or needs to be archived.
    if ([self shouldLogFileBeArchived:logFileInfo]) {
        logFileInfo.isArchived = YES;
        return NO;
    }
    
    // All checks have passed. It's valid.
    return YES;
}

- (NSString *)createNewLogFile {
    static NSUInteger MAX_ALLOWED_ERROR = 5;
    
    NSString *fileName = [self newLogFileName];
    NSString *logsDirectory = [self logsDirectory];
    NSData *fileHeader = [self logFileHeaderData];
    if (fileHeader == nil) {
        fileHeader = [NSData new];
    }
    
    NSUInteger attempt = 1;
    NSUInteger criticalErrors = 0;
    
    do {
        if (criticalErrors >= MAX_ALLOWED_ERROR) {
            NSLog(@"FileLogger: Bailing file creation, encountered %ld errors.",
                  (unsigned long)criticalErrors);
            return nil;
        }
        
        NSString *actualFileName = fileName;
        
        if (attempt > 1) {
            NSString *extension = [actualFileName pathExtension];
            
            actualFileName = [actualFileName stringByDeletingPathExtension];
            actualFileName = [actualFileName stringByAppendingFormat:@" %lu", (unsigned long)attempt];
            
            if (extension.length) {
                actualFileName = [actualFileName stringByAppendingPathExtension:extension];
            }
        }
        
        NSString *filePath = [logsDirectory stringByAppendingPathComponent:actualFileName];
        
        NSError *error = nil;
        BOOL success = [fileHeader writeToFile:filePath options:NSAtomicWrite error:&error];
        
#if TARGET_OS_IPHONE
        if (success) {
            // When creating log file on iOS we're setting NSFileProtectionKey attribute to NSFileProtectionCompleteUnlessOpen.
            //
            // But in case if app is able to launch from background we need to have an ability to open log file any time we
            // want (even if device is locked). Thats why that attribute have to be changed to
            // NSFileProtectionCompleteUntilFirstUserAuthentication.
            NSDictionary *attributes = @{NSFileProtectionKey: [self logFileProtection]};
            success = [[NSFileManager defaultManager] setAttributes:attributes
                                                       ofItemAtPath:filePath
                                                              error:&error];
        }
#endif
        
        if (success) {
            NSLog(@"PURLogFileManagerDefault: Created new log file: %@", actualFileName);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Since we just created a new log file, we may need to delete some old log files
                [self deleteOldLogFiles];
            });
            return filePath;
        } else if (error.code == NSFileWriteFileExistsError) {
            attempt++;
            continue;
        } else {
            NSLog(@"PURLogFileManagerDefault: Critical error while creating log file: %@", error);
            criticalErrors++;
            continue;
        }
        
        return filePath;
    } while (YES);
}

- (NSDateFormatter *)logFileDateFormatter {
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSString *dateFormat = @"yyyy'-'MM'-'dd'--'HH'-'mm'-'ss'-'SSS'";
    NSString *key = [NSString stringWithFormat:@"logFileDateFormatter.%@", dateFormat];
    NSDateFormatter *dateFormatter = dictionary[key];
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:dateFormat];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        dictionary[key] = dateFormatter;
    }
    
    return dateFormatter;
}

- (NSString *)applicationName {
    static NSString *_appName;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        
        if (_appName.length == 0) {
            _appName = [[NSProcessInfo processInfo] processName];
        }
        
        if (_appName.length == 0) {
            _appName = @"";
        }
    });
    
    return _appName;
}

- (BOOL)isLogFile:(NSString *)fileName {
    NSString *appName = [self applicationName];
    
    // We need to add a space to the name as otherwise we could match applications that have the name prefix.
    BOOL hasProperPrefix = [fileName hasPrefix:[appName stringByAppendingString:@" "]];
    BOOL hasProperSuffix = [fileName hasSuffix:@".log"];
    
    return (hasProperPrefix && hasProperSuffix);
}

- (NSArray *)unsortedLogFilePaths {
    NSString *logsDirectory = [self logsDirectory];
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil];
    
    NSMutableArray *unsortedLogFilePaths = [NSMutableArray arrayWithCapacity:[fileNames count]];
    
    for (NSString *fileName in fileNames) {
        // Filter out any files that aren't log files. (Just for extra safety)
        
#if TARGET_IPHONE_SIMULATOR
        // In case of iPhone simulator there can be 'archived' extension. isLogFile:
        // method knows nothing about it. Thus removing it for this method.
        //
        // See full explanation in the header file.
        NSString *theFileName = [fileName stringByReplacingOccurrencesOfString:@".archived"
                                                                    withString:@""];
        
        if ([self isLogFile:theFileName])
#else
            
            if ([self isLogFile:fileName])
#endif
            {
                NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
                
                [unsortedLogFilePaths addObject:filePath];
            }
    }
    
    return unsortedLogFilePaths;
}

- (NSArray *)unsortedLogFileInfos {
    NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];
    
    NSMutableArray *unsortedLogFileInfos = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];
    
    for (NSString *filePath in unsortedLogFilePaths) {
        LogFileInfo *logFileInfo = [[LogFileInfo alloc] initWithFilePath:filePath];
        
        [unsortedLogFileInfos addObject:logFileInfo];
    }
    
    return unsortedLogFileInfos;
}

- (NSArray *)sortedLogFileInfos {
    return [[self unsortedLogFileInfos] sortedArrayUsingComparator:^NSComparisonResult(LogFileInfo *obj1,
                                                                                       LogFileInfo *obj2) {
        NSDate *date1 = [NSDate new];
        NSDate *date2 = [NSDate new];
        
        NSArray<NSString *> *arrayComponent = [[obj1 fileName] componentsSeparatedByString:@" "];
        if (arrayComponent.count > 0) {
            NSString *stringDate = arrayComponent.lastObject;
            stringDate = [stringDate stringByReplacingOccurrencesOfString:@".log" withString:@""];
            stringDate = [stringDate stringByReplacingOccurrencesOfString:@".archived" withString:@""];
            date1 = [[self logFileDateFormatter] dateFromString:stringDate] ?: [obj1 creationDate];
        }
        
        arrayComponent = [[obj2 fileName] componentsSeparatedByString:@" "];
        if (arrayComponent.count > 0) {
            NSString *stringDate = arrayComponent.lastObject;
            stringDate = [stringDate stringByReplacingOccurrencesOfString:@".log" withString:@""];
            stringDate = [stringDate stringByReplacingOccurrencesOfString:@".archived" withString:@""];
            date2 = [[self logFileDateFormatter] dateFromString:stringDate] ?: [obj2 creationDate];
        }
        
        return [date2 compare:date1 ?: [NSDate new]];
    }];
    
}

- (void)deleteOldLogFiles {
    NSLog(@"FileLogger: deleteOldLogFiles");
    
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
    NSUInteger firstIndexToDelete = NSNotFound;
    
    const unsigned long long diskQuota = self.logFilesDiskQuota;
    const NSUInteger maxNumLogFiles = self.maximumNumberOfLogFiles;
    
    if (diskQuota) {
        unsigned long long used = 0;
        
        for (NSUInteger i = 0; i < sortedLogFileInfos.count; i++) {
            LogFileInfo *info = sortedLogFileInfos[i];
            used += info.fileSize;
            
            if (used > diskQuota) {
                firstIndexToDelete = i;
                break;
            }
        }
    }
    
    if (maxNumLogFiles) {
        if (firstIndexToDelete == NSNotFound) {
            firstIndexToDelete = maxNumLogFiles;
        } else {
            firstIndexToDelete = MIN(firstIndexToDelete, maxNumLogFiles);
        }
    }
    
    if (firstIndexToDelete == 0) {
        // Do we consider the first file?
        // We are only supposed to be deleting archived files.
        // In most cases, the first file is likely the log file that is currently being written to.
        // So in most cases, we do not want to consider this file for deletion.
        
        if (sortedLogFileInfos.count > 0) {
            LogFileInfo *logFileInfo = sortedLogFileInfos[0];
            
            if (!logFileInfo.isArchived) {
                // Don't delete active file.
                ++firstIndexToDelete;
            }
        }
    }
    
    if (firstIndexToDelete != NSNotFound) {
        // removing all log files starting with firstIndexToDelete
        
        for (NSUInteger i = firstIndexToDelete; i < sortedLogFileInfos.count; i++) {
            LogFileInfo *logFileInfo = sortedLogFileInfos[i];
            
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:&error];
            if (success) {
                NSLog(@"FileLogger: Deleting file: %@", logFileInfo.fileName);
            } else {
                NSLog(@"FileLogger: Error deleting file %@", error);
            }
        }
    }
}


+ (void) loggerEnabled : (BOOL) val
{
    [[self sharedInstance] setLoggerEnabled:val];
}

+(NSString *)defaultLogsDirectory
{
    return [[self sharedInstance] defaultLogsDirectory];
}

@end
