#pragma once

#include "vec3.h"

// A ray has an origin and a direction.
// It can compute a point along its path using: P(t) = origin + t * direction
class Ray {
public:
    Vec3 orig;
    Vec3 dir;

    __host__ __device__
    Ray() {}

    __host__ __device__
    Ray(const Vec3& origin, const Vec3& direction)
        : orig(origin), dir(direction) {}

    __host__ __device__
    Vec3 origin() const { return orig; }

    __host__ __device__
    Vec3 direction() const { return dir; }

    // Returns point along the ray at parameter t
    __host__ __device__
    Vec3 at(float t) const {
        return orig + dir * t;
    }
};
