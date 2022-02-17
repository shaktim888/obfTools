//
//  ZipEncrypt.h
//  HYCodeScan
//
//  Created by admin on 2020/3/26.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef ZipEncrypt_h
#define ZipEncrypt_h

#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif

FOUNDATION_EXPORT void compressToZip(const char* folder, const char * saveTo);

#endif /* ZipEncrypt_h */
