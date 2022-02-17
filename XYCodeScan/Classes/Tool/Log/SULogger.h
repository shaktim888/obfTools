#import <Foundation/Foundation.h>

@interface SULogger : NSObject

/**
 *  描述：初始化Logger
 */
+ (void)start;

/**
 *  描述：改变Log面板状态(隐藏->显示 or 显示->隐藏)
 */
+ (void)visibleChange;

@end
