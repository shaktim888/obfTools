//
//  NSString+Extension.h
//  CodeObfuscation
//
//  Created by HY admin on 2019/8/16.
//  Copyright © 2019年 HY admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extension)

/** 生成length长度的随机字符串（不包含数字） */
+ (instancetype)hy_randomStringWithoutDigitalWithLength:(int)length;
+ (instancetype)hy_randomStringWithLetters:(int)length letters: (NSString *) letters;
/** 去除空格 */
- (instancetype)hy_stringByRemovingSpace;

/** 将字符串用空格分割成数组 */
- (NSArray *)hy_componentsSeparatedBySpace;

- (instancetype)hy_firstCharUppercase;
- (instancetype)hy_firstCharLowercase;

/** 从mainBundle中加载文件数据 */
+ (instancetype)hy_stringWithFilename:(NSString *)filename
                            extension:(NSString *)extension;

+ (instancetype)hy_stringWithFile:(NSString*)fileName;
/** 生成MD5 */
- (NSString *)hy_MD5;

/** 生成crc32 */
- (NSString *)hy_crc32;

@end
