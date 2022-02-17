#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
#import <AppKit/AppKit.h>
#import "ImageObf.h"

static bool isBitSet(char ch, int pos) {
    // 7 6 5 4 3 2 1 0
    ch = ch >> pos;
    if(ch & 1)
        return true;
    return false;
}

static NSString* decodeImg_(NSString* imgFile)
{
    NSImage * image = [[NSImage alloc] initWithContentsOfFile:imgFile];
//    UIImage * image = [[UIImage alloc] initWithContentsOfFile:imgFile];
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    
    CGImageRef imageRef = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
//    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);
    // char to work on
    char ch=0;
    int bit_count = 0;
    unsigned char * arr = malloc(sizeof(char) * width * height / 2);
    int len = 0;
    memset(arr, 0, sizeof(char) * width * height / 8);
    bool isStop = false;
    bool hasAlpha = bitsPerPixel / bitsPerComponent > 3;
    for(int y=0;y < height && !isStop;y++)
    {
        for(int x=0;x < width && !isStop;x++)
        {
            if(hasAlpha) {
                unsigned char alpha = *(buffer + y * bytesPerRow + x * 4 + 3);
                if(alpha != 255) continue;
            }
            for(int color=0; color < 3 && !isStop; color++) {
                unsigned char c = *(buffer + y * bytesPerRow + x * 4 + color);
                if(isBitSet(c,0))
                    ch |= 1;
                bit_count++;
                if(bit_count == 8) {
                    bit_count = 0;
                    arr[len++] = ch;
                    // NULL char is encountered
                    if(ch == '\0') {
                        isStop = true;
                        break;
                    }
                    ch = 0;
                }
                else {
                    ch = ch << 1;
                }
            }
        }
    }
    NSString* ret = [[NSString alloc] initWithUTF8String:(const char *)arr];
    return ret;
}

static void encodeImg_(NSString* imgFile ,NSString * msg, NSString* path)
{
    if(!path) path = imgFile;
    imgFile = [imgFile stringByStandardizingPath];
    path = [path stringByStandardizingPath];
    NSImage * image = [[NSImage alloc] initWithContentsOfFile:imgFile];
    if(!image) return;
    //    UIImage * image = [[UIImage alloc] initWithContentsOfFile:imgFile];
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    
    CGImageRef imageRef = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
    //    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);  //获取图片像素的宽
    size_t height = CGImageGetHeight(imageRef); //获取图片像素的高
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    bool shouldInterpolate = CGImageGetShouldInterpolate(imageRef);
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(imageRef);
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);
    
    bool isStop = false;
    const char * str = [msg UTF8String];
    // char to work on
    unsigned long totalLen = strlen(str);
    int curItr = 0;
    char ch = str[curItr];
    int bit_count = 0;
    // to check whether file has ended
    bool last_null_char = false;
    // to check if the whole message is encoded or not
    bool encoded = false;
    bool hasAlpha = bitsPerPixel / bitsPerComponent > 3;
    for(int y=0;y < height && !isStop;y++)
    {
        for(int x=0;x < width && !isStop;x++)
        {
            if(hasAlpha) {
                unsigned char alpha = *(buffer + y * bytesPerRow + x * 4 + 3);
                if(alpha != 255) continue;
            }
            for(int color=0; color < 3 && !isStop; color++) {
                if(isBitSet(ch,7-bit_count))
                    buffer[y * bytesPerRow + x * 4 + color] |= 1;
                else
                    buffer[y * bytesPerRow + x * 4 + color] &= ~1;
                
                // increment bit_count to work on next bit
                bit_count++;
                
                // if last_null_char is true and bit_count is 8, then our message is successfully encode.
                if(last_null_char && bit_count == 8) {
                    encoded  = true;
                    isStop = true;
                    break;
                }
                
                // if bit_count is 8 we pick the next char from the file and work on it
                if(bit_count == 8) {
                    bit_count = 0;
                    ch = str[++curItr];
                    
                    // if EndOfFile(EOF) is encountered insert NULL char to the image
                    if(curItr == totalLen) {
                        last_null_char = true;
                        ch = '\0';
                    }
                }
            }
        }
    }
    // whole message was not encoded
    if(!encoded) {
        NSLog(@"Error...");
    } else {
        CFDataRef effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
        CGDataProviderRef effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
        CGImageRef effectedCgImage = CGImageCreate(
                                                   width, height,
                                                   bitsPerComponent, bitsPerPixel, bytesPerRow,
                                                   colorSpace, bitmapInfo, effectedDataProvider,
                                                   NULL, shouldInterpolate, intent);
//        NSSize size = NSMakeSize(width, height);
//        NSImage *effectedImage = [[NSImage alloc] initWithCGImage:effectedCgImage size:size];
        CFRelease(effectedDataProvider);
        CFRelease(effectedData);
        CFRelease(data);
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:effectedCgImage];
        NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        [pngData writeToFile:path atomically:YES];
        CGImageRelease(effectedCgImage);
    }
}

@implementation ImageObf

+(void) encodeImg : (NSString *) json img : (NSString*) img{
    NSData * data = [NSData dataWithContentsOfFile:json];
    NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    encodeImg_(img, str, img);
}

+(NSString* ) decodeImg : (NSString*) img
{
    return decodeImg_(img);
}

@end
