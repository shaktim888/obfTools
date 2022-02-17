#ifndef ImageObf_h
#define ImageObf_h

@interface ImageObf : NSObject
{
}

+(void) encodeImg : (NSString *) json img : (NSString*) img;
+(NSString* ) decodeImg : (NSString*) img;

@end
#endif /* ImageObf_h */
