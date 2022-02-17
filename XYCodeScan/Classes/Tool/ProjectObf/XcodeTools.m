//
//  XcodeTools.m
//  HYCodeScan
//
//  Created by admin on 2020/7/10.
//

#import "XcodeTools.h"
#import "HYGenerateNameTool.h"
#import "NSString+Extension.h"
#import "UserConfig.h"
#import "exec_cmd.h"
#import "Timer.h"

static void moveFolder(NSString * from , NSString * to) {
    
}

@implementation XcodeTools
NSMutableDictionary * UDID_Dict;

+ (void) setKiwiObf : (PBXProject*) project targets : (NSArray*) targets
{
//    GCC_VERSION = ""; => GCC_VERSION = com.apple.compilers.llvm.clang.1_1;
    if(![UserConfig sharedInstance].useKiwi){
        return;
    }
    Timer_start_print("设置kiwi");
    char * c_xcodePath = exec_cmd("xcode-select --print-path");
    NSString * xcodePath = [NSString stringWithUTF8String:c_xcodePath];
    xcodePath = [xcodePath stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSString * oldKiwi = [xcodePath stringByAppendingPathComponent:@"../PlugIns/Xcode3Core.ideplugin/Contents/SharedSupport/Developer/Library/Xcode/Plug-ins/KiwiSecSet.xcplugin"];
    oldKiwi = [oldKiwi stringByStandardizingPath];
    BOOL isFolder = NO;
    NSFileManager * fileManager = [[NSFileManager alloc] init];
    BOOL isExist = [fileManager fileExistsAtPath:oldKiwi isDirectory:&isFolder];
    int installedVersion = 0;
    if(isExist)
    {
        installedVersion = 1;
    }
    else {
        NSString * newKiwi = [xcodePath stringByAppendingPathComponent:@"Toolchains/XcodeDefault.xctoolchain/usr/bin/clang.org"];
        newKiwi = [newKiwi stringByStandardizingPath];
        isExist = [fileManager fileExistsAtPath:newKiwi isDirectory:&isFolder];
        if(isExist) {
            installedVersion = 2;
        } else {
            newKiwi = @"~/Library/Developer/Toolchains/kiwisec.xctoolchain";
            newKiwi = [newKiwi stringByStandardizingPath];
            isExist = [fileManager fileExistsAtPath:newKiwi isDirectory:&isFolder];
            if(isExist) {
                installedVersion = 3;
            }
        }
    }
    NSString * configStr;
    
    if(installedVersion > 0) {
        NSString * content = [NSString hy_stringWithFilename:@"File/kiwiConfig/kiki_config" extension:@"json"];
        NSData *jsonData = [content dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&err];
        if(dic) {
            bool isNeedSetGCC = false;
            switch (installedVersion) {
                case 1:
                {
                    isNeedSetGCC = true;
                    if(dic[@"old"]) {
                        if([UserConfig sharedInstance].isUnity) {
                            configStr = dic[@"old"][@"unity"];
                        } else {
                            configStr = dic[@"old"][@"normal"];
                        }
                    }
                    break;
                }
                case 2:
                case 3:
                {
                    if(dic[@"new"]) {
                        if([UserConfig sharedInstance].isUnity) {
                            configStr = dic[@"new"][@"unity"];
                        } else {
                            configStr = dic[@"new"][@"normal"];
                        }
                    }
                    break;
                }
                default:
                    break;
            }
            if(![configStr isEqualToString:@""]) {
                NSArray * arr = [configStr hy_componentsSeparatedBySpace];
                
                if(targets)
                {
                    for(PBXTarget * t in project.targets){
                        if([targets containsObject:[t getName]])
                        {
                            {
                                XCBuildConfiguration* conf = [t.buildConfigurationList getBuildConfigs:@"Debug"];
                                if(isNeedSetGCC) {
                                    [conf setBuildSetting:@"GCC_VERSION" settingValue:@"com.apple.compilers.llvm.clang.1_1"];
                                }
                                [conf addOtherCFlag:@"$(inherited)"];
                                for(NSString * item in arr) {
                                    if(![item isEqualToString:@""]) {
                                        [conf addOtherCFlag:item];
                                    }
                                }
                            }
                            {
                                XCBuildConfiguration* conf = [t.buildConfigurationList getBuildConfigs:@"Release"];
                                if(isNeedSetGCC) {
                                    [conf setBuildSetting:@"GCC_VERSION" settingValue:@"com.apple.compilers.llvm.clang.1_1"];
                                }
                                [conf addOtherCFlag:@"$(inherited)"];
                                for(NSString * item in arr) {
                                    if(![item isEqualToString:@""]) {
                                        [conf addOtherCFlag:item];
                                    }
                                }
                            }
                        }
                    }
                }
                else
                {
                    for(PBXTarget * t in project.targets){
                        {
                            XCBuildConfiguration* conf = [t.buildConfigurationList getBuildConfigs:@"Debug"];
                            if(isNeedSetGCC) {
                                [conf setBuildSetting:@"GCC_VERSION" settingValue:@"com.apple.compilers.llvm.clang.1_1"];
                            }
                            [conf addOtherCFlag:@"$(inherited)"];
                            for(NSString * item in arr) {
                                if(![item isEqualToString:@""]) {
                                    [conf addOtherCFlag:item];
                                }
                            }
                        }
                        {
                            XCBuildConfiguration* conf = [t.buildConfigurationList getBuildConfigs:@"Release"];
                            if(isNeedSetGCC) {
                                [conf setBuildSetting:@"GCC_VERSION" settingValue:@"com.apple.compilers.llvm.clang.1_1"];
                            }
                            [conf addOtherCFlag:@"$(inherited)"];
                            for(NSString * item in arr) {
                                if(![item isEqualToString:@""]) {
                                    [conf addOtherCFlag:item];
                                }
                            }
                        }
                    }
                }
            }
        }
    } else {
        NSLog(@"检测到并未安装kiwi。跳过设置。");
    }
    Timer_end_print("设置kiwi");
}

+ (void) addFileRedefineToTarget : (nullable PBXProject*) project targets : (nullable NSArray*) targets
{
    if(targets)
    {
        for(PBXTarget * t in project.targets){
            if([targets containsObject:[t getName]])
            {
                XCBuildConfiguration* debug = [t.buildConfigurationList getBuildConfigs:@"Debug"];
                [debug addOtherCFlag:@"$(inherited)"];
                [debug addOtherCFlag:@"-D__FILE__='\\\"\\\"'"];
                XCBuildConfiguration* release = [t.buildConfigurationList getBuildConfigs:@"Release"];
                [release addOtherCFlag:@"$(inherited)"];
                [release addOtherCFlag:@"-D__FILE__='\\\"\\\"'"];
            }
        }
    }
    else
    {
        for(PBXTarget * t in project.targets){
            XCBuildConfiguration* debug = [t.buildConfigurationList getBuildConfigs:@"Debug"];
            [debug addOtherCFlag:@"$(inherited)"];
            [debug addOtherCFlag:@"-D__FILE__='\\\"\\\"'"];
            XCBuildConfiguration* release = [t.buildConfigurationList getBuildConfigs:@"Release"];
            [release addOtherCFlag:@"$(inherited)"];
            [release addOtherCFlag:@"-D__FILE__='\\\"\\\"'"];
        }
    }
}

+ (void) addFileToTarget : (NSString*) file project: (PBXProject*) project group :(PBXGroup*) group targets : (NSArray*) targets
{
    group = group ? group : project.mainGroup;
    if(targets)
    {
        for(PBXTarget * t in project.targets){
            if([targets containsObject:[t getName]])
            {
                [group addFileWithPath:file target:t];
            }
        }
    }
    else
    {
        for(PBXTarget * t in project.targets){
            [group addFileWithPath:file target:t];
        }
    }
}

+(void) addPchFile : (NSString*) dir project:(PBXProject *) project targets : (NSArray*) targets
{
//    "GCC_PREFIX_HEADER"
    NSMutableSet * fileSet = [[NSMutableSet alloc] init];
    if(targets)
    {
        for(PBXTarget * t in project.targets){
            if([targets containsObject:[t getName]])
            {
                NSString * f = [t.buildConfigurationList getBuildSetting:@"Debug" name:@"GCC_PREFIX_HEADER"];
                if(f && ![fileSet containsObject:f])
                {
                    NSLog(@"修改pch：%@", f);
                    [fileSet addObject:f];
                    NSMutableString * ret = [NSMutableString string];
                    f = [f stringByReplacingOccurrencesOfString:@"$(SRCROOT)/" withString:@""];
                    if(![f hasPrefix:@"/"]) {
                        f = [dir stringByAppendingPathComponent:f];
                    }
                    NSString * file = [NSString hy_stringWithFile:f];
                    [ret appendString:file];
                    [ret appendString:@"#import \"Obfuscation_PCH.h\"\n"];
                    [ret writeToFile:f atomically:true encoding:NSUTF8StringEncoding error:nil];
                }
            }
        }
    }
    else
    {
        for(PBXTarget * t in project.targets){

            NSString * f = [t.buildConfigurationList getBuildSetting:@"Debug" name:@"GCC_PREFIX_HEADER"];
            if(f && ![fileSet containsObject:f])
            {
                [fileSet addObject:f];
                NSMutableString * ret = [NSMutableString string];
                [ret appendString:@"#import \"Obfuscation_PCH.h\"\n"];
   
                f = [f stringByReplacingOccurrencesOfString:@"$(SRCROOT)/" withString:@""];
                if(![f hasPrefix:@"/"]) {
                    f = [dir stringByAppendingPathComponent:f];
                }
                NSLog(@"修改pch：%@", f);
                NSString * file = [NSString hy_stringWithFile:f];
                [ret appendString:file];
                [ret writeToFile:f atomically:true encoding:NSUTF8StringEncoding error:nil];
            }
        }
    }
}
+ (void) obfXcodeprojUDID : (NSString*) path isTopProj: (BOOL) isTop
{
    if(isTop) {
        if(UDID_Dict) [UDID_Dict removeAllObjects];
        else UDID_Dict = [[NSMutableDictionary alloc] init];
    }
    PBXProjParser * parser = [[PBXProjParser alloc] init];
    [parser parseProjectWithPath:path];
    NSArray * allIds = parser.objects.rawData.allKeys;
    NSString * d = [path stringByDeletingLastPathComponent];
    
    if ([path.pathExtension isEqualToString:@"xcodeproj"]) {
        path = [path stringByAppendingPathComponent:@"project.pbxproj"];
    }
    NSString * content = [NSString hy_stringWithFile:path];
    NSArray * allref = [parser remoteIDS].allObjects;
    for(NSString* isa in allref)
    {
        NSString * rep = [UDID_Dict objectForKey:isa];
        if(!rep){
            rep = [XcodeTools genObjectId];
            [UDID_Dict setObject:rep forKey:isa];
        }
        content = [content stringByReplacingOccurrencesOfString:isa withString:rep];
    }
    for(NSString* isa in allIds) {
        NSString * rep = [UDID_Dict objectForKey:isa];
        if(!rep){
            rep = [XcodeTools genObjectId];
            [UDID_Dict setObject:rep forKey:isa];
        }
        content = [content stringByReplacingOccurrencesOfString:isa withString:rep];
    }
    
    [content writeToFile:path atomically:true encoding:NSUTF8StringEncoding error:nil];
    [self deepModifyChildProjectConfig:parser.project.mainGroup root:d pPath:d func:^(PBXProject * childproject, NSString* childPath) {
        [self obfXcodeprojUDID:childPath isTopProj:false];
    } needSave:false];
}

+(NSString *) genObjectId
{
    NSString *examplehash = @"D04218DC1BA6CBB90031707C";
    // 创建一个新的 uuid
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    // 获取UUID的字符串表示形式
    NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    uuidString = [[uuidString mutableCopy] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return [uuidString substringToIndex:examplehash.length];
}

+ (NSArray *) scanXibFile : (nullable NSString *) parentName dict:(id) dict arr:(NSMutableArray *) arr
{
    if([dict isKindOfClass:[NSDictionary class]])
    {
        for(NSString * key in dict)
        {
            id val = dict[key];
            if([val isKindOfClass:[NSDictionary class]] || [val isKindOfClass:[NSArray class]])
            {
                [self scanXibFile:key dict:val arr:arr];
            }
            else{
                if([key isEqualToString:@"customClass"]) {
                    [arr addObject:val];
                } else if([key isEqualToString:@"selector"] && [parentName isEqualToString:@"action"]) {
                    NSArray *aArray = [val componentsSeparatedByString:@":"];
                    for(NSString * v in aArray) {
                        [arr addObject:v];
                    }
                } else if([key isEqualToString:@"property"] && [parentName isEqualToString:@"outlet"]) {
                    [arr addObject:val];
                }
            }
        }
    } else if([dict isKindOfClass:[NSArray class]])
    {
        for(id val in dict)
        {
            if([val isKindOfClass:[NSDictionary class]] || [val isKindOfClass:[NSArray class]])
            {
                [self scanXibFile:nil dict:val arr:arr];
            }
        }
    }
    return arr;
}

+ (void) deepForEachWithFileTypeInXcode:(bool) needFilter group:(PBXGroup *) group root:(NSString *) root pPath:(NSString *) pPath fileTypes:(NSArray *) fileTypes func:(void(^)(NSString*, NSString*)) func
{
    if(needFilter && ![HYGenerateNameTool checkGroupOK:[group getName]]){
        return;
    }
    for(PBXNavigatorItem * item in group.children) {
        NSString * p = [item getPath];
        if(![p hasPrefix:@"/"])
        {
            NSString * st = [item getSourceTree];
            if([st isEqualToString:PBXSourceTree_GROUP]){
                p = [pPath stringByAppendingPathComponent:p];
            }
            else if([st isEqualToString:PBXSourceTree_ROOT]) {
                p = [root stringByAppendingPathComponent:p];
            }
        }
        p = [p stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
        if([item isKindOfClass:[PBXGroup class]])
        {
            [self deepForEachWithFileTypeInXcode:needFilter group:(PBXGroup*)item root:root pPath:p fileTypes:fileTypes func:func];
//            deepForEachWithFileTypeInXcode(needFilter, (PBXGroup*)item, root, p, fileTypes, func);
        }
        else
        {
            if([item isKindOfClass:[PBXFileReference class]]) {
                NSString * ft = [((PBXFileReference *) item) getLastKnownFileType];
                for(NSString * t in fileTypes)
                {
                    if([ft containsString:t])
                    {
                        func(p, ft);
                    }
                }
            }
        }
    }
}

+ (bool) deepForEachXcodeGroup:(bool) needFilter group:(PBXGroup *)group extensions:(NSArray *) extensions root:(NSString *) root pPath:(NSString *) pPath func:(void(^)(NSString*))func findOne:(bool)findOne
{
     if(needFilter && ![HYGenerateNameTool checkGroupOK:[group getName]]){
         return false;
     }
    for(PBXNavigatorItem * item in group.children) {
        NSString * p = [item getPath];
        if(![p hasPrefix:@"/"])
        {
            NSString * st = [item getSourceTree];
            if([st isEqualToString:PBXSourceTree_GROUP]){
                p = [pPath stringByAppendingPathComponent:p];
            }
            else if([st isEqualToString:PBXSourceTree_ROOT]) {
                p = [root stringByAppendingPathComponent:p];
            }
        }
        p = [p stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
        if([item isKindOfClass:[PBXGroup class]])
        {
            if([self deepForEachXcodeGroup:needFilter group:(PBXGroup *)item extensions:extensions root:root pPath:p func:func findOne:findOne])
            {
                return true;
            }
        }
        else
        {
            for(NSString * ext in extensions)
            {
                if([p hasSuffix:ext])
                {
                    func(p);
                    if(findOne) {
                        return true ;
                    }
                }
            }
        }
    }
    return false;
}

+ (void) deepModifyChildProjectConfig: (PBXGroup *) group root:(NSString *) root pPath:(NSString *) pPath func : (void(^)(PBXProject *, NSString*)) func needSave:(BOOL) needSave
{
    for(PBXNavigatorItem * item in group.children) {
        NSString * p = [item getPath];
        if(![p hasPrefix:@"/"])
        {
            NSString * st = [item getSourceTree];
            if([st isEqualToString:PBXSourceTree_GROUP]){
                p = [pPath stringByAppendingPathComponent:p];
            }
            else if([st isEqualToString:PBXSourceTree_ROOT]) {
                p = [root stringByAppendingPathComponent:p];
            }
        }
        p = [p stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
        if([item isKindOfClass:[PBXGroup class]])
        {
            [self deepModifyChildProjectConfig:(PBXGroup *)item root:root pPath:p func:func needSave:needSave];
//            deepModifyChildProjectConfig((PBXGroup*)item, root, p, func, needSave);
        }
        else
        {
            NSString * ft = [((PBXFileReference *) item) getLastKnownFileType];
            if([ft isEqualToString:@"wrapper.pb-project"]) {
                p = [p stringByStandardizingPath];
                PBXProjParser * parser = [[PBXProjParser alloc] init];
                [parser parseProjectWithPath:p];
                if(parser.project) {
                    func(parser.project, p);
                    if(needSave) {
                        [[[parser pbxprojDictionary] convertToPropertyListData] writeToFile:[p stringByAppendingPathComponent:@"project.pbxproj"] atomically:true];
                    }
                }
            }
        }
    }
}

+ (void)moveFolder:(NSString *)filePath toFolder:(NSString *) moveToPath {
    filePath = [filePath stringByStandardizingPath];
    moveToPath = [moveToPath stringByStandardizingPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isFolder = NO;
    BOOL isExist = [fileManager fileExistsAtPath:filePath isDirectory:&isFolder];
    if(isExist) {
        if(isFolder) {
            [fileManager createDirectoryAtPath:moveToPath withIntermediateDirectories:TRUE attributes:nil error:nil];
            NSDirectoryEnumerator *myDirectoryEnumerator = [fileManager enumeratorAtPath:filePath];
            //列举目录内容，可以遍历子目录
            for (NSString *path in myDirectoryEnumerator.allObjects) {
                NSString * childPath = [filePath stringByAppendingPathComponent:path];
                NSString * toChildPath = [moveToPath stringByAppendingPathComponent:path];
                [self moveFolder:childPath toFolder:toChildPath];
            }
            [fileManager removeItemAtPath:filePath error:nil];
        } else {
            NSString * toFolder = [moveToPath stringByDeletingLastPathComponent];
            [fileManager createDirectoryAtPath:toFolder withIntermediateDirectories:TRUE attributes:nil error:nil];
            [fileManager moveItemAtPath:filePath toPath:moveToPath error:nil];
        }
    }
}

+ (void) modifyGroupAndFolderName : (PBXGroup *) group root:(NSString *) root pPath:(NSString *) pPath orgPath:(NSString*) orgPath pathMap: (NSMutableDictionary*) dict fileArr :(NSMutableArray *) fileArr {
    for(PBXNavigatorItem * item in group.children) {
        // 有可能原始路径已经变了
        NSString * op = [item getPath];
        NSString * p = op;
        
        if(![p hasPrefix:@"/"])
        {
            NSString * st = [item getSourceTree];
            if([st isEqualToString:PBXSourceTree_GROUP]){
                p = [pPath stringByAppendingPathComponent:p];
                op = [orgPath stringByAppendingPathComponent:op];
            }
            else if([st isEqualToString:PBXSourceTree_ROOT]) {
                p = [root stringByAppendingPathComponent:p];
                op = [root stringByAppendingPathComponent:op];
            }
        }
        p = [p stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
        op = [op stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
        
        p = [p stringByReplacingOccurrencesOfString:@"$(PROJECT_DIR)" withString:root];
        op = [op stringByReplacingOccurrencesOfString:@"$(PROJECT_DIR)" withString:root];
        
        p = [p stringByStandardizingPath];
        op = [op stringByStandardizingPath];

        // 绝对路径问题需要修改掉
        {
            int mlen = 0;
            for(NSString * key in dict) {
                if(key.length > mlen && [op hasPrefix:key]) {
                    mlen = key.length;
                    p= [op stringByReplacingOccurrencesOfString:key withString:dict[key]];
                }
            }
        }
        
        if([item isKindOfClass:[PBXGroup class]])
        {
            bool isModified = false;
            if([item isKindOfClass:[PBXVariantGroup class]]) {
                // 这里可能有多语言，就不改了
                return;
            }
            if([[item getPath] isEqualToString:@"Pods"]) {
                return;
            }
            NSFileManager * manager = [NSFileManager defaultManager];
            
            if(dict[[op stringByAppendingString:@"/"]]) {
                isModified = true;
            }
            
            if([p isEqualToString:root]) {
                isModified = true;
            }
            BOOL isFolder = NO;
            BOOL isExist = [manager fileExistsAtPath:p isDirectory:&isFolder];
            NSString * newDic;
            NSString * word;
            if(isExist) {
                if(!isModified) {
                    NSLog(@"修改路径：%@", op);
                    NSString * fileName = [p lastPathComponent];
                    while(true) {
                        word = [HYGenerateNameTool generateByName:WordName from:fileName cache:false];
                        if([fileName pathExtension].length > 0) {
                            word = [word stringByAppendingFormat:@".%@", [fileName pathExtension]];
                        }
                        newDic = [[p stringByDeletingLastPathComponent] stringByAppendingPathComponent:word];
                        // 创建新文件夹
                        NSError * error = nil;
                        if ([manager createDirectoryAtPath:newDic withIntermediateDirectories:NO attributes:nil error:&error] ==  YES) {
                            // 移动文件
                            [self moveFolder:p toFolder:newDic];
                            break;
                        }
                    }
    //                [dict setObject:newPath forKey:[item getPath]];
                    
                    [dict setObject:[newDic stringByAppendingString:@"/"] forKey:[op stringByAppendingString:@"/"]];
                    [item setName:word];
                    p = newDic;
                }

                if(![[item getPath] hasPrefix:@"/"])
                {
                    NSString * newPath;
                    NSString * st = [item getSourceTree];
                    if([st isEqualToString:PBXSourceTree_GROUP]){
                        newPath = [p stringByReplacingOccurrencesOfString:pPath withString:@""];
                    }
                    else if([st isEqualToString:PBXSourceTree_ROOT]) {
                        newPath = [p stringByReplacingOccurrencesOfString:root withString:@""];
                    }

                    NSString * org_set_path = [item getPath];
                    if([org_set_path hasPrefix:@"$(PROJECT_DIR)"]) {
                        newPath = [newPath stringByReplacingOccurrencesOfString:root withString:@"$(PROJECT_DIR)"];
                    }
                    if([org_set_path hasPrefix:@"$(SRCROOT)"]) {
                        newPath = [newPath stringByReplacingOccurrencesOfString:root withString:@"$(SRCROOT)"];
                    }
                    
                    if([newPath hasPrefix:@"/"]) {
                        newPath = [newPath substringFromIndex:1];
                    }
                    [item setPath:newPath];
                }
            } else {
                NSLog(@"Group的文件夹不存在：%@", p);
            }
            
            [self modifyGroupAndFolderName:(PBXGroup *)item root:root pPath:p orgPath:op pathMap:dict fileArr:fileArr];
            
        }
        else
        {
            if(![[item getPath] hasPrefix:@"/"])
            {
                [fileArr addObject:@{
                    @"orgPath" : orgPath,
                    @"pPath" : pPath,
                    @"file" : item
                }];
            }
        }
    }
}

+(void) replaceConfigInnerConfigPath : (XCBuildConfiguration*) config root:(NSString *) root key:(NSString *) key dict:(NSDictionary *) dict {
    id data = [config getBuildSetting:key];
    
    NSString*(^solvePath)(NSString * pPath) = ^ (NSString * pPath){
        bool hasYH = [pPath hasPrefix:@"\""] && [pPath hasSuffix:@"\""];
        if(hasYH) {
            pPath = [pPath substringFromIndex:1];
            pPath = [pPath substringToIndex:[pPath length] - 1];
        }
        NSString * orgPath = pPath;
        
        pPath = [pPath stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:root];
        pPath = [pPath stringByReplacingOccurrencesOfString:@"$(PROJECT_DIR)" withString:root];
        
        if(![pPath isEqualToString:@""]) {
            if(![pPath hasPrefix:@"/"])
            {
                pPath = [root stringByAppendingPathComponent:pPath];
            }
            
            if(![pPath hasSuffix:@"/"])
            {
                pPath = [pPath stringByAppendingString:@"/"];
            }
            
            {
                NSString * op = pPath;
                int mlen = 0;
                for(NSString * key in dict) {
                    if(key.length > mlen && [op hasPrefix:key]) {
                        mlen = key.length;
                        pPath = [op stringByReplacingOccurrencesOfString:key withString:dict[key]];
                    }
                }
            }
            
            if([orgPath hasPrefix:@"$(PROJECT_DIR)"]) {
                pPath = [pPath stringByReplacingOccurrencesOfString:root withString:@"$(PROJECT_DIR)"];
            }
            if([orgPath hasPrefix:@"$(SRCROOT)"]) {
                pPath = [pPath stringByReplacingOccurrencesOfString:root withString:@"$(SRCROOT)"];
            }
            if(![orgPath hasPrefix:@"/"])
            {
                pPath = [pPath stringByReplacingOccurrencesOfString:root withString:@""];
                if([pPath hasPrefix:@"/"]) {
                    pPath = [pPath substringFromIndex:1];
                }
            }
            if(![orgPath hasSuffix:@"/"] && [pPath hasSuffix:@"/"])
            {
                pPath = [pPath substringToIndex:[pPath length] - 1];
            }
        }
        if(hasYH) {
            return [NSString stringWithFormat:@"\"%@\"", pPath];
        }
        return pPath;
    };
    
    if([data isKindOfClass:[NSArray class]]) {
        NSMutableArray * dataArr = [data mutableCopy];
        for(int i = 0; i < dataArr.count; i++ ) {
            NSString * pPath = [dataArr objectAtIndex:i];
            pPath = solvePath(pPath);
            [dataArr replaceObjectAtIndex:i withObject:pPath];
        }
        [config setBuildSetting:key settingValue:dataArr];
        
    } else if([data isKindOfClass:[NSString class]]) {
        NSString * pPath = solvePath(data);
        [config setBuildSetting:key settingValue:pPath];
    }
    
}

+ (void) reNameProjectGroup :(NSString *) projectPath
{
    NSString* dir = [projectPath stringByDeletingLastPathComponent];
    PBXProjParser * parser = [[PBXProjParser alloc] init];
    [parser parseProjectWithPath:projectPath];
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    NSMutableArray * fileArr = [[NSMutableArray alloc] init];
    [self modifyGroupAndFolderName:parser.project.mainGroup root:dir pPath:dir orgPath:dir pathMap:dict fileArr:fileArr];
    
    for(NSDictionary * f in fileArr) {
//                1. 扫描出所有的文件列表
//                2. 预处理出一个文件改动方案
//                3. 开始执行改文件名操作。
//                    扫描所有的文件。检测头文件和cpp文件。根据隐射表进行修改
        PBXNavigatorItem * item = f[@"file"];
        NSString * pPath = f[@"pPath"];
        NSString * orgPath = f[@"orgPath"];
        // 有可能原始路径已经变了
        NSString * op = [item getPath];
        NSString * p = op;
       
        if(![p hasPrefix:@"/"])
        {
            NSString * st = [item getSourceTree];
            if([st isEqualToString:PBXSourceTree_GROUP]){
                p = [pPath stringByAppendingPathComponent:p];
                op = [orgPath stringByAppendingPathComponent:op];
            }
            else if([st isEqualToString:PBXSourceTree_ROOT]) {
                p = [dir stringByAppendingPathComponent:p];
                op = [dir stringByAppendingPathComponent:op];
            }
        }
        p = [p stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:dir];
        op = [op stringByReplacingOccurrencesOfString:@"$(SRCROOT)" withString:dir];
        
        p = [p stringByReplacingOccurrencesOfString:@"$(PROJECT_DIR)" withString:dir];
        op = [op stringByReplacingOccurrencesOfString:@"$(PROJECT_DIR)" withString:dir];
        
        p = [p stringByStandardizingPath];
        op = [op stringByStandardizingPath];
        // 绝对路径问题需要修改掉
        {
            int mlen = 0;
            for(NSString * key in dict) {
                if(key.length > mlen && [op hasPrefix:key]) {
                    mlen = key.length;
                    p= [op stringByReplacingOccurrencesOfString:key withString:dict[key]];
                }
            }
        }
        NSString * newPath;
        NSString * st = [item getSourceTree];
        if([st isEqualToString:PBXSourceTree_GROUP]){
            newPath = [p stringByReplacingOccurrencesOfString:pPath withString:@""];
        }
        else if([st isEqualToString:PBXSourceTree_ROOT]) {
            newPath = [p stringByReplacingOccurrencesOfString:dir withString:@""];
        }
        NSString * org_set_path = [item getPath];
        if([org_set_path hasPrefix:@"$(PROJECT_DIR)"]) {
            newPath = [newPath stringByReplacingOccurrencesOfString:dir withString:@"$(PROJECT_DIR)"];
        }
        if([org_set_path hasPrefix:@"$(SRCROOT)"]) {
            newPath = [newPath stringByReplacingOccurrencesOfString:dir withString:@"$(SRCROOT)"];
        }
        if([newPath hasPrefix:@"/"]) {
            newPath = [newPath substringFromIndex:1];
        }
        [item setPath:newPath];
    }
    
    for(PBXTarget * t in parser.project.targets){
        NSDictionary<NSString *,XCBuildConfiguration *>* configs = [t.buildConfigurationList getAllBuildConfigs];
        for(NSString* ck in configs) {
            XCBuildConfiguration * item = configs[ck];
            [self replaceConfigInnerConfigPath:item root:dir key:@"INFOPLIST_FILE" dict:dict];
            [self replaceConfigInnerConfigPath:item root:dir key:@"GCC_PREFIX_HEADER" dict:dict];
            [self replaceConfigInnerConfigPath:item root:dir key:@"HEADER_SEARCH_PATHS" dict:dict];
            [self replaceConfigInnerConfigPath:item root:dir key:@"USER_HEADER_SEARCH_PATHS" dict:dict];
            [self replaceConfigInnerConfigPath:item root:dir key:@"FRAMEWORK_SEARCH_PATHS" dict:dict];
            [self replaceConfigInnerConfigPath:item root:dir key:@"LIBRARY_SEARCH_PATHS" dict:dict];
            [self replaceConfigInnerConfigPath:item root:dir key:@"SYSTEM_HEADER_SEARCH_PATHS" dict:dict];
        }
    }
    [parser save:projectPath];
}


@end
