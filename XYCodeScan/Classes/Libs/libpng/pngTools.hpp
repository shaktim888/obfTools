//
//  pngTools.hpp
//  HYCodeScan
//
//  Created by admin on 2019/9/23.
//  Copyright © 2019 admin. All rights reserved.
//

#ifndef pngTools_hpp
#define pngTools_hpp

#include <stdlib.h>
#include <stdio.h>
#include "png.h"

class PngParse
{
public:
    PngParse(const char *filename);
    ~PngParse();
    void write_png_file(const char *filename, const char * desc = nullptr);
    void random_add_color();
    static void gemARandomPicture(const char *file_name);
    png_bytep get_value(int x, int y);
    bool success;
    int width;
    int height;
    size_t pixbytes;
    png_byte color_type;
    png_byte bit_depth;
    png_byte filter_type;
    png_byte interlace_type;
    png_byte compression_type;
    png_bytep *row_pointers;
};

#endif /* pngTools_hpp */
