//
//  Xor.m
//  HYCodeScan
//
//  Created by admin on 2020/3/26.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "Xor.h"

namespace Xor
{
    // 实现一个固定的随机数生成器
    class WellRng512
    {
    public:
        WellRng512()
        {
            index = 0;
            state[0] = 33;
            state[1] = 22;
            state[2] = 42;
            state[3] = 55;
            state[4] = 23;
            state[5] = 45;
            state[6] = 34;
            state[7] = 65;
            state[8] = 43;
            state[9] = 11;
            state[10] = 54;
            state[11] = 56;
            state[12] = 32;
            state[13] = 67;
            state[14] = 34;
            state[15] = 55;
        }
        //返回32位随机数
        unsigned int WELLRNG512()
        {
            unsigned int a, b, c, d;
            a = state[index];
            c = state[(index + 13) & 15];
            b = a^c ^ (a << 16) ^ (c << 15);
            c = state[(index + 9) & 15];
            c ^= (c >> 11);
            a = state[index] = b^c;
            d = a ^ ((a << 5) & 0xBA442D26UL);
            index = (index + 15) & 15;
            a = state[index];
            state[index] = a^b^d ^ (a << 2) ^ (b << 18) ^ (c << 28);
            return state[index];
        }
    protected:

        //初始化状态到随即位
        unsigned int state[16];
        //初始化必须为0
        unsigned int index;
    };
    static unsigned char mXorKey[1024] = { 0 };
    
    
    static void initXor()
    {
        if (mXorKey[0] != 0)
            return;
        WellRng512 rng;
        // 使用固定的随机数生成器在任何平台上都生成一个一样的key
        for (size_t i = 0; i < sizeof(mXorKey); i++)
        {
            mXorKey[i] = rng.WELLRNG512();
        }
    }
    
    static bool checkEncrypt(unsigned char* &buffer, ssize_t * sizeRead)
    {
        initXor();
        if (*sizeRead >= 6
            && buffer[*sizeRead - 1] == mXorKey[(*sizeRead - 0) % sizeof(mXorKey)]
            && buffer[*sizeRead - 2] == mXorKey[(*sizeRead - 1) % sizeof(mXorKey)]
            && buffer[*sizeRead - 3] == mXorKey[(*sizeRead - 2) % sizeof(mXorKey)]
            && buffer[*sizeRead - 4] == mXorKey[(*sizeRead - 3) % sizeof(mXorKey)]
            && buffer[*sizeRead - 5] == mXorKey[(*sizeRead - 4) % sizeof(mXorKey)]
            && buffer[*sizeRead - 6] == mXorKey[(*sizeRead - 5) % sizeof(mXorKey)]) {
            return true;
        }
        return false;
    }
    static void decodeXor(unsigned char * &buffer, ssize_t * fileSize)
    {
        initXor();
        if(checkEncrypt(buffer, fileSize))
        {
            *fileSize -= 6;
//            if (forString) {
//                buffer = (unsigned char*)realloc(buffer, sizeof(unsigned char) * (*sizeRead + 1));
//                buffer[*sizeRead] = '\0';
//            }
//            else
//            {
                buffer = (unsigned char*)realloc(buffer, sizeof(unsigned char) * (*fileSize));
//            }
            for (ssize_t i = 0; i < *fileSize; i++)
            {
                buffer[i] = buffer[i] ^ mXorKey[*fileSize % sizeof(mXorKey)];
            }
        }
    }

#ifdef ENCRYPT_XOR
    static void encodeXor(unsigned char * &buffer, ssize_t * fileSize)
    {
        initXor();
        if(!checkEncrypt(buffer, fileSize))
        {
            for (ssize_t i = 0; i < *fileSize; i++)
            {
                buffer[i] = buffer[i] ^ mXorKey[*fileSize % sizeof(mXorKey)];
            }
            *fileSize += 6;
            buffer = (unsigned char*)realloc(buffer, sizeof(unsigned char) * (*fileSize));
            buffer[*fileSize - 1] = mXorKey[(*fileSize - 0) % sizeof(mXorKey)];
            buffer[*fileSize - 2] = mXorKey[(*fileSize - 1) % sizeof(mXorKey)];
            buffer[*fileSize - 3] = mXorKey[(*fileSize - 2) % sizeof(mXorKey)];
            buffer[*fileSize - 4] = mXorKey[(*fileSize - 3) % sizeof(mXorKey)];
            buffer[*fileSize - 5] = mXorKey[(*fileSize - 4) % sizeof(mXorKey)];
            buffer[*fileSize - 6] = mXorKey[(*fileSize - 5) % sizeof(mXorKey)];
        }
    }
    
    unsigned char* encodeFileData(const char * filename, const char* mode, ssize_t *size)
    {
        unsigned char * buffer = nullptr;
        *size = 0;
        do
        {
            // read the file from hardware
            FILE *fp = fopen(filename, mode);
            if(!fp) {
                return nullptr;
            }

            fseek(fp,0,SEEK_END);
            *size = ftell(fp);
            fseek(fp,0,SEEK_SET);
            buffer = (unsigned char*)malloc(*size);
            *size = fread(buffer,sizeof(unsigned char), *size,fp);
            encodeXor(buffer, size);
            fclose(fp);
        } while (0);

        if (!buffer)
        {
            printf("Get data from file(%s) failed!", filename);
        }
        return buffer;
    }
#endif

    unsigned char* getFileData(const char * filename, const char* mode, ssize_t *size)
    {
        unsigned char * buffer = nullptr;
        *size = 0;
        do
        {
            // read the file from hardware
            FILE *fp = fopen(filename, mode);
            if(!fp) {
                return nullptr;
            }

            fseek(fp,0,SEEK_END);
            *size = ftell(fp);
            fseek(fp,0,SEEK_SET);
            buffer = (unsigned char*)malloc(*size);
            *size = fread(buffer,sizeof(unsigned char), *size,fp);
            decodeXor(buffer, size);
            fclose(fp);
        } while (0);

        if (!buffer)
        {
            printf("Get data from file(%s) failed!", filename);
        }
        return buffer;
    }
    
    
}
