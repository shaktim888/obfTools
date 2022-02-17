//
//  HYObfuscationTool.h
//  HYCodeObfuscation
//
//  Created by HY admin on 2019/8/17.
//  Copyright © 2019年 HY admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYObfuscationTool : NSObject

/** 加密字符串 */
//+ (void)encryptString:(NSString *)string
//           completion:(void (^)(NSString *h, NSString *m))completion;
//
///** 加密dir下的所有字符串 */
//+ (void)encryptStringsAtDir:(NSString *)dir
//                   progress:(void (^)(NSString *detail))progress
//                 completion:(void (^)(NSString *h, NSString *m))completion;

/** 混淆dir下的所有类名、方法名 */
+ (void) reset;
+ (void) write : (NSString *) folder;

+ (void)obfuscateAtDir:(NSArray<NSString*> *)dir
              prefixes:(NSArray *)prefixes;

+ (void) obfuscateWithFiles: (NSArray<NSString*> *) files
                   prefixes:(NSArray *)prefixes;

@end
