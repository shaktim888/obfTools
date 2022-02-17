#ifndef StringObf_h
#define StringObf_h

@interface StringObf : NSObject

+ (void) build;
+ (void) save: (NSString *) folder;
+ (NSString *) getFileName;

+ (NSString *) ObfOC : (NSString*) str;
+ (NSString *) ObfCPtr : (NSString*) str;

+ (NSString *) importHead;

@end

#endif /* StringObf_h */
