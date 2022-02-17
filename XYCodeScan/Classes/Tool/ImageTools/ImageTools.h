
@interface ImageTools : NSObject
{
}

+ (void) addNoice : (NSString*) file outfile: (NSString*) outfile;
+ (void) pngquant : (int) speed file : (NSString*) file;

+ (void) solveImage : (NSString*) file;
+ (void) solveOneFile : (NSString*) file;

@end
