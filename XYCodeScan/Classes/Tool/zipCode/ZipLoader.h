//
//  ZipLoader.h
//  HYCodeScan
//
//  Created by admin on 2020/3/26.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef ZipLoader_h
#define ZipLoader_h

#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif

FOUNDATION_EXPORT void loadZipFile(const char* file, const char * saveTo);

#endif /* ZipLoader_h */
