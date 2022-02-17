#ifndef __{{ FuncName }}_h
#define __{{ FuncName }}_h

#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif

#ifdef __OBJC__
#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSString * {{ FuncName }}(char * contents, int key, BOOL hasEmoji);
#endif

FOUNDATION_EXPORT char * {{ CFuncName }} (char * contents, int key, int hasEmoji);

#endif

