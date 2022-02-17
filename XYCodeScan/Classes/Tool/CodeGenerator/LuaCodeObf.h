#ifndef LuaCodeObf_h
#define LuaCodeObf_h


@interface LuaCodeObf : NSObject

+(void) rcg : (NSString*) input output : (NSString*) output;
+(void) generateLuaFile : (NSString *) folder num : (int) num;
@end

#endif /* LuaCodeObf_h */
