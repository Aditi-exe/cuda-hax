#pragma once

#include <cstdint>
#include "../include/camera.h"

// Called by main.cpp — launches the CUDA render
void launch_render(
    uint8_t *framebuffer, 
    int width, 
    int height, 
    const Camera& cam
);
