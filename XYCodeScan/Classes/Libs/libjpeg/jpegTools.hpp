//
//  jpegTools.hpp
//  HYCodeScan
//
//  Created by admin on 2019/9/24.
//  Copyright © 2019 admin. All rights reserved.
//

#ifndef jpegTools_hpp
#define jpegTools_hpp

#include <stdio.h>
#include <jpeglib.h>
#include <stdlib.h>

class JpegParse
{
public:
    JpegParse(const char *filename );
    int write_jpeg_file(const char *filename );
    void random_add_color();
    static void genAPicture(const char *filename );
    int width;
    int height;
    int bytes_per_pixel;   /* or 1 for GRACYSCALE images */
    J_COLOR_SPACE color_space; /* or JCS_GRAYSCALE for grayscale images */
    unsigned char *raw_image;
    bool success;
};
#endif /* jpegTools_hpp */
