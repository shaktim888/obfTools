#ifndef mmd5_hpp
#define mmd5_hpp

@interface mmd5 : NSObject

+(void) mmd5File :(NSString *) inFile outDir: (NSString *) outFile;
+(void) mmd5Dir : (NSString *) inDir outDir: (NSString *) outDir;
+(void) genAPngPic: (NSString*) inName;
+(void) genAJpgPic: (NSString*) inName;
@end
#endif /* mmd5_hpp */
