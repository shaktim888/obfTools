#ifndef HYGenerateNameTool_h
#define HYGenerateNameTool_h

typedef NS_ENUM(NSInteger, HYNameType) {
    Skip = 0,
    TypeName = 1,
    FuncName = 2,
    VarName = 3,
    ArgName = 4,
    WordName = 5,
    ResName = 6,
};

typedef NS_ENUM(NSInteger, IgnoreEnumType) {
    Ignore_NONE = 0,
    Ignore_ALL = 1,
    
    Ignore_Type = 2,
    Ignore_Func = 3,
    Ignore_Arg = 4,
    Ignore_Var = 5,
    
    Ignore_Folder = 6,
    Ignore_Group = 7,
    Ignore_File = 8,
    
};

@interface HYGenerateNameTool : NSObject
+ (void) resolveWord : (NSString *) path;

+ (NSString*) generateName : (HYNameType) type from: (NSString*) from typeName: (NSString*) typeName cache : (BOOL) cache globalClassPrefix : (NSString*) globalClassPrefix;

+ (NSString*) generateByName : (HYNameType) type from: (NSString*) from cache : (BOOL) cache;
+ (NSString*) generateByTypeName:(HYNameType)type from:(NSString *)from cache:(BOOL)cache;

+ (void) clearCache : (HYNameType) type;
+ (void) buildCustomForbiddenName;
+ (BOOL) checkNameOK: (NSString *) name type : (IgnoreEnumType) type scanAll : (BOOL) scanAll;
+ (BOOL) checkGroupOK: (NSString *) name;
+ (void) addCustomForbiddenName : (NSString*) name;
+ (bool) isIgnoreFile : (NSString *) fileName;
@end

#endif /* HYGenerateNameTool_h */
