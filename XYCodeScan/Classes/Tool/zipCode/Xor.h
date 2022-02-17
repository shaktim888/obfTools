//
//  Xor.h
//  HYCodeScan
//
//  Created by admin on 2020/3/26.
//  Copyright © 2020 Admin. All rights reserved.
//

#ifndef Xor_h
#define Xor_h

// mac
#define ENCRYPT_XOR

namespace Xor {
#ifdef ENCRYPT_XOR
    unsigned char* encodeFileData(const char * filename, const char* mode, ssize_t *size);
#endif
    unsigned char* getFileData(const char * filename, const char* mode, ssize_t *size);
}

#endif /* Xor_h */
