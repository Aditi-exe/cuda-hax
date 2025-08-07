#pragma message("Compiling vec3.h")

#ifndef VEC3_H
#define VEC3_H

#include <cmath>
#include <iostream>


class Vec3 {
public:
    float x, y, z;

    __host__ __device__ Vec3() : x(0), y(0), z(0) {}
    __host__ __device__ Vec3(float x, float y, float z) : x(x), y(y), z(z) {}

    // Accessors
    __host__ __device__ float length() const {
        return sqrtf(x * x + y * y + z * z);
    }

    __host__ __device__ float length_squared() const {
        return x * x + y * y + z * z;
    }

    __host__ __device__ Vec3 normalized() const {
        float len = length();
        return (len > 0) ? (*this) / len : Vec3(0, 0, 0);
    }

    __host__ __device__ void normalize_in_place() {
        float len = length();
        if (len > 0) {
            x /= len; y /= len; z /= len;
        }
    }

    // Operator overloads
    __host__ __device__ Vec3 operator-() const {
        return Vec3(-x, -y, -z);
    }

    __host__ __device__ Vec3& operator+=(const Vec3& v) {
        x += v.x; y += v.y; z += v.z;
        return *this;
    }

    __host__ __device__ Vec3& operator-=(const Vec3& v) {
        x -= v.x; y -= v.y; z -= v.z;
        return *this;
    }

    __host__ __device__ Vec3& operator*=(const float t) {
        x *= t; y *= t; z *= t;
        return *this;
    }

    __host__ __device__ Vec3& operator/=(const float t) {
        return *this *= 1.0f / t;
    }

    __host__ __device__ Vec3 operator/(float t) const {
        return Vec3(x / t, y / t, z / t);
    }

    __host__ __device__ Vec3 operator*(float t) const {
        return Vec3(x * t, y * t, z * t);
    }

    __host__ __device__ Vec3 operator+(const Vec3& v) const {
        return Vec3(x + v.x, y + v.y, z + v.z);
    }

    __host__ __device__ Vec3 operator-(const Vec3& v) const {
        return Vec3(x - v.x, y - v.y, z - v.z);
    }

    __host__ __device__ float dot(const Vec3& v) const {
        return x * v.x + y * v.y + z * v.z;
    }

    __host__ __device__ Vec3 cross(const Vec3& v) const {
        return Vec3(
            y * v.z - z * v.y,
            z * v.x - x * v.z,
            x * v.y - y * v.x
        );
    }

    __host__ __device__ Vec3 clamp(const Vec3& v, float min_val, float max_val) {
        return Vec3(
            fminf(fmaxf(v.x, min_val), max_val),
            fminf(fmaxf(v.y, min_val), max_val),
            fminf(fmaxf(v.z, min_val), max_val)
        );
    }
};

// Point3 is just a Vec3 but semantically treated as a position
using Point3 = Vec3;

// Scalar multiplication from the left
__host__ __device__ inline Vec3 operator*(float t, const Vec3& v) {
    return Vec3(t * v.x, t * v.y, t * v.z);
}

#endif // VEC3_H