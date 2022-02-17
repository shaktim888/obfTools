//
//  NSFileManager+Extension.h
//  HYCodeObfuscation
//
//  Created by HY admin on 2019/8/16.
//  Copyright © 2019年 HY admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Extension)

/** 获得文件的MIMEType */
+ (void)hy_getMIMEType:(NSString*)filepath
            completion:(void (^)(NSString *MIMEType))completion;

/** 将文件名分割成文件名+拓展名 */
+ (void)hy_divideFilename:(NSString *)filename
               completion:(void (^)(NSString *filename, NSString *extension))completion;

/** 获得dir的所有符合extensions拓展名的子路径 */
+ (NSArray *)hy_subpathsAtPath:(NSString *)dir
                    extensions:(NSArray *)extensions;

/** 获得dir的所有子目录 */
+ (NSArray *)hy_subdirsAtPath:(NSString *)dir;

/** 检查某个路径是否存在，如果存在，就生成新的路径名，直到不存在为止 */
+ (NSString *)hy_checkPathExists:(NSString *)path;

@end
