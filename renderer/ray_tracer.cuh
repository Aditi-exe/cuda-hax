#pragma once

#include <cstdint>
#include "../include/camera.h"

// Called by main.cpp — launches the CUDA render
void launch_render(
    uint8_t *framebuffer, 
    int width, 
    int height, 
    const Camera& cam,
    unsigned char* d_imagedata_sun,
    int imagewidth_sun,
    int imageheight_sun,
    unsigned char* d_imagedata_earth,
    int imagewidth_earth,
    int imageheight_earth
);
