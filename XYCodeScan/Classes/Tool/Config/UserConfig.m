#import <Foundation/Foundation.h>

#import "UserConfig.h"
#import "NSFileManager+Extension.h"
#import "NSString+Extension.h"

static NSString * STORE_KEY = @"APP_CONFIG";
@interface UserConfig ()
{
}

@end

@implementation UserConfig

- (NSMutableDictionary *) getDefaultConfig
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    dict[@"xcodePath"] = @"";
    dict[@"codePath"] = @"";
    dict[@"targets"] = @"";
    dict[@"backupPath"] = @"";
    dict[@"luaFolder"] = @"";
    dict[@"resFolder"] = @"";
    dict[@"customIgnoreFile"] = @"";
    dict[@"prop"] = @(50);
    dict[@"scanProjectCode"] = @(true);
    dict[@"isLuaCode"] = @(true);
    dict[@"isUglifyLua"] = @(false);
    dict[@"isMinifyLua"] = @(false);
    dict[@"imageMode"] = @(4);
    dict[@"encodeCString"] = @(true);
    dict[@"encodeNSString"] = @(true);
    dict[@"insertFunction"] = @(true);
    dict[@"insertCode"] = @(true);
    dict[@"addProperty"] = @(true);
    dict[@"scanType"] = @(true);
    dict[@"scanFunc"] = @(true);
    dict[@"scanVar"] = @(true);
    dict[@"scanProp"] = @(false);
    dict[@"addRubishRes"] = @(true);
    dict[@"modifyFileName"] = @(true);
    dict[@"jsObf"] = @(false);
    dict[@"mmd5"] = @(true);
    dict[@"backup"] = @(true);
    dict[@"skipOptimize"] = @(false);
    dict[@"autoRenameDefine"] = @(true);
    dict[@"scanXib"] = @(true);
    dict[@"saveLog"] = @(false);
    dict[@"isAddCpp"] = @(true);
    dict[@"isAddOC"] = @(true);
    dict[@"addOCNum"] = @(0);
    dict[@"addCppNum"] = @(0);
    dict[@"addCppFile"] = @(-1);
    dict[@"addOCFile"] = @(-1);
    dict[@"isUnity"] = @(false);
    dict[@"addMethodNum"] = @(100);
    dict[@"OCWeight"] = @(3);
    dict[@"stringWeight"] = @(1);
    dict[@"stringWordMin"] = @(1);
    dict[@"stringWordMax"] = @(3);
    dict[@"pngquantSpeed"] = @(3);
    dict[@"isAddFileReDefine"] = @(true);
    dict[@"useKiwi"] = @(false);
    dict[@"udid"] = @(true);
    
    dict[@"rubbishResMin"] = @(500);
    dict[@"rubbishResMax"] = @(1000);
    
    dict[@"genjs"] = @(false);
    dict[@"genlua"] = @(true);
    dict[@"insertLuaCocos"] = @(true);
    dict[@"groupRename"] = @(false);

    return dict;
}

- (void) loadFromDict : (NSDictionary *) customDict
{
    NSDictionary * dict = [self combineWithDefault:customDict];
    self.xcodePath = dict[@"xcodePath"];
    self.codePath = dict[@"codePath"];
    self.targets = dict[@"targets"];
    self.backupPath = dict[@"backupPath"];
    self.luaFolder = dict[@"luaFolder"];
    self.resFolder = dict[@"resFolder"];
    self.customIgnoreFile = dict[@"customIgnoreFile"];
    self.prop = [dict[@"prop"] intValue];
    self.scanProjectCode = [dict[@"scanProjectCode"] boolValue];
    self.isLuaCode = [dict[@"isLuaCode"] boolValue];
    self.isUglifyLua = [dict[@"isUglifyLua"] boolValue];
    self.isMinifyLua = [dict[@"isMinifyLua"] boolValue];
    self.imageMode = [dict[@"imageMode"] intValue];
    self.encodeCString = [dict[@"encodeCString"] boolValue];
    self.encodeNSString = [dict[@"encodeNSString"] boolValue];
    self.insertFunction = [dict[@"insertFunction"] boolValue];
    self.insertCode = [dict[@"insertCode"] boolValue];
    self.addProperty = [dict[@"addProperty"] boolValue];
    self.scanType = [dict[@"scanType"] boolValue];
    self.scanFunc = [dict[@"scanFunc"] boolValue];
    self.scanVar = [dict[@"scanVar"] boolValue];
    self.scanProp = [dict[@"scanProp"] boolValue];
    self.addRubishRes = [dict[@"addRubishRes"] boolValue];
//    self.modifyFileName = [dict[@"modifyFileName"] boolValue];
    self.jsObf = [dict[@"jsObf"] boolValue];
    self.mmd5 = [dict[@"mmd5"] boolValue];
    self.backup = [dict[@"backup"] boolValue];
    self.skipOptimize = [dict[@"skipOptimize"] boolValue];
    self.autoRenameDefine = [dict[@"autoRenameDefine"] boolValue];
    self.scanXib = [dict[@"scanXib"] boolValue];
    self.saveLog = [dict[@"saveLog"] boolValue];
    self.isAddCpp = [dict[@"isAddCpp"] boolValue];
    self.isAddOC = [dict[@"isAddOC"] boolValue];
    self.addCppNum = [dict[@"addCppNum"] intValue];
    self.addOCNum = [dict[@"addOCNum"] intValue];
    self.isUnity = [dict[@"isUnity"] boolValue];
    self.addMethodNum = [dict[@"addMethodNum"] intValue];
 
    self.OCWeight = [dict[@"OCWeight"] intValue];
    self.stringWeight = [dict[@"stringWeight"] intValue];
    self.stringWordMin = [dict[@"stringWordMin"] intValue];
    self.stringWordMax = [dict[@"stringWordMax"] intValue];
    self.pngquantSpeed = [dict[@"pngquantSpeed"] intValue];
    self.isAddFileReDefine = [dict[@"isAddFileReDefine"] boolValue];
    self.useKiwi = [dict[@"useKiwi"] boolValue];
    self.udid = [dict[@"udid"] boolValue];

    self.rubbishResMin = [dict[@"rubbishResMin"] intValue];
    self.rubbishResMax = [dict[@"rubbishResMax"] intValue];
    
    self.genjs = [dict[@"genjs"] boolValue];
    self.genlua = [dict[@"genlua"] boolValue];
    self.insertLuaCocos = [dict[@"insertLuaCocos"] boolValue];
    self.groupRename = [dict[@"groupRename"] boolValue];
    
}

- (NSDictionary *) combineWithDefault: (NSDictionary *) customDict
{
    NSMutableDictionary * defaultCfg = [self getDefaultConfig];
    if(customDict) {
        for(NSString * key in customDict) {
            defaultCfg[key] = customDict[key];
        }
    }
    return defaultCfg;
}

- (NSDictionary *) serialize
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    
    dict[@"xcodePath"] = self.xcodePath;
    dict[@"codePath"] = self.codePath;
    dict[@"targets"] = self.targets;
    dict[@"backupPath"] = self.backupPath;
    dict[@"luaFolder"] = self.luaFolder;
    dict[@"resFolder"] = self.resFolder;
    dict[@"customIgnoreFile"] = self.customIgnoreFile;
    dict[@"prop"] = @(self.prop);
    dict[@"scanProjectCode"] = @(self.scanProjectCode);
    dict[@"isLuaCode"] = @(self.isLuaCode);
    dict[@"isUglifyLua"] = @(self.isUglifyLua);
    dict[@"isMinifyLua"] = @(self.isMinifyLua);
    dict[@"imageMode"] = @(self.imageMode);
    dict[@"encodeCString"] = @(self.encodeCString);
    dict[@"encodeNSString"] = @(self.encodeNSString);
    dict[@"insertFunction"] = @(self.insertFunction);
    dict[@"insertCode"] = @(self.insertCode);
    dict[@"addProperty"] = @(self.addProperty);
    dict[@"scanType"] = @(self.scanType);
    dict[@"scanFunc"] = @(self.scanFunc);
    dict[@"scanVar"] = @(self.scanVar);
    dict[@"scanProp"] = @(self.scanProp);
    dict[@"addRubishRes"] = @(self.addRubishRes);
//    dict[@"modifyFileName"] = @(self.modifyFileName);
    dict[@"jsObf"] = @(self.jsObf);
    dict[@"mmd5"] = @(self.mmd5);
    dict[@"backup"] = @(self.backup);
    dict[@"skipOptimize"] = @(self.skipOptimize);
    dict[@"autoRenameDefine"] = @(self.autoRenameDefine);
    dict[@"scanXib"] = @(self.scanXib);
    dict[@"saveLog"] = @(self.saveLog);
    dict[@"isAddCpp"] = @(self.isAddCpp);
    dict[@"isAddOC"] = @(self.isAddOC);
    dict[@"addCppNum"] = @(self.addCppNum);
    dict[@"addOCNum"] = @(self.addOCNum);
    dict[@"addMethodNum"] = @(self.addMethodNum);
    dict[@"isUnity"] = @(self.isUnity);
    
    dict[@"OCWeight"] = @(self.OCWeight);
    dict[@"stringWeight"] = @(self.stringWeight);
    dict[@"stringWordMin"] = @(self.stringWordMin);
    dict[@"stringWordMax"] = @(self.stringWordMax);
    dict[@"pngquantSpeed"] = @(self.pngquantSpeed);
    dict[@"isAddFileReDefine"] = @(self.isAddFileReDefine);
    dict[@"useKiwi"] = @(self.useKiwi);
    dict[@"udid"] = @(self.udid);
    
    dict[@"rubbishResMin"] = @(self.rubbishResMin);
    dict[@"rubbishResMax"] = @(self.rubbishResMax);

    dict[@"genjs"] = @(self.genjs);
    dict[@"genlua"] = @(self.genlua);
    dict[@"insertLuaCocos"] = @(self.insertLuaCocos);
    dict[@"groupRename"] = @(self.groupRename);
    
    return dict;
}

- (void)loadFromSystem
{
    [self loadFromJson:[self defaultConfigPath] isForceLoad:true];
//    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
//    NSDictionary * cfg = [defaults objectForKey:STORE_KEY];
//    [self loadFromDict:cfg];
}

- (bool) loadFromJson : (NSString *) jsonFile
{
    return [self loadFromJson:jsonFile isForceLoad:false];
}

- (bool) loadFromJson : (NSString *) jsonFile isForceLoad : (bool) isForceLoad
{
    NSString* jsonString = [NSString hy_stringWithFile:jsonFile];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(isForceLoad || dic) {
        [self loadFromDict:dic];
        return true;
    }
    return false;
}

-(void) revertToDefaultConfig
{
    [self loadFromDict:nil];
}

-(NSString *) defaultConfigPath
{
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    NSString * dir = [[basePath stringByAppendingPathComponent:@"Caches"] stringByAppendingPathComponent:appName];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:nil];
    return [dir stringByAppendingPathComponent:@"app.json"];
}

-(void)save
{
    [self saveToFile:[self defaultConfigPath]];
//    NSDictionary * dict = [self serialize];
//    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
//    [defaults setObject:dict forKey:STORE_KEY];
//    [defaults synchronize];
}

- (void)saveToFile: (NSString *) path {
    NSDictionary * dict = [self serialize];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        [jsonString writeToFile:path atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadFromSystem];
    }
    return self;
}

+ (instancetype)sharedInstance { 
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

@end
