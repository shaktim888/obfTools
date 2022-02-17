//
//  pngTools.cpp
//  HYCodeScan
//
//  Created by admin on 2019/9/23.
//  Copyright © 2019 admin. All rights reserved.
//

#include "pngTools.hpp"
#include <memory.h>

PngParse::PngParse(const char *filename) {
    row_pointers = nullptr;
    success = false;
    FILE *fp = fopen(filename, "rb");
    if(!fp) {
        return;
    }
    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if(!png) {
        fclose(fp);
        return;
    }
    png_infop info = png_create_info_struct(png);
    if(!info) {
        fclose(fp);
        return;
    }
    if(setjmp(png_jmpbuf(png))) {
        fclose(fp);
        return;
    };
    png_init_io(png, fp);
    png_read_info(png, info);
    width      = png_get_image_width(png, info);
    height     = png_get_image_height(png, info);
    color_type = png_get_color_type(png, info);
    bit_depth  = png_get_bit_depth(png, info);
    filter_type = png_get_filter_type(png, info);
    interlace_type = png_get_interlace_type(png, info);
    compression_type = png_get_compression_type(png, info);

    if(bit_depth == 16)
        png_set_strip_16(png);
    
    if(color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_palette_to_rgb(png);
    
    if(color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
        png_set_expand_gray_1_2_4_to_8(png);
    
    if(png_get_valid(png, info, PNG_INFO_tRNS))
        png_set_tRNS_to_alpha(png);
    
    if(color_type == PNG_COLOR_TYPE_RGB ||
       color_type == PNG_COLOR_TYPE_GRAY ||
       color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_filler(png, 0xFF, PNG_FILLER_AFTER);
    
    if(color_type == PNG_COLOR_TYPE_GRAY ||
       color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
        png_set_gray_to_rgb(png);
    
    png_read_update_info(png, info);
    
    row_pointers = (png_bytep*)malloc(sizeof(png_bytep) * height);
    size_t rowbytes = png_get_rowbytes(png,info);
    pixbytes = rowbytes / width;
    for(int y = 0; y < height; y++) {
        row_pointers[y] = (png_byte*)malloc(rowbytes);
    }
    
    png_read_image(png, row_pointers);
    
    fclose(fp);
    success = true;
}

/* Write a png file */
void PngParse::write_png_file(const char *file_name, const char * desc)
{
    if(!success) {
        return;
    }
    FILE *fp;
    png_structp png_ptr;
    png_infop info_ptr;
    png_colorp palette;
    
    fp = fopen(file_name, "wb");
    if (fp == NULL)
        return;
  
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL) {
        fclose(fp);
        return;
    }
    
    info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr == NULL)
    {
        fclose(fp);
        png_destroy_write_struct(&png_ptr,  NULL);
        return;
    }
    if (setjmp(png_jmpbuf(png_ptr)))
    {
        fclose(fp);
        png_destroy_write_struct(&png_ptr, &info_ptr);
        return;
    }
    png_init_io(png_ptr, fp);
    png_set_IHDR(
                 png_ptr,
                 info_ptr,
                 width, height,
                 8,
                 PNG_COLOR_TYPE_RGBA,
                 PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_BASE,
                 PNG_FILTER_TYPE_BASE
                 );
    /* Set the palette if there is one.  REQUIRED for indexed-color images. */
//    palette = (png_colorp)png_malloc(png_ptr, PNG_MAX_PALETTE_LENGTH * (sizeof (png_color)));
//    png_set_PLTE(png_ptr, info_ptr, palette, PNG_MAX_PALETTE_LENGTH);
    if(desc)
    {
        png_text text_ptr[1];
        char key0[] = "Title";
        text_ptr[0].key = key0;
        text_ptr[0].text = (char*) desc;
        text_ptr[0].compression = PNG_TEXT_COMPRESSION_NONE;
        text_ptr[0].itxt_length = 0;
        text_ptr[0].lang = NULL;
        text_ptr[0].lang_key = NULL;
        
        png_set_text(png_ptr, info_ptr, text_ptr, 1);
    }

    png_write_info(png_ptr, info_ptr);
//    png_set_packing(png_ptr);
//    png_set_packswap(png_ptr);
    png_write_image(png_ptr, row_pointers);
    if (setjmp(png_jmpbuf(png_ptr)))
    {
        printf("save png file failed:%s\n", file_name);
    }

    png_write_end(png_ptr, NULL);
//    png_free(png_ptr, palette);
//    palette = NULL;
    png_destroy_write_struct(&png_ptr, &info_ptr);
    fclose(fp);
}

PngParse::~PngParse() {
    if(row_pointers) {
        for(int y = 0; y < height; y++) {
            free(row_pointers[y]);
        }
        free(row_pointers);
        row_pointers = nullptr;
    }
}

png_bytep PngParse::get_value(int x, int y) {
    png_bytep row = row_pointers[y];
    return &(row[x * pixbytes]);
}

void PngParse::gemARandomPicture(const char *file_name)
{
    int width = ((10 + arc4random() % 256) >> 1) << 1;
    int height = ((10 + arc4random() % 256) >> 1) << 1;
    FILE *fp;
    png_structp png_ptr;
    png_infop info_ptr;

    fp = fopen(file_name, "wb");
    if (fp == NULL)
      return;

    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL) {
      fclose(fp);
      return;
    }

    info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr == NULL)
    {
      fclose(fp);
      png_destroy_write_struct(&png_ptr,  NULL);
      return;
    }
    if (setjmp(png_jmpbuf(png_ptr)))
    {
      fclose(fp);
      png_destroy_write_struct(&png_ptr, &info_ptr);
      return;
    }
    png_init_io(png_ptr, fp);
    png_set_IHDR(
               png_ptr,
               info_ptr,
               width, height,
               8,
               PNG_COLOR_TYPE_RGBA,
               PNG_INTERLACE_NONE,
               PNG_COMPRESSION_TYPE_BASE,
               PNG_FILTER_TYPE_BASE
               );

    png_bytep * row_pointers = (png_bytep *) malloc(sizeof(png_bytep) * height);
    for(int j = 0; j < height; j++ ) {
        row_pointers[j] = (png_byte *) malloc(sizeof(png_byte) * 4 * width);
        if(arc4random() % 2 == 0) {
            memset(row_pointers[j], 1 + arc4random() % 255, sizeof(png_byte) * 4 * width);
        }
    }
    for(int i = 0; i < 1000 + arc4random() % 1000; i++) {
        int x = arc4random() % width;
        int y = arc4random() % height;
        png_bytep row = row_pointers[y];
        png_bytep p = &(row[x * 4]);
        p[0] = arc4random() % 256;
        p[1] = arc4random() % 256;
        p[2] = arc4random() % 256;
        p[3] = arc4random() % 256;
    }
    
    png_write_info(png_ptr, info_ptr);
    //    png_set_packing(png_ptr);
    //    png_set_packswap(png_ptr);
    png_write_image(png_ptr, row_pointers);
    if (setjmp(png_jmpbuf(png_ptr)))
    {
        printf("save png file failed:%s\n", file_name);
    }
    png_write_end(png_ptr, NULL);
//    png_free(png_ptr, palette);
//    palette = NULL;
    png_destroy_write_struct(&png_ptr, &info_ptr);
    
    for(int j = 0; j < height; j++ ) {
        free(row_pointers[j]);
    }
    free(row_pointers);
    
    fclose(fp);
}

void PngParse::random_add_color() {
    if(!success) {
        return ;
    }
    int x = arc4random() % width;
    int y = arc4random() % height;
    png_bytep p = get_value(x, y);
    int c = 0;
    if(pixbytes >= 3) {
        c = arc4random() % 3;
    } else {
        c = arc4random() % pixbytes;
    }
    if(p[c] == 255) {
        p[c] -= 1;
    } else {
        p[c] += 1;
    }
}

