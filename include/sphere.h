#pragma once

#include "cuda_utils.h"
#include "vec3.h"
#include "ray.h"


class Sphere {
public:
    Point3 center;
    float radius;

    CUDA_HOSTDEV
    Sphere() {
        center = Point3(0.0f, 0.0f, 0.0f);
        radius = 2.0f;
    }
    CUDA_HOSTDEV
    Sphere(Point3 c, float r) {
        center = c;
        radius = r;
    }

    CUDA_HOSTDEV
    bool hit(const Ray& r, float t_min, float t_max, float& t_hit) const {
        Vec3 oc = r.origin() - center;
        float a = r.direction().dot(r.direction());
        float b = 2.0f * oc.dot(r.direction());
        float c = oc.dot(oc) - radius * radius;
        float discriminant = b * b - 4 * a * c;

        if (discriminant > 0) {
            float root = sqrtf(discriminant);
            float temp = (-b - root) / (2.0f * a);
            if (temp < t_max && temp > t_min) {
                t_hit = temp;
                return true;
            }
            temp = (-b + root) / (2.0f * a);
            if (temp < t_max && temp > t_min) {
                t_hit = temp;
                return true;
            }
        }
        return false;
    }
};