#import <Foundation/Foundation.h>

#import "xxtea.h"
#import "xxteaTools.h"
#import "FileOperation.hpp"

void skipBOM(const char*& chunk, int& chunkSize)
{
    // UTF-8 BOM? skip
    if (static_cast<unsigned char>(chunk[0]) == 0xEF &&
        static_cast<unsigned char>(chunk[1]) == 0xBB &&
        static_cast<unsigned char>(chunk[2]) == 0xBF)
    {
        chunk += 3;
        chunkSize -= 3;
    }
}

@implementation xxteaTools

//
//+ (void) setXXTEAKeyAndSign : (NSString*) key sign :(NSString*) sign
//{
//    if (key && sign)
//    {
//        _xxteaKeyLen = strlen([key UTF8String]);
//        _xxteaKey = key;
//
//        _xxteaKeyLen = strlen([key UTF8String]);
//        _xxteaSign = sign;
//
//        _xxteaEnabled = true;
//    }
//    else
//    {
//        _xxteaEnabled = false;
//    }
//}

+ (const char*) xxteaLoadBuffer : (const char *)chunk chunkSize:(int) chunkSize contentSize:(uint32_t&) contentSize xxteaKey : (NSString*) _xxteaKey xxteaSign :(NSString*) _xxteaSign
{
    
    bool _xxteaEnabled = false;
    size_t _xxteaKeyLen = 0;
    size_t _xxteaSignLen = 0;
    
    if (_xxteaKey && _xxteaSign)
    {
        _xxteaKeyLen = strlen([_xxteaKey UTF8String]);
        _xxteaEnabled = true;
        _xxteaSignLen = strlen([_xxteaSign UTF8String]);
    }
    else
    {
        _xxteaEnabled = false;
    }
    if (_xxteaEnabled && strncmp(chunk, [_xxteaSign UTF8String], _xxteaSignLen) == 0)
    {
        // decrypt XXTEA
        xxtea_long len = 0;
        unsigned char* result = xxtea_decrypt((unsigned char*)chunk + _xxteaSignLen,
                                              (xxtea_long)chunkSize - _xxteaSignLen,
                                              (unsigned char*)[_xxteaKey UTF8String],
                                              (xxtea_long)_xxteaKeyLen,
                                              &len);
        unsigned char* content = result;
        contentSize = len;
        skipBOM((const char*&)content, (int&)contentSize);
        return (const char*)content;
    }
    else
    {
        contentSize = chunkSize;
        skipBOM(chunk, (int&)contentSize);
        return chunk;
    }
}

+ (const char*) xxteaEncBuffer : (const char *)chunk chunkSize:(int) chunkSize contentSize:(uint32_t&) contentSize xxteaKey : (NSString*) _xxteaKey xxteaSign :(NSString*) _xxteaSign
{
    
    bool _xxteaEnabled = false;
    size_t _xxteaKeyLen = 0;
    size_t _xxteaSignLen = 0;
    
    if (_xxteaKey && _xxteaSign)
    {
        _xxteaKeyLen = strlen([_xxteaKey UTF8String]);
        _xxteaEnabled = true;
        _xxteaSignLen = strlen([_xxteaSign UTF8String]);
    }
    else
    {
        _xxteaEnabled = false;
    }
    if (_xxteaEnabled && strncmp(chunk, [_xxteaSign UTF8String], _xxteaSignLen) == 0)
    {
        // encrypt XXTEA
        xxtea_long len = 0;
        unsigned char* result = xxtea_encrypt((unsigned char*)chunk + _xxteaSignLen,
                                              (xxtea_long)chunkSize - _xxteaSignLen,
                                              (unsigned char*)[_xxteaKey UTF8String],
                                              (xxtea_long)_xxteaKeyLen,
                                              &len);
        contentSize = len;
        return (const char*)result;
    }
    else
    {
        contentSize = chunkSize;
        return chunk;
    }
}
+ (void) decodeFile :(NSString*) file output: (NSString*) output key : (NSString*) key sign :(NSString*) sign
{
    file = [file stringByStandardizingPath];
    output = [output stringByStandardizingPath];
    BOOL isFolder = NO;
    BOOL isExist = [[NSFileManager defaultManager]  fileExistsAtPath:file isDirectory:&isFolder];
    if(isExist && !isFolder) {
        NSData *reader = [NSData dataWithContentsOfFile:file];
        const char * data = (const char *)[reader bytes];
        uint32_t retCnt = 0;
        const char * ret = [self xxteaLoadBuffer:data chunkSize:reader.length contentSize:(uint32_t&)retCnt xxteaKey:key xxteaSign:sign];
        FileOperation::createDirectory([[output stringByDeletingLastPathComponent] UTF8String]);
        NSData * dec = [NSData dataWithBytes:ret length:retCnt];
        [dec writeToFile:output atomically:true];
        
    }
}


+ (void) encodeFile : (NSString*) file output: (NSString*) output key : (NSString*) key sign :(NSString*) sign
{
    file = [file stringByStandardizingPath];
    output = [output stringByStandardizingPath];
    NSData *reader = [NSData dataWithContentsOfFile:file];
    const char * data = (const char *)[reader bytes];

    uint32_t retCnt = 0;
    const char * ret = [self xxteaEncBuffer:data chunkSize:reader.length contentSize:(uint32_t&)retCnt xxteaKey:key xxteaSign:sign];
    NSData * dec = [NSData dataWithBytes:ret length:retCnt];
    [dec writeToFile:output atomically:true];
}

@end
