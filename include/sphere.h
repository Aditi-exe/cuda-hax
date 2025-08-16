#pragma once

#include "cuda_utils.h"
#include "vec3.h"
#include "ray.h"
#include <cmath>

// Defining material
struct Material {
    Vec3 albedo;
    bool useTexture;
    int textureID;
    Vec3 emission;
    float emissionStrength;

    CUDA_HOSTDEV
    Material() :
        albedo(1.0f, 1.0f, 1.0f),
        useTexture(false),
        textureID(-1),
        emission(0.0f, 0.0f, 0.0f),
        emissionStrength(0.0f) {}
};

// Hit record for sphere intersection
struct SphereHitRecord {
    float t;
    Vec3 point;
    Vec3 normal;
    float u, v;
    Material material;
};

class Sphere {
public:
    Point3 center;
    float radius;
    Material material;

    CUDA_HOSTDEV
    Sphere() {
        center = Point3(0.0f, 0.0f, 0.0f);
        radius = 2.0f;
        material = Material();
    }
    CUDA_HOSTDEV
    Sphere(Point3 c, float r, const Material& m) {
        center = c;
        radius = r;
        material = m;
    }

    // UV mapping for a sphere (p is point on surface)
    CUDA_HOSTDEV
    static void getSphereUV(const Point3& p, float& u, float& v) {
        float theta = acosf(-p.y);
        float phi = atan2f(-p.z, p.x) + M_PI;
        u = phi / (2.0f * M_PI);
        v = theta / M_PI;
    }

    CUDA_HOSTDEV
    bool hit(const Ray& r, float t_min, float t_max, SphereHitRecord& rec) const {
        Vec3 oc = r.origin() - center;
        float a = r.direction().dot(r.direction());
        float b = 2.0f * oc.dot(r.direction());
        float half_b = oc.dot(r.direction());
        float c = oc.dot(oc) - radius * radius;
        float discriminant = b * b - 4 * a * c;

        if (discriminant > 0) {
            float root = sqrtf(discriminant);

            // check the smaller root
            float temp = (-half_b - root) / a;
            if (temp < t_max && temp > t_min) {
                rec.t = temp;
                rec.point = r.at(temp);
                rec.normal = (rec.point - center) / radius;

                // spherical UV mapping
                float phi = atan2f(rec.normal.z, rec.normal.x);
                float theta = acosf(rec.normal.y);
                rec.u = 1.0f - (phi + M_PI) / (2.0f * M_PI);
                rec.v = theta / M_PI;

                rec.material = material;
                return true;
            }

            // check the larger root
            temp = (-half_b + root) / a;
            if (temp < t_max && temp > t_min) {
                rec.t = temp;
                rec.point = r.at(temp);
                rec.normal = (rec.point - center) / radius;

                // spherical UV mapping
                float phi = atan2f(rec.normal.z, rec.normal.x);
                float theta = acosf(rec.normal.y);
                rec.u = 1.0f - (phi + M_PI) / (2.0f * M_PI);
                rec.v = theta / M_PI;

                rec.material = material;
                return true;


            // float root = sqrtf(discriminant);
            // float temp = (-b - root) / (2.0f * a);
            // if (temp < t_max && temp > t_min) {
            //     rec.t = temp;
            //     return true;
            // }
            // temp = (-b + root) / (2.0f * a);
            // if (temp < t_max && temp > t_min) {
            //     rec.t = temp;
            //     return true;
            // }
            }
            return false;
        }
    };
};
