//
//  ZipEncrypt.m
//  HYCodeScan
//
//  Created by admin on 2020/3/26.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "Xor.h"
#include "ZipEncrypt.h"

#include "exec_cmd.h"
#include <string>


void compressToZip(const char* folder, const char * saveTo)
{
    std::string saveToPath = saveTo;
    std::string directory;
    const size_t last_slash_idx = saveToPath.rfind('/');
    if (std::string::npos != last_slash_idx)
    {
        directory = saveToPath.substr(0, last_slash_idx);
    } else {
        const size_t last_slash_idx = saveToPath.rfind('\\');
        if (std::string::npos != last_slash_idx)
        {
            directory = saveToPath.substr(0, last_slash_idx);
        }
    }
    exec_cmd((std::string("chmod +r ") + folder).c_str());
    exec_cmd((std::string("chmod +w ") + directory).c_str());
    std::string cmd = "cd ";
    cmd = cmd + folder + "\nzip -q -r " + saveTo + " .";
    exec_cmd(cmd.c_str());
    ssize_t size = 0;
    unsigned char *zipFileData = Xor::encodeFileData(saveTo, "rb", &size);
    
    FILE *fp = NULL;
    fp = fopen(saveTo, "wb+");
    if (NULL == fp)
    {
        return;
    }
    fwrite(zipFileData, size, 1, fp);
    
    fclose(fp);
    fp = NULL;
    if (zipFileData) {
      free(zipFileData);
    }
}
