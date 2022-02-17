//
//  XcodeClang.m
//  HYCodeScan
//
//  Created by admin on 2020/7/21.
//

#import "ClangXcode.h"
#import "clang-c/Index.h"
#import "PBXProjectManager.h"
#import "UserConfig.h"
#import "JunkCodeClientData.h"
#import "ClangTokenParser.h"

static NSString * const RUN_Scheme = @"Debug";


@interface ClangXcode()
{
    NSMutableDictionary * _allFiles;
    DFModelBuilder * _modelBuilder;
}

@property (nonatomic, strong) DFModelBuilder* modelBuilder;
@end

@implementation ClangXcode

- (instancetype) init {
    self = [super init];
    if (self) {
        _allFiles = [[NSMutableDictionary alloc] init];
        _modelBuilder = [[DFModelBuilder alloc] init];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


- (void)obfWithTarget:(PBXTarget*) target
{
    NSMutableArray<PBXBuildFile*>* arr = target.sourcesBuildPhase.files;
    for(PBXBuildFile* file in arr) {
        [self junkCodeWithFile:file target:target];
    }
    for(NSString * f in _allFiles) {
        JunkCodeClientData* data = _allFiles[f];
        [data obfAll:self.modelBuilder];
    }
    for(NSString * f in _allFiles) {
        JunkCodeClientData* data = _allFiles[f];
        [data updateContent];
    }
}

/** 花指令 */
- (BOOL)junkCodeWithFile:(PBXBuildFile *)file
                  target:(PBXTarget *)target
{
    JunkCodeClientData* data = [[JunkCodeClientData alloc] initWithFile:[file.fileRef getFullPath]];
    [self _visitASTWithFile:file
                     target:target
                    visitor:_visitJunkCodes
                 clientData:(__bridge void *)data];
    [_allFiles setObject:data forKey:[file.fileRef getFullPath]];
    return true;
}

- (void)obfWithXcode
{
    [_allFiles removeAllObjects];
    if([UserConfig sharedInstance].xcodePath.length == 0) {
        return;
    }
    PBXProjParser* parser = [[PBXProjParser alloc] init];
    [parser parseProjectWithPath:[UserConfig sharedInstance].xcodePath];
    NSMutableArray* targets = [[NSMutableArray alloc] init];
    if([UserConfig sharedInstance].targets.length > 0) {
        NSArray * splits = [[UserConfig sharedInstance].targets componentsSeparatedByString:@","];
        for(NSString * str in splits) {
            PBXTarget* target = [parser.project getTargetByName:str];
            if(target) {
                [targets addObject:target];
            }
        }
    } else {
        PBXTarget* target = [parser.project getMobileTarget];
        if(target) {
            [targets addObject:target];
        } else {
            [targets addObject:parser.project.targets.firstObject];
        }
    }
    for(PBXTarget * target in targets) {
        [self obfWithTarget:target];
    }
}

// Supported indexer callback functions
void indexDeclaration(CXClientData client_data, const CXIdxDeclInfo* declaration);
CXIdxClientFile ppIncludedFile(CXClientData client_data, const CXIdxIncludedFileInfo* included_file);
void indexEntityReference(CXClientData client_data, const CXIdxEntityRefInfo *);

static IndexerCallbacks indexerCallbacks = {
    .indexDeclaration = indexDeclaration,
    .ppIncludedFile = ppIncludedFile,
    .indexEntityReference = indexEntityReference,
};

/** 遍历某个文件的语法树 */
- (void)_visitASTWithFile:(PBXBuildFile *) buildFile
                   target:(PBXTarget *)target
                  visitor:(CXCursorVisitor)visitor
               clientData:(CXClientData)clientData
{
    NSString * file = [buildFile.fileRef getFullPath];
    if(file.length == 0) return;
    // 文件路径
    const char *filepath = file.UTF8String;
    
    // 创建index
    CXIndex index = clang_createIndex(1, 1);
    
    NSMutableArray * buildArgs = [[NSMutableArray alloc] init];
    [buildArgs addObject:@"-c"];
    [buildArgs addObject:@"-arch"];
    [buildArgs addObject:@"arm64"];
    [buildArgs addObject:@"-isysroot"];
    [buildArgs addObject:@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"];
    bool isCustomArc = false;
    NSArray * compileFlag = [buildFile getCompileFlag];
    if(compileFlag) {
        for (NSString *flg in compileFlag) {
            if([flg containsString:@"objc-arc"]){
                isCustomArc = true;
            }
            [buildArgs addObject:flg];
        }
    }

    if([[file pathExtension] isEqualToString:@"m"]) {
        [buildArgs addObject:@"-x"];
        [buildArgs addObject:@"objective-c"];
        if(!isCustomArc) {
            NSString * arc = [target getBuildSetting:RUN_Scheme name:@"CLANG_ENABLE_OBJC_ARC"];
            if([arc isEqualToString:@"YES"]) {
                [buildArgs addObject:@"-fobjc-arc"];
            } else {
                [buildArgs addObject:@"-fno-objc-arc"];
            }
        }
        NSString * weak = [target getBuildSetting:RUN_Scheme name:@"CLANG_ENABLE_OBJC_WEAK"];
        if([weak isEqualToString:@"YES"]) {
            [buildArgs addObject:@"-fobjc-weak"];
        }
    } else if([[file pathExtension] isEqualToString:@"mm"]) {
        [buildArgs addObject:@"-x"];
        [buildArgs addObject:@"objective-c++"];
        NSString * cxx = [target getBuildSetting:RUN_Scheme name:@"CLANG_CXX_LANGUAGE_STANDARD"];
        if(cxx) {
            [buildArgs addObject:[NSString stringWithFormat:@"-std=%@", cxx]];
        }
        NSString * libs = [target getBuildSetting:RUN_Scheme name:@"CLANG_CXX_LIBRARY"];
        if(libs) {
            [buildArgs addObject:[NSString stringWithFormat:@"-stdlib=%@", libs]];
        }
        if(!isCustomArc) {
            NSString * arc = [target getBuildSetting:RUN_Scheme name:@"CLANG_ENABLE_OBJC_ARC"];
            if([arc isEqualToString:@"YES"]) {
                [buildArgs addObject:@"-fobjc-arc"];
            } else {
                [buildArgs addObject:@"-fno-objc-arc"];
            }
        }
        NSString * weak = [target getBuildSetting:RUN_Scheme name:@"CLANG_ENABLE_OBJC_WEAK"];
        if([weak isEqualToString:@"YES"]) {
            [buildArgs addObject:@"-fobjc-weak"];
        }
    } else if([[file pathExtension] isEqualToString:@"cpp"]) {
        [buildArgs addObject:@"-x"];
        [buildArgs addObject:@"c++"];
        NSString * cxx = [target getBuildSetting:RUN_Scheme name:@"CLANG_CXX_LANGUAGE_STANDARD"];
        if(cxx) {
            [buildArgs addObject:[NSString stringWithFormat:@"-std=%@", cxx]];
        }
        NSString * libs = [target getBuildSetting:RUN_Scheme name:@"CLANG_CXX_LIBRARY"];
        if(libs) {
            [buildArgs addObject:[NSString stringWithFormat:@"-stdlib=%@", libs]];
        }
    } else if([[file pathExtension] isEqualToString:@"c"]) {
        [buildArgs addObject:@"-x"];
        [buildArgs addObject:@"c"];
    }
    
    NSArray* searchPaths = [target getSearchPaths:RUN_Scheme];
    if(searchPaths) {
        for (NSString *subDir in searchPaths) {
            if(![subDir containsString:@"inherited"]) {
                [buildArgs addObject:@"-I"];
                [buildArgs addObject:subDir];
            }
        }
    }
    NSString * pchFile = [target getPchFile:RUN_Scheme];
    if(pchFile) {
        [buildArgs addObject:@"-include"];
        [buildArgs addObject:pchFile];
    }
    NSArray * defines = [target getDefine:RUN_Scheme];
    if(defines) {
        for (NSString *de in defines) {
            if(![de containsString:@"inherited"]) {
                [buildArgs addObject:@"-D"];
                [buildArgs addObject:de];
            }
        }
    }
    [buildArgs addObject:@"-ast-dump"];
    
    size_t argCount = buildArgs.count;
    int argIndex = 0;
    const char **args = malloc(sizeof(char *) * argCount);
    for (NSString *arg in buildArgs) {
        args[argIndex++] = arg.UTF8String;
    }
    
    CXIndexAction action = clang_IndexAction_create(index);
    // 解析语法树，返回根节点TranslationUnit
    
    CXTranslationUnit tu = clang_parseTranslationUnit(index, filepath,
                                                      args,
                                                      (int)argCount,
                                                      NULL, 0, CXTranslationUnit_None);
    
    free(args);
    if (!tu) return;
    _modelBuilder.translationUnit = tu;
    int indexResult = clang_indexTranslationUnit(action,
                                                 (__bridge CXClientData)_modelBuilder,
                                                 &indexerCallbacks,
                                                 sizeof(indexerCallbacks),
                                                 CXIndexOpt_SuppressWarnings | CXIndexOpt_SuppressRedundantRefs,
    tu);
    
    
    // 解析语法树
    clang_visitChildren(clang_getTranslationUnitCursor(tu),
                        visitor, clientData);
    
    // Cleanup
    clang_IndexAction_dispose(action);
    // 销毁
    clang_disposeTranslationUnit(tu);
    _modelBuilder.translationUnit = nil;
    clang_disposeIndex(index);
    (void) indexResult;
}

@end
