#import <Foundation/Foundation.h>

/** 类名、方法名 */
@interface HYTokensClientData : NSObject
@property (nonatomic, strong) NSArray *prefixes;
@property (nonatomic, strong) NSMutableSet *typeTokens;
@property (nonatomic, strong) NSMutableSet *funcTokens;
@property (nonatomic, strong) NSMutableSet *varTokens;
@property (nonatomic, strong) NSMutableSet *argTokens;
@property (nonatomic, strong) NSMutableSet *propTokens;

@property (nonatomic, copy) NSString *file;
@end

@interface HYClangTool : NSObject

/** 获得file中的所有字符串 */
+ (NSSet *)stringsWithFile:(NSString *)file
                searchPath:(NSString *)searchPath;

/** 获得file中的所有类名、方法名） */
+ (HYTokensClientData *)classesAndMethodsWithFile:(NSString *)file
                            prefixes:(NSArray *)prefixes
                          searchPath:(NSString *)searchPath;


/** 扫描所有的符号 */
+ (HYTokensClientData *)scanAllKeys:(NSString *)file
                                       searchPath:(NSString *)searchPath;

+ (void) clearCache;

@end
