
#import "HYClangTool.h"
#import "clang-c/Index.h"
#import "NSFileManager+Extension.h"
#import "NSString+Extension.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "HYGenerateNameTool.h"

@implementation HYTokensClientData

- (instancetype)init {
    
    if (self = [super init]) {
        self.funcTokens = [NSMutableSet set];
        self.typeTokens = [NSMutableSet set];
        self.varTokens  = [NSMutableSet set];
        self.propTokens = [NSMutableSet set];
        self.argTokens  = [NSMutableSet set];
    }
    return self;
}

@end

/** 字符串 */
@interface HYStringsClientData : NSObject
@property (nonatomic, strong) NSMutableSet *strings;
@property (nonatomic, copy) NSString *file;
@end

@implementation HYStringsClientData
@end

@implementation HYClangTool

static const char *_getFilename(CXCursor cursor) {
    CXSourceRange range = clang_getCursorExtent(cursor);
    CXSourceLocation location = clang_getRangeStart(range);
    CXFile file;
    clang_getFileLocation(location, &file, NULL, NULL, NULL);
    return clang_getCString(clang_getFileName(file));
}

static const char *_getCursorName(CXCursor cursor) {
    return clang_getCString(clang_getCursorSpelling(cursor));
}

static const char *_getCursorType(CXCursor cursor) {
    return clang_getCString(clang_getTypeSpelling(clang_getCursorType(cursor)));
}

static NSString * getFileName(const char * name)
{
    NSString * p = [NSString stringWithUTF8String:name];
    return [p stringByDeletingPathExtension];
}

static bool _isFromFile(const char *filepath, CXCursor cursor) {
    if (filepath == NULL) return 0;
    const char *cursorPath = _getFilename(cursor);
    if (cursorPath == NULL) return true;
    // 同名均可
    return [getFileName(cursorPath) isEqualToString:getFileName(filepath)];
}

static NSMutableSet<NSString*> * tempForbiddenNames = NULL;

static void addForbiddenSymbols() {
    if(!tempForbiddenNames)
    {
        tempForbiddenNames = [NSMutableSet new];
    }
}

static bool isTypeCursor(CXCursor *cursor)
{
    return
    cursor->kind == CXCursor_ObjCInterfaceDecl ||
    cursor->kind == CXCursor_ObjCProtocolDecl ||
    cursor->kind == CXCursor_ObjCImplementationDecl ||
    cursor->kind == CXCursor_ClassDecl ||
    cursor->kind == CXCursor_StructDecl ||
    cursor->kind == CXCursor_UnionDecl ||
    cursor->kind == CXCursor_EnumDecl ||
    false;
}

static bool isFuncCursor(CXCursor *cursor)
{
    return
    cursor->kind == CXCursor_ObjCInstanceMethodDecl ||
    cursor->kind == CXCursor_FunctionDecl ||
    cursor->kind == CXCursor_ObjCClassMethodDecl ||
    cursor->kind == CXCursor_CXXMethod ||
    false;
}

static bool isVarCursor(CXCursor * cursor) {
    return
    cursor->kind == CXCursor_FieldDecl ||
    cursor->kind == CXCursor_ObjCIvarDecl ||
    cursor->kind == CXCursor_VarDecl ||
    false;
}

static bool isPropertyCursor(CXCursor *cursor)
{
    return cursor->kind == CXCursor_ObjCPropertyDecl;
}

static bool checkHeadFileIsObjC(NSString * f)
{
    NSData * data = [NSData dataWithContentsOfFile:f];
    NSString *textFileContents = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if(!textFileContents)
    {
        textFileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if ([textFileContents rangeOfString:@"@interface"].location != NSNotFound
        || [textFileContents rangeOfString:@"@protocol"].location != NSNotFound
        || [textFileContents rangeOfString:@"#import"].location != NSNotFound){
        return YES;
    }
    return NO;
}

enum CXChildVisitResult _visitTokens(CXCursor cursor,
                                      CXCursor parent,
                                      CXClientData clientData) {
    if (clientData == NULL) return CXChildVisit_Break;
    
    HYTokensClientData *data = (__bridge HYTokensClientData *)clientData;
    NSString *name1 = [NSString stringWithUTF8String:_getCursorName(cursor)];
    if (!_isFromFile(data.file.UTF8String, cursor)) {
        return CXChildVisit_Continue;
    }
    
    if (
        cursor.kind == CXCursor_ObjCInstanceMethodDecl ||
        cursor.kind == CXCursor_ObjCClassMethodDecl ||
        cursor.kind == CXCursor_ObjCInterfaceDecl ||
        cursor.kind == CXCursor_ObjCProtocolDecl ||
        cursor.kind == CXCursor_ObjCImplementationDecl ||
        cursor.kind == CXCursor_ClassDecl ||
        cursor.kind == CXCursor_UnexposedDecl ||
        cursor.kind == CXCursor_StructDecl ||
        cursor.kind == CXCursor_UnionDecl ||
        cursor.kind == CXCursor_EnumDecl ||
        cursor.kind == CXCursor_FieldDecl ||
        cursor.kind == CXCursor_FunctionDecl ||
        cursor.kind == CXCursor_EnumConstantDecl ||
        cursor.kind == CXCursor_CXXMethod ||
        cursor.kind == CXCursor_ObjCPropertyDecl ||
        cursor.kind == CXCursor_ObjCIvarDecl ||
        cursor.kind == CXCursor_VarDecl ||
        false) {
        NSString *name = [NSString stringWithUTF8String:_getCursorName(cursor)];
        name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSLog(@"%@", name);
        if(isPropertyCursor(&cursor)){
            NSString * setFuncName = [@"set" stringByAppendingString:[name hy_firstCharUppercase]];
            [tempForbiddenNames addObject:setFuncName];
            
            [data.typeTokens removeObject:name];
            [data.typeTokens removeObject:setFuncName];
            
            [data.funcTokens removeObject:name];
            [data.funcTokens removeObject:setFuncName];
            
            [data.varTokens removeObject:name];
            [data.varTokens removeObject:setFuncName];
        }
        
        NSArray *tokens = [name componentsSeparatedByString:@":"];
        int index = 0;
        for (NSString *token in tokens) {
            if([token length] == 0) continue;
            index++;
            IgnoreEnumType t;
            if(isTypeCursor(&cursor))
            {
                t = Ignore_Type;
            }
            else if(isFuncCursor(&cursor)){
                if(index <= 1) {
                    t = Ignore_Func;
                }
                else{
                    t = Ignore_Arg;
                }
            }
            else {
                t = Ignore_Var;
            }
            if ([HYGenerateNameTool checkNameOK:token type:t scanAll:true] && ![tempForbiddenNames containsObject:token]) {
                bool isIgnore = false;
                if( data.prefixes && [data.prefixes count] > 0)
                {
                    // 前缀匹配
                    isIgnore = true;
                    for (NSString *prefix in data.prefixes) {
                        if ([token rangeOfString:prefix].location == 0) {
                            isIgnore = false;
                        }
                    }
                }
                if(!isIgnore)
                {
                    if(isTypeCursor(&cursor))
                    {
                        [data.typeTokens addObject:token];
                    }
                    else if(isFuncCursor(&cursor)){
                        if(index <= 1) {
                            [data.funcTokens addObject:token];
                        } else {
                            [data.argTokens addObject:token];
                        }
                    }
                    else if(isPropertyCursor(&cursor)){
                        [tempForbiddenNames addObject:token];
                        [data.propTokens addObject:token];
                    }
                    else{
                        [data.varTokens addObject:token];
                    }
                }
            } else {
                NSLog(@"Ignored: %@",name);
                if(cursor.kind == CXCursor_ObjCClassMethodDecl ||
                   cursor.kind == CXCursor_ObjCInterfaceDecl ||
                   cursor.kind == CXCursor_ObjCProtocolDecl ||
                   cursor.kind == CXCursor_ObjCImplementationDecl ||
                   cursor.kind == CXCursor_ClassDecl)
                   return CXChildVisit_Recurse;
                else
                    return CXChildVisit_Continue;
            }
        }
        
    }
    
    return CXChildVisit_Recurse;
}

enum CXChildVisitResult _visitStrings(CXCursor cursor,
                                      CXCursor parent,
                                      CXClientData clientData) {
    if (clientData == NULL) return CXChildVisit_Break;
    
    HYStringsClientData *data = (__bridge HYStringsClientData *)clientData;
    if (!_isFromFile(data.file.UTF8String, cursor)) return CXChildVisit_Continue;
    
    if (cursor.kind == CXCursor_StringLiteral) {
        const char *name = _getCursorName(cursor);
        NSString *js = [NSString stringWithFormat:@"decodeURIComponent(escape(%s))", name];
        NSString *string = [[[JSContext alloc] init] evaluateScript:js].toString;
        [data.strings addObject:string];
    }

    return CXChildVisit_Recurse;
}

+ (NSSet *)stringsWithFile:(NSString *)file
                searchPath:(NSString *)searchPath
{
    addForbiddenSymbols();
    HYStringsClientData *data = [[HYStringsClientData alloc] init];
    data.file = file;
    data.strings = [NSMutableSet set];
    [self _visitASTWithFile:file
                 searchPath:searchPath
                    visitor:_visitStrings
                 clientData:(__bridge void *)data
                  isViewAll:false];
    return data.strings;
}

+ (HYTokensClientData *)classesAndMethodsWithFile:(NSString *)file
                            prefixes:(NSArray *)prefixes
                          searchPath:(NSString *)searchPath
{
    addForbiddenSymbols();
    HYTokensClientData *data = [[HYTokensClientData alloc] init];
    data.file = file;
    data.prefixes = prefixes;
    
    [self _visitASTWithFile:file
                 searchPath:searchPath
                    visitor:_visitTokens
                 clientData:(__bridge void *)data
                  isViewAll:false];
    return data;
}

/** 遍历某个文件的语法树 */
+ (void)_visitASTWithFile:(NSString *)file
               searchPath:(NSString *)searchPath
                  visitor:(CXCursorVisitor)visitor
               clientData:(CXClientData)clientData
                isViewAll:(bool)isViewAll
{
    if (file.length == 0) return;
    // 文件路径
    const char *filepath = file.UTF8String;
    
    // 创建index
    CXIndex index = clang_createIndex(1, 1);

    // 搜索路径
    int argCount = 0;
    int argIndex = 0;
    
    const char **args = NULL;
    if([[file pathExtension] isEqualToString:@"h"] || [[file pathExtension] isEqualToString:@"hpp"]){
        if(checkHeadFileIsObjC(file))
        {
            argCount = 2;
            args = malloc(sizeof(char *) * argCount);
            args[argIndex++] = "-x";
            args[argIndex++] = "objective-c";
//            argCount = 5;
//            NSArray *subDirs = nil;
//            if (searchPath.length) {
//                subDirs = [NSFileManager hy_subdirsAtPath:searchPath];
//                argCount += ((int)subDirs.count + 1) * 2;
//            }
//            args = malloc(sizeof(char *) * argCount);
//            args[argIndex++] = "-c";
//            args[argIndex++] = "-arch";
//            args[argIndex++] = "i386";
//            args[argIndex++] = "-isysroot";
//            args[argIndex++] = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk";
//            if (searchPath.length) {
//                args[argIndex++] = "-I";
//                args[argIndex++] = searchPath.UTF8String;
//            }
//            for (NSString *subDir in subDirs) {
//                args[argIndex++] = "-I";
//                args[argIndex++] = subDir.UTF8String;
//            }
        }
        else{
            argCount = 4;
            args = malloc(sizeof(char *) * argCount);
            args[argIndex++] = "-x";
            args[argIndex++] = "c++";
            args[argIndex++] = "-std=c++11";
            args[argIndex++] = "-D__CODE_GENERATOR__";
        }
    }
    // 解析语法树，返回根节点TranslationUnit
    CXTranslationUnit tu = clang_parseTranslationUnit(index, filepath,
                                                      args,
                                                      argCount,
                                                      NULL, 0,
                                                      isViewAll ? (CXTranslationUnit_KeepGoing | CXTranslationUnit_SkipFunctionBodies) : CXTranslationUnit_KeepGoing);
    free(args);
    
    if (!tu) return;
    
    // 解析语法树
    clang_visitChildren(clang_getTranslationUnitCursor(tu),
                        visitor, clientData);
    
    // 销毁
    clang_disposeTranslationUnit(tu);
    clang_disposeIndex(index);
}

+ (void) clearCache
{
    if(tempForbiddenNames)
    {
        [tempForbiddenNames removeAllObjects];
    }
}

enum CXChildVisitResult _visitAll(CXCursor cursor,
                                     CXCursor parent,
                                     CXClientData clientData) {
    if (clientData == NULL) return CXChildVisit_Break;
    
    HYTokensClientData *data = (__bridge HYTokensClientData *)clientData;
    if (!_isFromFile(data.file.UTF8String, cursor)) {
        return CXChildVisit_Continue;
    }
    
    NSString *name = [NSString stringWithUTF8String:_getCursorName(cursor)];
    name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
    if(isPropertyCursor(&cursor)){
        [data.propTokens addObject:name];
    }
    else if(isTypeCursor(&cursor))
    {
        [data.typeTokens addObject:name];
    }
    else if (isFuncCursor(&cursor)) {
        NSArray *tokens = [name componentsSeparatedByString:@":"];
        [data.funcTokens addObject:[tokens firstObject]];
        for(int i = 1; i< tokens.count; i++) {
            [data.argTokens addObject:[tokens objectAtIndex:i]];
        }
    } else {
        [data.varTokens addObject:name];
    }
    return CXChildVisit_Recurse;
}

+ (HYTokensClientData *)scanAllKeys:(NSString *)file searchPath:(NSString *)searchPath { 
    HYTokensClientData *data = [[HYTokensClientData alloc] init];
    data.file = file;
    data.prefixes = NULL;
    
    [self _visitASTWithFile:file
                 searchPath:searchPath
                    visitor:_visitAll
                 clientData:(__bridge void *)data
                  isViewAll:true];
    return data;
}

@end
