
#ifndef HYDefineRenameTool_h
#define HYDefineRenameTool_h

@interface HYDefineRenameTool : NSObject

+(void) renameHeadFile : (NSArray<NSString*> *) fileList callback:(void(^)(NSString*)) call;

@end


#endif
