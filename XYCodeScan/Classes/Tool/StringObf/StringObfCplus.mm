#include "StringObfCplus.h"
#import "StringObf.h"

extern void buildStringObf()
{
    [StringObf build];
}

extern char * ObfOC(const char* str)
{
    NSString * ocStr = [NSString stringWithUTF8String:str];
    if(ocStr) {
        return (char *)[[StringObf ObfOC:ocStr] UTF8String];
    } else {
        return (char*)str;
    }
}

extern char * ObfCPtr(const char* str)
{
    NSString * ocStr = [NSString stringWithUTF8String:str];
    if(ocStr) {
        return (char *)[[StringObf ObfCPtr:ocStr] UTF8String];
    } else {
        return (char*)str;
    }
}

extern char * importObfHead()
{
    return (char *)[[StringObf importHead] UTF8String];
}

extern void saveObfToFolder(char* path)
{
    return [StringObf save:[NSString stringWithUTF8String:path]];
}
