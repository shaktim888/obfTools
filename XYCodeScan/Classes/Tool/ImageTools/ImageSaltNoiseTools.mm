#include <cmath>
#include <limits>
#include <iostream>
#import "ImageSaltNoiseTools.h"
#import <AppKit/AppKit.h>
#import "UserConfig.h"
#import "mmd5.h"


#ifdef USE_OPENCV


#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace cv;
using namespace std;

class BaseSaltNoice
{
public:
    virtual void handle(Mat dstImage)
    {
    }
};

class NormalSaltNoice : public BaseSaltNoice
{
private:
    float n;
public:
    NormalSaltNoice(float n) : BaseSaltNoice()
    , n(n)
    {

    }

    virtual void handle(Mat dstImage)
    {
        int num = dstImage.rows * dstImage.cols * n * 0.5;
        for (int k = 0; k < num; k++)
        {
            //随机取值行列
            int i = rand() % dstImage.rows;
            int j = rand() % dstImage.cols;
            //图像通道判定
            if (dstImage.channels() == 1)
            {
                dstImage.at<uchar>(i, j) = 255;        //盐噪声
            }
            else
            {
                dstImage.at<Vec3b>(i, j)[0] = 255;
                dstImage.at<Vec3b>(i, j)[1] = 255;
                dstImage.at<Vec3b>(i, j)[2] = 255;
            }
        }
        for (int k = 0; k < num; k++)
        {
            //随机取值行列
            int i = rand() % dstImage.rows;
            int j = rand() % dstImage.cols;
            //图像通道判定
            if (dstImage.channels() == 1)
            {
                dstImage.at<uchar>(i, j) = 0;        //椒噪声
            }
            else
            {
                dstImage.at<Vec3b>(i, j)[0] = 0;
                dstImage.at<Vec3b>(i, j)[1] = 0;
                dstImage.at<Vec3b>(i, j)[2] = 0;
            }
        }
    }
};

class GaussianNoise : public BaseSaltNoice
{
private:
    //生成高斯噪声
    double generateGaussianNoise(double mu, double sigma)
    {
        //定义小值
        const double epsilon = numeric_limits<double>::min();
        static double z0, z1;
        static bool flag = false;
        flag = !flag;
        //flag为假构造高斯随机变量X
        if (!flag)
            return z1 * sigma + mu;
        double u1, u2;
        //构造随机变量
        do
        {
            u1 = rand() * (1.0 / RAND_MAX);
            u2 = rand() * (1.0 / RAND_MAX);
        } while (u1 <= epsilon);
        //flag为真构造高斯随机变量
        z0 = sqrt(-2.0*log(u1))*cos(2 * CV_PI*u2);
        z1 = sqrt(-2.0*log(u1))*sin(2 * CV_PI*u2);
        return z0*sigma + mu;
    }

public:
    GaussianNoise() : BaseSaltNoice()
    {

    }

    virtual void handle(Mat dstImage)
    {
        int channels = dstImage.channels();
        int rowsNumber = dstImage.rows;
        int colsNumber = dstImage.cols*channels;
        //判断图像的连续性
        if (dstImage.isContinuous())
        {
            colsNumber *= rowsNumber;
            rowsNumber = 1;
        }
        for (int i = 0; i < rowsNumber; i++)
        {
            for (int j = 0; j < colsNumber; j++)
            {
                //添加高斯噪声
                int val = dstImage.ptr<uchar>(i)[j] +
                generateGaussianNoise(2, 0.8) * 32;
                if (val < 0)
                    val = 0;
                if (val>255)
                    val = 255;
                dstImage.ptr<uchar>(i)[j] = (uchar)val;
            }
        }
    }
};



void ImageSaltNoiseTools::solve(char * file, float f, char * path)
{
    srand(time(0));
    Mat srcImage = imread(file);
    if (!srcImage.data)
    {
        std::cout << "读入图像有误！" << std::endl;
        return;
    }
//    std::cout <<getBuildInformation();
    imshow("1", srcImage);

    Mat dstImage = srcImage.clone();
    int type = 1;
//    int type = rand() % 2;
    BaseSaltNoice * tools;
    switch (type) {
        case 0:
            tools = new GaussianNoise();
            break;
        default:
            tools = new NormalSaltNoice(0.01);
            break;
    }
    tools->handle(dstImage);
    delete tools;
    imshow("2", dstImage);
    //存储图像
//    saveWithCVMat(dstImage, @"/Users/hqq/Desktop/timg2.png");
    imwrite("/Users/hqq/Desktop/timg2.jpg", dstImage);
}

#else
//------------------------------------------------------------------------


static float colorBlend(int R1, float Alpha1, int R2, float Alpha2)
{
    float R = R1 * Alpha1 + R2 * Alpha2 * (1-Alpha1);
    float Alpha = 1 - (1 - Alpha1) *(1-Alpha2);
    R = R / Alpha;
    return int(R);
}

void ImageSaltNoiseTools::solve(char * file, float f, char * path)
{
    Timer_start("noiseImage");
    NSImage * image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:file]];
    if(!image) return;

    int type = 0;
    switch ([UserConfig sharedInstance].imageMode) {
        case ImageSolveType::WhiteBlack:
            type = 1;
            break;
        case ImageSolveType::Mask:
            type = 2;
            break;
        case ImageSolveType::Mix:
            type = arc4random() % 2 == 0 ? 1 : 2;
            break;
        default:
            type = 1;
            break;
    }
    //    UIImage * image = [[UIImage alloc] initWithContentsOfFile:imgFile];
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    
    CGImageRef imageRef = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
    //    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);  //获取图片像素的宽
    size_t height = CGImageGetHeight(imageRef); //获取图片像素的高
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    bool shouldInterpolate = CGImageGetShouldInterpolate(imageRef);
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(imageRef);
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);
    
    if(type == 1) {
        int num = f * width * height;
        for(int i = 0; i < num; i++)
        {
            int u1 = arc4random() % height;
            int u2 = arc4random() % width;
            if(bitsPerPixel == 1 * bitsPerComponent)
            {
                buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + 0] = 255;
            }
            else{
                for(int color = 0; color < 3; color ++)
                {
                    buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + color] = 255;
                }
            }
        }
        
        for(int i = 0; i < num; i++)
        {
            int u1 = arc4random() % height;
            int u2 = arc4random() % width;
            if(bitsPerPixel == 1 * bitsPerComponent)
            {
                buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + 0] = 255;
            }
            else{
                for(int color = 0; color < 3; color ++)
                {
                    buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + color] = 0;
                }
            }
        }
    }
    else if(type == 2){
        float factor = 0.5;
        for(int u1 = 0; u1 < height; u1++)
        {
            for( int u2 = 0; u2 < width; u2++)
            {
                if(bitsPerPixel == 1)
                {
                    buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + 0] = 0;
                }
                else{
                    float alpha1 = 0.05;
                    float alpha2 = 1;
                    if(bitsPerPixel > 3 * bitsPerComponent)
                    {
                        alpha2 = buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + 3] / 255.0;
                    }
                    if(alpha2 != 0)
                    {
                        for(int color = 0; color < 3; color ++)
                        {
                            int orgC = buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + color];
                            int rdC = ::floor((arc4random()%256) * factor);
                            int tV = colorBlend(rdC, alpha1, orgC, alpha2);
                            tV = int(tV / alpha2) % 255;
                            buffer[u1 * width * bitsPerPixel / bitsPerComponent + u2 * bitsPerPixel / bitsPerComponent + color] = tV;
                        }
                    }
                }
            }
        }
    }
    
    CFDataRef effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
    CGDataProviderRef effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
    CGImageRef effectedCgImage = CGImageCreate(
                                               width, height,
                                               bitsPerComponent, bitsPerPixel, bytesPerRow,
                                               colorSpace, bitmapInfo, effectedDataProvider,
                                               NULL, shouldInterpolate, intent);
    CFRelease(effectedDataProvider);
    CFRelease(effectedData);
    CFRelease(data);
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:effectedCgImage];
    NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    [pngData writeToFile:[NSString stringWithUTF8String:path] atomically:YES];
    CGImageRelease(effectedCgImage);
    Timer_end("noiseImage");
    
}

#endif
