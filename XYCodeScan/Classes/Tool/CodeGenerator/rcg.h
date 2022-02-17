#import <Foundation/Foundation.h>

@interface CodeGenerator : NSObject

+(void) rcg : (NSString*) input output : (NSString*) output prop : (int) prop;

+(void) insertCode : (NSString*) inFile output : (NSString*) output import : (NSString*) import code : (NSString*) code;
@end
