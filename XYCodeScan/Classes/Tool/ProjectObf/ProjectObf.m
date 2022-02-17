#import <Foundation/Foundation.h>
#import "ProjectObf.h"
#import "NSFileManager+Extension.h"
#import "NSString+Extension.h"
#import "CodeFileGenerator.h"
#import "rcg.h"
#import "UserConfig.h"
#import "HYGenerateNameTool.h"
#import "HYObfuscationTool.h"
#import "LuaCodeObf.h"
#import "ImageTools.h"
#import "XMLReader.h"
#import "mmd5.h"
#import "HYDefineRenameTool.h"
#import "StringObf.h"
#import "ResGenerator.h"
#import "exec_cmd.h"
#import "LuaObf.h"
#import "CodeGenerator.h"
#import "XcodeTools.h"

void copyFolderFromPath(NSString * sourcePath ,NSString * toPath)
{
    sourcePath = [sourcePath stringByStandardizingPath];
    toPath = [toPath stringByStandardizingPath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isFolder = NO;
    BOOL isExist = [fileManager fileExistsAtPath:toPath isDirectory:&isFolder];
    if(isExist)
    {
        NSLog(@"已存在备份文件：%@", toPath);
        return;
    }else {
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:toPath error:&err];
    }
    NSArray* array = [fileManager contentsOfDirectoryAtPath:sourcePath error:nil];
    for(int i = 0; i<[array count]; i++)
    {
        NSString *fullPath = [sourcePath stringByAppendingPathComponent:[array objectAtIndex:i]];
        NSString *fullToPath = [toPath stringByAppendingPathComponent:[array objectAtIndex:i]];
        //判断是不是文件夹
        BOOL isFolder = NO;
        //判断是不是存在路径 并且是不是文件夹
        BOOL isExist = [fileManager fileExistsAtPath:fullPath isDirectory:&isFolder];
        if (isExist){
            NSError *err = nil;
            [[NSFileManager defaultManager] copyItemAtPath:fullPath toPath:fullToPath error:&err];
            if (isFolder){
                copyFolderFromPath(fullPath,fullToPath);
            }
        }
    }
}


@implementation ProjectObf

static NSString * getBackupPath(NSString * str)
{
    str = [str stringByStandardizingPath];
    NSMutableArray * arr = [[str pathComponents] mutableCopy];
    NSString * lastName = [[arr lastObject] stringByAppendingString:@"_hybackup"];
    [arr replaceObjectAtIndex:arr.count-1  withObject:lastName];
    return [NSString pathWithComponents:arr];
}

static void searchFolder(NSString*p , NSMutableArray* container) {
    p = [p stringByStandardizingPath];
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [myFileManager enumeratorAtPath:p];
    BOOL isDir = NO;
    BOOL isExist = NO;
    isExist = [myFileManager fileExistsAtPath:p isDirectory:&isDir];
    if(isDir && isExist) {
        [container addObject:p];
        //列举目录内容，可以遍历子目录
        for (NSString *path in myDirectoryEnumerator.allObjects) {
            isExist = [myFileManager fileExistsAtPath:[p stringByAppendingPathComponent:path] isDirectory:&isDir];
            if (isExist && isDir) {
                searchFolder([p stringByAppendingPathComponent:path], container);
            }
        }
    }
}

+(void) addRubbishFileWithFolders: (NSArray *) fromFolder
{
    UserConfig * config = [UserConfig sharedInstance];
    if(!config.addRubishRes) return;
    NSMutableArray * container = [[NSMutableArray alloc] init];
    for( NSString * p in fromFolder) {
        searchFolder(p, container);
    }
    if(container.count == 0) return;
    int rubbishTypesNum = 3;
    int folderNum = config.rubbishResMin / rubbishTypesNum;
    if(folderNum > container.count) {
        folderNum = container.count;
    }
    int minNum = round(config.rubbishResMin * 1.0 / (folderNum * rubbishTypesNum));
    int maxNum = round(config.rubbishResMax * 1.0 / (folderNum * rubbishTypesNum)) + 1;
    int startIndex = arc4random() % container.count;
    for(int i = 0; i < folderNum; i++) {
        NSString * f = [container objectAtIndex: (startIndex + i) % container.count];
        NSLog(@"对文件夹添加垃圾资源：%@", f);
        [ResGenerator genRubishFile:f typeNum:rubbishTypesNum minNum:minNum maxNum: maxNum];
        
    }
}

+(void) xattrPath:(NSString *) path
{
    if(path && ![path isEqualToString:@""]) {
        NSString * cmd1 = [NSString stringWithFormat:@"chmod -R +w \"%@\"", path];
        NSString * cmd2 = [NSString stringWithFormat:@"xattr -rc \"%@\"", path];
        exec_cmd([cmd1 UTF8String]);
        exec_cmd([cmd2 UTF8String]);
    }
}

+(void) obf
{
    Timer_reset();
    [HYGenerateNameTool buildCustomForbiddenName];
    UserConfig * config = [UserConfig sharedInstance];
    NSMutableSet * rcgFileCache = [[NSMutableSet alloc] init];
    NSMutableArray * allFolder = [[NSMutableArray alloc] init];
    [self xattrPath:config.backupPath];
    if(config.backup && [config.backupPath length] > 0)
    {
        NSString * backdir = getBackupPath(config.backupPath);
        NSLog(@"正在备份文件：%@ ---> %@", config.backupPath, backdir);
        copyFolderFromPath(config.backupPath, backdir);
    }
    int prob = (int)config.prop;
    NSLog(@"混淆概率：%d", prob);
    if(config.encodeNSString || config.encodeCString)
    {
        [StringObf build];
    }
    
    bool needScan = config.scanType || config.scanProp || config.scanFunc || config.scanVar;
    needScan = needScan && (config.scanProjectCode || config.codePath.length > 0);
    __block bool isHaveObfH = false;
    // 混淆xcode
    if([config.xcodePath length] > 0)
    {
        NSString * projectPath = config.xcodePath;
        NSString* dir = [projectPath stringByDeletingLastPathComponent];
        [self xattrPath:dir];
        
        if(config.udid) {
            Timer_start_print("修改UDID");
            [XcodeTools obfXcodeprojUDID:projectPath isTopProj:true];
            Timer_end_print("修改UDID");
        }
        NSArray * targets = NULL;
        if(config.targets.length > 0)
        {
            targets = [config.targets componentsSeparatedByString:@","];
        }
        PBXProjParser * parser = [[PBXProjParser alloc] init];
        [parser parseProjectWithPath:projectPath];
        
        // 这个必须第一个做
        if(config.isAddFileReDefine) {
            Timer_start_print("重定义__FILE__");
            [XcodeTools deepModifyChildProjectConfig:parser.project.mainGroup root:dir pPath:dir func:^(PBXProject * childproject, NSString * childPath) {
                [XcodeTools addFileRedefineToTarget:childproject targets:nil];
            } needSave:true];
//            // 这里因为是单例，需要重新解析一次。
//            [parser parseProjectWithPath:projectPath];
            [XcodeTools addFileRedefineToTarget:parser.project targets:targets];
            
            Timer_end_print("重定义__FILE__");
        }
        
        [XcodeTools setKiwiObf:parser.project targets:targets];
        
        [XcodeTools deepForEachXcodeGroup:false group:parser.project.mainGroup extensions:@[@"Obfuscation_PCH.h"] root:dir pPath:dir func:^(NSString* p){
            isHaveObfH = true;
            if(config.autoRenameDefine) {
                Timer_start_print("重定义文件");
                [HYDefineRenameTool renameHeadFile:@[p] callback:nil];
                Timer_end_print("重定义文件");
            }
        } findOne:true];
        
        if(!isHaveObfH && needScan)
            [HYObfuscationTool reset];
        
        if([UserConfig sharedInstance].scanXib)
        {
            Timer_start_print("扫描Xib");
            [XcodeTools deepForEachXcodeGroup:false group: parser.project.mainGroup extensions:@[@".storyboard", @".xib"] root:dir pPath:dir func:^(NSString* p){
                NSLog(@"读取文件：%@", p);
                NSData * data = [[NSData alloc] initWithContentsOfFile:p];
                NSError *error = nil;
                if(data)
                {
                    NSDictionary *dict = [XMLReader dictionaryForXMLData:data options:XMLReaderOptionsProcessNamespaces error:&error];
                    NSMutableArray * arr = [[NSMutableArray alloc] init];
                    [XcodeTools scanXibFile:nil dict:dict arr:arr];
                    for(NSString * key in arr)
                    {
                        [HYGenerateNameTool addCustomForbiddenName:key];
                    }
                }
            } findOne:false];
            Timer_end_print("扫描Xib");
        }
        
        __block int num = 0;
        NSMutableArray * cfiles = [[NSMutableArray alloc] init];
        [XcodeTools deepForEachXcodeGroup:true group:parser.project.mainGroup extensions:@[@".c",@".cc", @".cpp", @".m", @".mm"] root:dir pPath:dir func:^(NSString* p){
            [cfiles addObject:p];
            num += 1;
        } findOne:false];
        
        if(!isHaveObfH && needScan)
        {
            NSLog(@"正在进行扫描阶段");
            Timer_start_print("扫描代码");
            if( config.scanProjectCode) {
                [HYObfuscationTool obfuscateWithFiles:cfiles prefixes:nil];
            }
            if([config.codePath length] > 0)
            {
                [HYObfuscationTool obfuscateAtDir:@[config.codePath] prefixes:nil];
            }
            Timer_end_print("扫描代码");
        }
        if( config.scanProjectCode) {
            Timer_start_print("混淆工程代码");
            for(NSString * p in cfiles)
            {
                if(![rcgFileCache containsObject:p]) {
                    [rcgFileCache addObject:p];
                    NSLog(@"正在处理文件：%@" , p);
                    [CodeGenerator rcg:p output:p prop:prob];
                }
            }
            Timer_end_print("混淆工程代码");
            if(config.addProperty){
                Timer_start_print("添加属性");
                // 对头文件进行添加property操作
                [XcodeTools deepForEachXcodeGroup:true group:parser.project.mainGroup extensions:@[@".h"] root:dir pPath:dir func:^(NSString* p){
                    if(![rcgFileCache containsObject:p]) {
                        [rcgFileCache addObject:p];
                        [CodeGenerator rcg:p output:p prop:prob];
                    }
                } findOne:false];
                Timer_end_print("添加属性");
            }
        }
        num = MIN(num, 20);
        NSString * genGroupName = [[HYGenerateNameTool generateByName:WordName from:nil cache:false] stringByAppendingString:[HYGenerateNameTool generateByName:WordName from:nil cache:false]];
        NSString * outFolder = [dir stringByAppendingPathComponent:genGroupName];
        BOOL isDir = NO;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL existed = [fileManager fileExistsAtPath:outFolder isDirectory:&isDir];
        if ( !(isDir == YES && existed == YES) ) {
            [fileManager createDirectoryAtPath:outFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        PBXGroup* group = [parser.project.mainGroup addGroup:genGroupName path:genGroupName];
        if(config.isAddOC || config.isAddCpp){
            Timer_start_print("生成垃圾OC代码");
            
            if(config.isAddCpp) {
                char * importFuncName = NULL;
                if(config.addCppNum <= 0) {
                    importFuncName = genClassToFolder(Gen_Cplus, num, [outFolder UTF8String]);
                } else {
                    importFuncName = genClassToFolder(Gen_Cplus, config.addCppNum, [outFolder UTF8String]);
                }
                if(importFuncName) {
                    NSString * funcName = [NSString stringWithUTF8String:importFuncName];
                    [XcodeTools deepForEachXcodeGroup:false group:parser.project.mainGroup extensions:@[@".m", @".mm"] root:dir pPath:dir func:^(NSString* p){
                        NSLog(@"插入CPP引用代码到文件：%@, %@", p, funcName);
                        NSString * import = [NSString stringWithFormat:@"#import \"%@.h\"\n", funcName];
                        NSString * code = [NSString stringWithFormat:@"\n%@();\n", funcName];
                        [CodeGenerator insertCode:p output:p import:import code:code];
                    } findOne:true];
                }
            }
            if(config.isAddOC) {
                char * importFuncName = NULL;
                if(config.addOCNum <= 0) {
                    importFuncName = genClassToFolder(Gen_OC, num, [outFolder UTF8String]);
                } else {
                    importFuncName = genClassToFolder(Gen_OC, config.addOCNum, [outFolder UTF8String]);
                }
                if(importFuncName) {
                    NSString * funcName = [NSString stringWithUTF8String:importFuncName];
                    [XcodeTools deepForEachXcodeGroup:false group:parser.project.mainGroup extensions:@[@".m", @".mm"] root:dir pPath:dir func:^(NSString* p){
                        NSLog(@"插入OC引用代码到文件：%@, %@", p, funcName);
                        NSString * import = [NSString stringWithFormat:@"#import \"%@.h\"\n", funcName];
                        NSString * code = [NSString stringWithFormat:@"\n%@();\n", funcName];
                        [CodeGenerator insertCode:p output:p import:import code:code];
                    } findOne:true];
                }
            }
            Timer_end_print("生成垃圾OC代码");
//            NSLog(@"正在对生成的代码文件进行混淆");
            // 生成的文件也混淆一下。
            NSArray * subpaths = [NSFileManager hy_subpathsAtPath:outFolder extensions:@[@"h", @"cc", @"c", @"cpp", @"m", @"mm"]];
            for(NSString * file in subpaths)
            {
//                if(![rcgFileCache containsObject:file]) {
//                    NSLog(@"处理文件：%@", file);
//                    [rcgFileCache addObject:file];
//                    [CodeGenerator rcg:file output:file prop:prob];
//                }
                // TODO：改成随机添加到某些group
                [XcodeTools addFileToTarget:[file lastPathComponent] project:parser.project group:group targets:targets];
            }
        }
        
        NSLog(@"添加其他代码到工程");
        if(config.encodeNSString || config.encodeCString)
        {
            [StringObf save:[dir stringByAppendingPathComponent:genGroupName]];
            NSString *pathH = [NSString stringWithFormat:@"%@.h", [StringObf getFileName]];
            NSString *pathM = [NSString stringWithFormat:@"%@.m", [StringObf getFileName]];
            [XcodeTools addFileToTarget:pathH project:parser.project group:group targets:targets];
            [XcodeTools addFileToTarget:pathM project:parser.project group:group targets:targets];
        }
        
        NSLog(@"PCH头文件写入");
        if(!isHaveObfH && needScan)
        {
            [HYObfuscationTool write:[dir stringByAppendingPathComponent:genGroupName]];
            NSString *pathH = [NSString stringWithFormat:@"%@", @"Obfuscation_PCH.h"];
            [XcodeTools addFileToTarget:pathH project:parser.project group:group targets:targets];
            [XcodeTools addPchFile:dir project:parser.project targets:targets];
        }
        
        NSLog(@"添加完成");
        [parser save:projectPath];
        
//        [[[parser pbxprojDictionary] convertToPropertyListData] writeToFile:[projectPath stringByAppendingPathComponent:@"project.pbxproj"] atomically:true];
 
        NSLog(@"正在对工程中的资源文件进行hash值修改");
        [XcodeTools deepForEachWithFileTypeInXcode:false group:parser.project.mainGroup root:dir pPath:dir fileTypes:@[@"folder", @"image", @"text"] func:^(NSString * p, NSString * ft){
            NSLog(@"读取文件：%@", p);
            if([ft isEqualToString:@"folder.assetcatalog"]) {
                [ImageTools solveImage:p];
                if(config.mmd5)
                {
                    [mmd5 mmd5Dir:p outDir:p];
                }
            } else if([ft isEqualToString:@"folder"]) {
                Timer_start_print("生成垃圾资源");
                [ImageTools solveImage:p];
                if(config.mmd5)
                {
                    [mmd5 mmd5Dir:p outDir:p];
                }
                NSArray * luafiles = [NSFileManager hy_subpathsAtPath:p extensions:@[@"lua", @"luac"]];
                if(luafiles.count > 0) {
                    if(config.isLuaCode)
                    {
                        for(NSString * file in luafiles) {
                            [LuaCodeObf rcg:file output:file];
                            [LuaObf obf:file outfile:file];
                        }
                    }
                }
                if(config.addRubishRes) {
                    [allFolder addObject:p];
                }
                Timer_end_print("生成垃圾资源");
            } else if([ft containsString:@"image"]) {
                [ImageTools solveImage:p];
            } else {
                if(config.mmd5) {
                    [mmd5 mmd5File:p outDir:p];
                }
            }
        }];
        
        if(config.groupRename) {
            Timer_start_print("修改Group名字");
            [XcodeTools reNameProjectGroup:projectPath];
            Timer_end_print("修改Group名字");
        }
    }
    
    if([config.codePath length] > 0)
    {
        [self xattrPath:config.codePath];
        NSArray * subpaths = [NSFileManager hy_subpathsAtPath:config.codePath extensions:@[@"h", @"c", @"cc", @"cpp", @"m", @"mm"]];
        for(NSString * file in subpaths)
        {
            if(![rcgFileCache containsObject:file]) {
                [rcgFileCache addObject:file];
                [CodeGenerator rcg:file output:file prop:prob];
            }
        }
    }
    
    if([config.luaFolder length] > 0)
    {
        [self xattrPath:config.luaFolder];
        if(config.backup)
        {
            NSString * backup = getBackupPath(config.luaFolder);
            NSLog(@"正在备份资源文件：%@ ---> %@", config.luaFolder, backup);
            copyFolderFromPath(config.luaFolder, backup);
        }
        if(config.isLuaCode)
        {
            NSArray * arr = [NSFileManager hy_subpathsAtPath:config.luaFolder extensions:@[@"lua"]];
            for(NSString * file in arr) {
                [LuaCodeObf rcg:file output:file];
                [LuaObf obf:file outfile:file];
            }
        }
        if(config.addRubishRes) {
            [allFolder addObject:config.luaFolder];
//            [self addRubbishFile:config.luaFolder fileType:@"lua"];
//            [self addRubbishFile:config.luaFolder fileType:@"js"];
//            [self addRubbishFile:config.luaFolder fileType:@"other"];
        }
        if(config.mmd5)
        {
            [mmd5 mmd5Dir:config.luaFolder outDir:config.luaFolder];
        }
    }

    if([config.resFolder length] > 0)
    {
        [self xattrPath:config.resFolder];
        if(config.backup)
        {
            NSString * backup = getBackupPath(config.resFolder);
            NSLog(@"正在备份资源文件：%@ ---> %@", config.resFolder, backup);
            copyFolderFromPath(config.resFolder, backup);
        }
        [ImageTools solveImage:config.resFolder];
        if(config.mmd5)
        {
            [mmd5 mmd5Dir:config.resFolder outDir:config.resFolder];
        }
        if(config.addRubishRes) {
            [allFolder addObject:config.resFolder];
        }
    }
    
    if(config.addRubishRes) {
        [self addRubbishFileWithFolders:allFolder];
    }
    
    Timer_summary();
//
//    NSTask *myTask = [[NSTask alloc] init];//    myTask.launchPath = @"/bin/sh";
//
//    NSMutableArray * args = [[NSMutableArray alloc] init];
//    [args addObject:@"-p"];
    
//    [args addObject:project];
//    for(NSString * file in classSet)
//    {
//        NSString *pathH = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"/out/%@.h", file]];
//        NSString *pathM = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"/out/%@.m", file]];
//        [args addObject:@"-f"];
//        [args addObject:pathH];
//        [args addObject:@"-f"];
//        [args addObject:pathM];
//    }
//    if(targets)
//    {
//        for(NSString * t in targets)
//        {
//            [args addObject:@"-t"];
//            [args addObject:t];
//        }
//    }
//    NSString * rbFile = [[NSBundle mainBundle] pathForResource:@"File/CodeGenerator/script/project" ofType:@"rb"];
//    rbFile = [[@"export export LANG=\"zh_CN.UTF-8\"\nruby " stringByAppendingString:rbFile] stringByAppendingString:@" "];
//    NSString * cmd = [rbFile stringByAppendingString:[args componentsJoinedByString:@" "]];
//    [myTask setArguments:@[@"-c", cmd]];
//    [myTask launch];
//    [myTask waitUntilExit];
}

@end






