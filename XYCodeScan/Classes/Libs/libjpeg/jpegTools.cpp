//
//  jpegTools.cpp
//  HYCodeScan
//
//  Created by admin on 2019/9/24.
//  Copyright © 2019 admin. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "jpegTools.hpp"
#include "jpeglib.h"
#include <setjmp.h>
#include <memory.h>

struct my_error_mgr {
    struct jpeg_error_mgr pub;    /* "public" fields */
    
    jmp_buf setjmp_buffer;    /* for return to caller */
};

typedef struct my_error_mgr * my_error_ptr;

METHODDEF(void)
my_error_exit (j_common_ptr cinfo)
{
    /* cinfo->err really points to a my_error_mgr struct, so coerce pointer */
    my_error_ptr myerr = (my_error_ptr) cinfo->err;
    
    /* Always display the message. */
    /* We could postpone this until after returning, if we chose. */
    (*cinfo->err->output_message) (cinfo);
    
    /* Return control to the setjmp point */
    longjmp(myerr->setjmp_buffer, 1);
}

JpegParse::JpegParse(const char *filename) {
    success = false;
    struct jpeg_decompress_struct cinfo;
    FILE * infile;
    JSAMPARRAY buffer;
    int row_stride;
    if ((infile = fopen(filename, "rb")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        return;
    }
    struct my_error_mgr jerr;
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        return;
    }
    jpeg_create_decompress(&cinfo);
    jpeg_stdio_src(&cinfo, infile);
    (void) jpeg_read_header(&cinfo, TRUE);
    (void) jpeg_start_decompress(&cinfo);
    width = cinfo.output_width;
    height = cinfo.output_height;
    bytes_per_pixel = cinfo.output_components;
    color_space = cinfo.out_color_space;
    row_stride = cinfo.output_width * cinfo.output_components;
    raw_image = (unsigned char*)malloc(cinfo.output_height * row_stride );
    buffer = (*cinfo.mem->alloc_sarray)((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    unsigned long location = 0;
    while (cinfo.output_scanline < cinfo.output_height) {
        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
        for( int i=0; i < row_stride; i++)
            raw_image[location++] = buffer[0][i];
    }
    (void) jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    
    fclose(infile);
    success = true;
}

int JpegParse::write_jpeg_file(const char *filename) {
    if(!success) {
        return 0;
    }
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    
    JSAMPROW row_pointer[1];
    FILE *outfile = fopen( filename, "wb" );
    
    if ( !outfile )
    {
        printf("Error opening output jpeg file %s\n!", filename );
        return -1;
    }
    cinfo.err = jpeg_std_error( &jerr );
    jpeg_create_compress(&cinfo);
    jpeg_stdio_dest(&cinfo, outfile);
    
    cinfo.image_width = width;
    cinfo.image_height = height;
    cinfo.input_components = bytes_per_pixel;
    cinfo.in_color_space = color_space;
    
    jpeg_set_defaults( &cinfo );
    
    jpeg_start_compress( &cinfo, TRUE );
    
    while( cinfo.next_scanline < cinfo.image_height )
    {
        row_pointer[0] = &raw_image[ cinfo.next_scanline * cinfo.image_width *  cinfo.input_components];
        jpeg_write_scanlines( &cinfo, row_pointer, 1 );
    }
    
    jpeg_finish_compress( &cinfo );
    jpeg_destroy_compress( &cinfo );
    fclose( outfile );
    return 1;
}

void JpegParse::genAPicture(const char *filename )
{
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    
    int width = ((10 + arc4random() % 256) >> 1) << 1;
    int height = ((10 + arc4random() % 256) >> 1) << 1;
    
    JSAMPROW row_pointer[1];
    FILE *outfile = fopen( filename, "wb" );
    
    cinfo.err = jpeg_std_error( &jerr );
    jpeg_create_compress(&cinfo);
    jpeg_stdio_dest(&cinfo, outfile);
    int bytes_per_pixel = 3;
    cinfo.image_width = width;
    cinfo.image_height = height;
    cinfo.input_components = bytes_per_pixel;
    cinfo.in_color_space = JCS_RGB;
    
    jpeg_set_defaults( &cinfo );
    
    jpeg_start_compress( &cinfo, TRUE );
    unsigned char * raw_image = (unsigned char*)malloc(height * width * bytes_per_pixel );
    memset(raw_image, 1 + arc4random() % 255, height * width * bytes_per_pixel);
    
    for(int i = 0; i < 2000 ; i ++) {
        int p = arc4random() % (width * height * bytes_per_pixel);
        raw_image[p] = arc4random() % 256;
    }
    
    while( cinfo.next_scanline < cinfo.image_height )
    {
        row_pointer[0] = &raw_image[ cinfo.next_scanline * cinfo.image_width *  cinfo.input_components];
        jpeg_write_scanlines( &cinfo, row_pointer, 1 );
    }
    
    jpeg_finish_compress( &cinfo );
    jpeg_destroy_compress( &cinfo );
    free(raw_image);
    fclose( outfile );
}

void JpegParse::random_add_color() { 
    if(!success) {
        return;
    }
    for(int i = 0; i < 1000 ; i ++) {
        int p = arc4random() % (width * height * bytes_per_pixel);
        if(raw_image[p] + 1  > 255) {
            raw_image[p] -= 1;
        } else {
            raw_image[p] += 1;
        }
    }
}




