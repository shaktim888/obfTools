#ifndef xxteaTools_h
#define xxteaTools_h

@interface xxteaTools : NSObject
{
}
+ (void) decodeFile :(NSString*) file output: (NSString*) output key : (NSString*) key sign :(NSString*) sign;
+ (void) encodeFile : (NSString*) file output: (NSString*) output key : (NSString*) key sign :(NSString*) sign;

@end


#endif /* xxteaTools_h */
