#include "ray_tracer.cuh"
#include "../include/camera.h"
#include "../include/vec3.h"
#include "../include/ray.h"
#include "../include/sphere.h"

#define PI 3.1415926535f


__device__ Vec3 ray_color(const Ray &r)
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

        // spherical coordinates for texture mapping
        float u = 0.5f + atan2f(normal.z, normal.x) / (2.0f * PI);
        float v = 0.5f - asinf(normal.y) / PI;

        Vec3 base_color = Vec3(1.0f, 0.2f, 0.2f);  // Light red
        return diff * base_color;
    }
    else if (hit2) {
        Point3 p = r.at(t2_hit);
        Vec3 normal = (p - sphere2.center).normalized();

        float diff = fmaxf(normal.dot(light_dir), 0.0f);
        Vec3 base_color = Vec3(0.2f, 0.2f, 1.0f);  // Light blue
        return diff * base_color;
    }



    /*
    Sphere sphere(Point3(0.0f, 0.0f, -1.0f), 0.5f); // simple test sphere
    float t_hit;
    if (sphere.hit(r, 0.001f, FLT_MAX, t_hit)) {
        return Vec3(1.0, 0.0, 0.0);  // red if hit
    }
    */
    /*
    Sphere sphere(Point3(0.0f, 0.0f, -1.0f), 0.5f); // simple test sphere
    float t;
    if (sphere.hit(r, 0.001f, FLT_MAX, t))
    {
        Vec3 N = (r.at(t) - sphere.center).normalized(); // surface normal
        return 0.5f * Vec3(N.x + 1, N.y + 1, N.z + 1);  // map normal to [0,1]
    }
    */

    Vec3 unit_direction = r.direction().normalized(); // Use safe normalized() method
    float s = 0.5f * (unit_direction.y + 1.0f);
    // return (0.8f - s) * Vec3(1.0f, 1.0f, 1.0f) + s * Vec3(0.0f, 0.0f, 0.0f); // Sky gradient
    return s * Vec3(0.0f, 0.0f, 0.0f); // Sky gradient

}

__global__ void render_kernel(uint8_t *fb, int width, int height, Camera cam)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height)
        return;

    int pixel_index = (y * width + x) * 4; // RGBA

    float u = float(x) / float(width - 1);
    float v = float(y) / float(height - 1);

    Ray r = cam.get_ray(u, v);
    Vec3 col = ray_color(r);

    fb[pixel_index + 0] = static_cast<uint8_t>(255.99f * fminf(col.x, 1.0f));
    fb[pixel_index + 1] = static_cast<uint8_t>(255.99f * fminf(col.y, 1.0f));
    fb[pixel_index + 2] = static_cast<uint8_t>(255.99f * fminf(col.z, 1.0f));
    fb[pixel_index + 3] = 255; // Alpha channel
}

void launch_render(uint8_t *frameBuffer, int width, int height, const Camera& cam)
{
    dim3 threadsPerBlock(8, 8);
    dim3 numBlocks((width + 7) / 8, (height + 7) / 8);

    render_kernel<<<numBlocks, threadsPerBlock>>>(frameBuffer, width, height, cam);
    cudaDeviceSynchronize();
}



// __device__ Vec3 ray_color(const Ray &r)
// {
//     Sphere sphere1(Point3(-1.5f, 0.0f, -3.0f), 0.8f);
//     Sphere sphere2(Point3(1.5f, 0.0f, -4.0f), 0.2f);

//     float t1_hit, t2_hit;
//     bool hit1 = sphere1.hit(r, 0.001f, FLT_MAX, t1_hit);
//     bool hit2 = sphere2.hit(r, 0.001f, FLT_MAX, t2_hit);

//     Vec3 light_dir = Vec3(1, 1, 1).normalized();
//     Vec3 light_color = Vec3(1.0f, 1.0f, 1.0f);  // White light
//     float ambient = 0.1f;  // Ambient strength

//     if (hit1 && (!hit2 || t1_hit < t2_hit)) {
//         Point3 p = r.at(t1_hit);
//         Vec3 normal = (p - sphere1.center).normalized();
//         float diff = fmaxf(normal.dot(light_dir), 0.0f);

//         Vec3 base_color = Vec3(1.0f, 0.2f, 0.2f);  // Reddish
//         Vec3 color = (ambient + diff) * base_color * light_color;
//         return clamp(color, 0.0f, 1.0f);
//     }
//     else if (hit2) {
//         Point3 p = r.at(t2_hit);
//         Vec3 normal = (p - sphere2.center).normalized();
//         float diff = fmaxf(normal.dot(light_dir), 0.0f);

//         Vec3 base_color = Vec3(0.2f, 0.2f, 1.0f);  // Bluish
//         Vec3 color = (ambient + diff) * base_color * light_color;
//         return clamp(color, 0.0f, 1.0f);
//     }

//     // Background gradient
//     Vec3 unit_direction = r.direction().normalized();
//     float s = 0.5f * (unit_direction.y + 1.0f);
//     return (1.0f - s) * Vec3(1.0f, 1.0f, 1.0f) + s * Vec3(0.5f, 0.7f, 1.0f);
// }

// __global__ void render_kernel(uint8_t *fb, int width, int height, Camera cam)
// {
//     int x = blockIdx.x * blockDim.x + threadIdx.x;
//     int y = blockIdx.y * blockDim.y + threadIdx.y;

//     if (x >= width || y >= height)
//         return;

//     int pixel_index = (y * width + x) * 4; // RGBA

//     float u = float(x) / float(width - 1);
//     float v = float(y) / float(height - 1);

//     Ray r = cam.get_ray(u, v);
//     Vec3 col = ray_color(r);

//     fb[pixel_index + 0] = static_cast<uint8_t>(255.99f * fminf(col.x, 1.0f));
//     fb[pixel_index + 1] = static_cast<uint8_t>(255.99f * fminf(col.y, 1.0f));
//     fb[pixel_index + 2] = static_cast<uint8_t>(255.99f * fminf(col.z, 1.0f));
//     fb[pixel_index + 3] = 255; // Alpha channel
// }




// void launch_render(uint8_t *frameBuffer, int width, int height, const Camera& cam) {
//     dim3 threadsPerBlock(8, 8);
//     dim3 numBlocks((width + 7) / 8, (height + 7) / 8);

//     // Point3 lookFrom(0.0f, 0.0f, 1.0f);     // Camera position
//     // Point3 lookAt(0.0f, 0.0f, -1.0f);      // Look target
//     // Vec3 vup(0.0f, 1.0f, 0.0f);            // 'Up' direction
//     // float vfov = 90.0f;
//     // float aspect = float(width) / float(height);

//     // Camera cam(lookFrom, lookAt, vup, vfov, aspect);

//     render_kernel<<<numBlocks, threadsPerBlock>>>(frameBuffer, width, height, cam);
//     cudaDeviceSynchronize();
// }