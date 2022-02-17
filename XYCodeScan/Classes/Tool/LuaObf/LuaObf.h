#ifndef LuaObf_h
#define LuaObf_h


@interface LuaObf : NSObject
{
}
+ (void) compressLuaFile: (NSString* ) folder output: (NSString *) output prefix:(NSString *) prefix;
+ (void) obf : (NSString*) file outfile: (NSString*) outfile;

@end

#endif /* LuaObf_h */
