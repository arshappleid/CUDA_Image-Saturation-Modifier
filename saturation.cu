#include <cuda.h>
#include <cuda_runtime_api.h>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <stdio.h>


__device__ void rgbToHsv(unsigned char r, unsigned char g, unsigned char b, float *h, float *s, float *v);
__device__ void hsvToRgb(float h, float s, float v, unsigned char *r, unsigned char *g, unsigned char *b);
__global__ void adjustSaturationKernel(unsigned char *image, float saturation, int width, int height, int channels);

void adjustSaturation(char *imageName, float saturationFactor){
	// This is the wrapper function to adjustSaturationKernel

	// Read the image using OpenCV
    cv::Mat img = cv::imread(imageName, cv::IMREAD_COLOR);
    if (img.empty()) {
		printf("Error: Image cannot be loaded.");
		return;
	}
	
	// Convert image to a flat array of unsigned chars for CUDA
	cv::Mat imgFlat = img.reshape(1, img.total() * img.channels());
    unsigned char *image;
    
    // Allocate unified memory accessible by both host and device
    size_t imageSize = img.total() * img.channels();
    cudaMallocManaged(&image, imageSize);

    // Copy the image data into the managed memory
    memcpy(image, imgFlat.ptr(), imageSize);

    // Define the block and grid sizes
    dim3 blockSize(16, 16); // You can tune these values
    dim3 gridSize((img.cols + blockSize.x - 1) / blockSize.x, (img.rows + blockSize.y - 1) / blockSize.y);


    adjustSaturationKernel<<<gridSize, blockSize>>>(image, saturationFactor, img.cols, img.rows, img.channels());

    cudaDeviceSynchronize();

    cv::Mat resultImg = cv::Mat(img.size(), img.type(), image).clone();
    std::string modifiedImageName = "modified_" + std::string(imageName);
    cv::imwrite(modifiedImageName, resultImg);
    cudaFree(image);
}

__global__ void adjustSaturationKernel(unsigned char *image, float saturation, int width, int height, int channels) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x < width && y < height) {
        int idx = (y * width + x) * channels;
        
        // Read the pixel
        unsigned char r = image[idx];
        unsigned char g = image[idx + 1];
        unsigned char b = image[idx + 2];
        
        // Convert to HSV
        float h, s, v;
        rgbToHsv(r, g, b, &h, &s, &v);
        
        // Adjust the saturation
        s *= saturation;
        
        // Convert back to RGB
        hsvToRgb(h, s, v, &r, &g, &b);
        
        // Write the pixel back
        image[idx] = r;
        image[idx + 1] = g;
        image[idx + 2] = b;
    }
}

__device__ void rgbToHsv(unsigned char r, unsigned char g, unsigned char b, float *h, float *s, float *v) {
    float red = r / 255.0f;
    float green = g / 255.0f;
    float blue = b / 255.0f;

    float cmax = fmaxf(red, fmaxf(green, blue));
    float cmin = fminf(red, fminf(green, blue));
    float delta = cmax - cmin;

    // Hue calculation
    if (delta == 0) {
        *h = 0;
    } else if (cmax == red) {
        *h = 60.0f * fmodf(((green - blue) / delta), 6.0f);
    } else if (cmax == green) {
        *h = 60.0f * (((blue - red) / delta) + 2.0f);
    } else {
        *h = 60.0f * (((red - green) / delta) + 4.0f);
    }

    // Saturation calculation
    *s = (cmax == 0) ? 0 : (delta / cmax);

    // Value calculation
    *v = cmax;
}

__device__ void hsvToRgb(float h, float s, float v, unsigned char *r, unsigned char *g, unsigned char *b) {
    float c = v * s;
    float x = c * (1 - fabsf(fmodf(h / 60.0f, 2) - 1));
    float m = v - c;
    float r_, g_, b_;

    if (h >= 0 && h < 60) {
        r_ = c, g_ = x, b_ = 0;
    } else if (h >= 60 && h < 120) {
        r_ = x, g_ = c, b_ = 0;
    } else if (h >= 120 && h < 180) {
        r_ = 0, g_ = c, b_ = x;
    } else if (h >= 180 && h < 240) {
        r_ = 0, g_ = x, b_ = c;
    } else if (h >= 240 && h < 300) {
        r_ = x, g_ = 0, b_ = c;
    } else {
        r_ = c, g_ = 0, b_ = x;
    }

    *r = (unsigned char)((r_ + m) * 255.0f);
    *g = (unsigned char)((g_ + m) * 255.0f);
    *b = (unsigned char)((b_ + m) * 255.0f);
}


