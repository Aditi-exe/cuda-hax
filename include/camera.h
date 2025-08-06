#pragma once

#include "vec3.h"
#include "ray.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifdef __CUDACC__
#define CUDA_HOSTDEV __host__ __device__
#else
#define CUDA_HOSTDEV
#endif

class Camera {
public:
    Point3 origin;
    Point3 lower_left_corner;
    Vec3 horizontal;
    Vec3 vertical;
    Vec3 forward, right, up;
    float fov = 45.0f;
    float aspect_ratio;


    CUDA_HOSTDEV
    Camera(Point3 lookFrom, Point3 lookAt, Vec3 upVec, float vfov, float aspect)
    {
        aspect_ratio = aspect;
        float theta = vfov * M_PI / 180.0f;
        float h = tanf(theta / 2.0f);
        float viewport_height = 2.0f * h;
        float viewport_width = aspect * viewport_height;

        forward = (lookAt - lookFrom).normalized();
        right = forward.cross(upVec).normalized();
        up = right.cross(forward);

        origin = lookFrom;
        horizontal = viewport_width * right;
        vertical = viewport_height * up;
        lower_left_corner = origin - horizontal / 2.0f - vertical / 2.0f + forward;
    }



    /*
    // Constructor — sets up a fixed camera at (0, 0, 0) looking in -Z direction
    CUDA_HOSTDEV
    Camera(float aspect_ratio) {
        float viewport_height = 2.0f;
        float viewport_width = aspect_ratio * viewport_height;
        float focal_length = 1.0f;

        origin = Point3(0.0f, 0.0f, 0.0f);
        horizontal = Vec3(viewport_width, 0.0f, 0.0f);
        vertical = Vec3(0.0f, viewport_height, 0.0f);
        lower_left_corner = origin 
                            - horizontal / 2.0f 
                            - vertical / 2.0f 
                            - Vec3(0.0f, 0.0f, focal_length);
    }
    */

    // Returns a ray from the camera through image-space coordinates (u, v)
    CUDA_HOSTDEV
    Ray get_ray(float u, float v) const {
        return Ray(
            origin,
            lower_left_corner + u * horizontal + v * vertical - origin
        );
    }
};
