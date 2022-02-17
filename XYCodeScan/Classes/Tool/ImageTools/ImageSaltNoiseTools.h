#ifndef ImageTools_hpp
#define ImageTools_hpp

#include <cstdlib>
#include <iostream>
#include "ImageToolsConstants.h"

class ImageSaltNoiseTools
{
public:
    static void solve(char * imgFile, float f, char * path);
};

#endif /* ImageTools_hpp */
