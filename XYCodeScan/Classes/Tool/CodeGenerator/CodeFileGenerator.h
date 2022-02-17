#ifndef CodeFileGenerator_h
#define CodeFileGenerator_h

@interface CodeFileGenerator : NSObject

+ (NSSet*) genCodeFile : (NSString *) outputFolder count : (unsigned int) count;

@end

#endif /* CodeFileGenerator_h */
