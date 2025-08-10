#include "ray_tracer.cuh"
#include "../include/camera.h"
#include "../include/vec3.h"
#include "../include/ray.h"
#include "../include/sphere.h"

#define PI 3.1415926535f


// __device__ unsigned char* d_imagedata;
// __device__ int imagewidth;
// __device__ int imageheight;

// Sample texture color at UV
__device__ Vec3 sampleTexture(unsigned char* d_imagedata, int imagewidth, int imageheight, float u, float v) {
    int i = min(int((1.0f - u) * imagewidth), imagewidth - 1); // flipped u to NOT flip texture by 180 degrees sideways
    int j = min(int(v * imageheight), imageheight - 1);  // flipped v to NOT flip texture by 180 degrees

    int idx = (j * imagewidth + i) * 3;
    float r = d_imagedata[idx] / 255.0f;
    float g = d_imagedata[idx + 1] / 255.0f;
    float b = d_imagedata[idx + 2] / 255.0f;

    return Vec3(r, g, b);
}

__device__ Vec3 ray_color(const Ray &r, unsigned char* d_imagedata_sun, int imagewidth_sun, int imageheight_sun,
                                        unsigned char* d_imagedata_earth, int imagewidth_earth, int imageheight_earth)
{
    Sphere sphere1(Point3(-1.5f, 0.0f, -3.0f), 0.8f);
    Sphere sphere2(Point3(1.5f, 0.0f, -4.0f), 0.2f);  // New sphere to the right

    float t1_hit, t2_hit;
    bool hit1 = sphere1.hit(r, 0.001f, FLT_MAX, t1_hit);
    bool hit2 = sphere2.hit(r, 0.001f, FLT_MAX, t2_hit);

    Vec3 light_dir = Vec3(1, 1, 1).normalized();  // Directional light

    if (hit1 && (!hit2 || t1_hit < t2_hit)) {
        Point3 p = r.at(t1_hit);
        Vec3 normal = (p - sphere1.center).normalized();
        float diff = fmaxf(normal.dot(light_dir), 0.0f);

        // spherical coordinates for sun texture mapping
        float u = 0.5f + atan2f(normal.z, normal.x) / (2.0f * PI);
        float v = 0.5f - asinf(normal.y) / PI;

        Vec3 sun_texture = sampleTexture(d_imagedata_sun, imagewidth_sun, imageheight_sun, u, v);
        //Vec3 texture_color = Vec3(0.1f, 0.1f, 0.1f);
        return diff * sun_texture;
    }
    else if (hit2) {
        Point3 p = r.at(t2_hit);
        Vec3 normal = (p - sphere2.center).normalized();
        float diff = fmaxf(normal.dot(light_dir), 0.0f);

        // spherical coordinates for earth texture mapping
        float u = 0.5f + atan2f(normal.z, normal.x) / (2.0f * PI);
        float v = 0.5f - asinf(normal.y) / PI;

       // Vec3 base_color = Vec3(0.2f, 0.2f, 1.0f);  // Light blue
       Vec3 earth_texture = sampleTexture(d_imagedata_earth, imagewidth_earth, imageheight_earth, u, v);
       return diff * earth_texture;
    }

    Vec3 unit_direction = r.direction().normalized(); // Use safe normalized() method
    float s = 0.5f * (unit_direction.y + 1.0f);
    return (0.8f - s) * Vec3(1.0f, 1.0f, 1.0f) + s * Vec3(0.0f, 0.0f, 0.0f); // Sky gradient
    //return s * Vec3(0.0f, 0.0f, 0.0f); // Sky gradient

}

__global__ void render_kernel(uint8_t *fb, int width, int height, Camera cam, unsigned char* d_imagedata_sun, int imagewidth_sun, int imageheight_sun,
                                                                              unsigned char* d_imagedata_earth, int imagewidth_earth, int imageheight_earth)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height)
        return;

    int pixel_index = (y * width + x) * 4; // RGBA

    float u = float(x) / float(width - 1);
    float v = float(y) / float(height - 1);

    Ray r = cam.get_ray(u, v);
    Vec3 col = ray_color(r, d_imagedata_sun, imagewidth_sun, imageheight_sun, d_imagedata_earth, imagewidth_earth, imageheight_earth);

    fb[pixel_index + 0] = static_cast<uint8_t>(255.99f * fminf(col.x, 1.0f));
    fb[pixel_index + 1] = static_cast<uint8_t>(255.99f * fminf(col.y, 1.0f));
    fb[pixel_index + 2] = static_cast<uint8_t>(255.99f * fminf(col.z, 1.0f));
    fb[pixel_index + 3] = 255; // Alpha channel
}

void launch_render(uint8_t *frameBuffer, int width, int height, const Camera& cam, unsigned char* d_imagedata_sun, int imagewidth_sun, int imageheight_sun,
                                                                                   unsigned char* d_imagedata_earth, int imagewidth_earth, int imageheight_earth)
{
    dim3 threadsPerBlock(8, 8);
    dim3 numBlocks((width + 7) / 8, (height + 7) / 8);

    render_kernel<<<numBlocks, threadsPerBlock>>>(frameBuffer, width, height, cam, d_imagedata_sun, imagewidth_sun, imageheight_sun, d_imagedata_earth, imagewidth_earth, imageheight_earth);

    // Add error checking
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::cerr << "CUDA kernel launch error: " << cudaGetErrorString(err) << std::endl;
    }
    
    cudaDeviceSynchronize();
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::cerr << "CUDA kernel execution error: " << cudaGetErrorString(err) << std::endl;
    }
}
