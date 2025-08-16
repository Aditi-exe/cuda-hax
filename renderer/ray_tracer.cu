#include "ray_tracer.cuh"
#include "../include/camera.h"
#include "../include/vec3.h"
#include "../include/ray.h"
#include "../include/sphere.h"
#include <cfloat>

#define PI 3.1415926535f


// Sample texture color at UV
__device__ Vec3 sampleTexture(unsigned char* d_imagedata, int imagewidth, int imageheight, float u, float v) {
    // clamping u, v to [0, 1)
    u = u - floorf(u);
    v = v - floorf(v);
    int i = min(int(u * imagewidth), imagewidth - 1);
    int j = min(int(v * imageheight), imageheight - 1);

    int idx = (j * imagewidth + i) * 3;
    float r = d_imagedata[idx] / 255.0f;
    float g = d_imagedata[idx + 1] / 255.0f;
    float b = d_imagedata[idx + 2] / 255.0f;

    return Vec3(r, g, b);
}

__device__ Vec3 ray_color(const Ray &r, unsigned char* d_imagedata_sun, int imagewidth_sun, int imageheight_sun,
                                        unsigned char* d_imagedata_earth, int imagewidth_earth, int imageheight_earth)
{
    // Build materials
    Material sunMat;
    sunMat.albedo = Vec3(1.0f, 1.0f, 1.0f);
    sunMat.useTexture = true;
    sunMat.textureID = 0;
    sunMat.emission = Vec3(1.0f, 1.0f, 0.9f);    // warm yellowish emission tint
    sunMat.emissionStrength = 8.0f;              // tune this to change brightness

    Material earthMat;
    earthMat.albedo = Vec3(1.0f, 1.0f, 1.0f);
    earthMat.useTexture = true;
    earthMat.textureID = 1;
    earthMat.emission = Vec3(0.0f, 0.0f, 0.0f);
    earthMat.emissionStrength = 0.0f;


    Sphere sunSphere(Point3(-1.5f, 0.0f, -3.0f), 0.8f, sunMat); // Sun sphere
    Sphere earthSphere(Point3(1.5f, 0.0f, -4.0f), 0.2f, earthMat);  // Earth sphere


    Material haloMat;
    haloMat.emission = Vec3(1.0f, 0.9f, 0.6f);
    haloMat.emissionStrength = 0.4f;

    Sphere sunHaloSphere(
        sunSphere.center,
        sunSphere.radius * 1.01f,
        haloMat
    );


    // Try hitting both spheres using the new hit that fills SphereHitRecord
    SphereHitRecord recSun, recEarth, recHalo;
    bool hitSun = sunSphere.hit(r, 0.001f, FLT_MAX, recSun);
    bool hitEarth = earthSphere.hit(r, 0.001f, FLT_MAX, recEarth);

    // If ray hits the Sun directly: return emission (modulated by sun texture)
    if (hitSun && (!hitEarth || recSun.t < recEarth.t)) {
        // Use texture if available to modulate emission color
        Vec3 texColor(1.0f, 1.0f, 1.0f);
        if (recSun.material.useTexture && d_imagedata_sun) {
            texColor = sampleTexture(d_imagedata_sun, imagewidth_sun, imageheight_sun, recSun.u, recSun.v);
        }
        // final color = texture * emission * strength
        Vec3 emission = recSun.material.emission * recSun.material.emissionStrength;
        return texColor * emission;
    }

    // Halo check here
    if (sunHaloSphere.hit(r, 0.001f, FLT_MAX, recHalo)) {
        Vec3 halo = recHalo.material.emission * recHalo.material.emissionStrength;
        return halo; // or halo + ray_color(r, depth-1) if you want additive blending
    }


    // If ray hits Earth (or any other non-emissive object), compute shading from Sun
    if (hitEarth) {
        Vec3 hitP = recEarth.point;
        Vec3 N = recEarth.normal.normalized();

        // Direction from hit point toward Sun center
        Vec3 toSun = (sunSphere.center - hitP);
        float distToSun = toSun.length();
        Vec3 L = toSun / distToSun; // normalized

        // Shadow ray: check if Sun is visible from hit point
        Ray shadowRay(hitP + N * 1e-4f, L);
        SphereHitRecord tmpRec;
        bool sunVisible = false;

        // We only want to know if ray from hitP reaches the Sun surface before hitting anything else.
        // Since our scene only has Sun and Earth, we only test intersection with Sun.
        // limit t to slightly less than distToSun to avoid self-intersection with Sun center
        if (sunSphere.hit(shadowRay, 0.001f, distToSun - 1e-4f, tmpRec)) {
            // shadowRay intersects the Sun surface — Sun is visible
            sunVisible = true;
        }

        Vec3 finalColor(0.0f, 0.0f, 0.0f);

        if (sunVisible) {
            // Sun direction and Lambert term
            float NdotL = fmaxf(N.dot(L), 0.0f);

            // Simple white sunlight, scaled (you don’t want to sample the Sun’s texture here!)
            Vec3 sunLightColor(1.0f, 1.0f, 1.0f);

            // Distance attenuation (optional)
            float attenuation = 1.0f / (distToSun * distToSun);
            float distanceScale = 20.0f;
            attenuation *= distanceScale;

            finalColor = sunLightColor * NdotL * attenuation;
        }

        // Base Earth texture
        Vec3 baseColor(1.0f, 1.0f, 1.0f);
        if (recEarth.material.useTexture && d_imagedata_earth) {
            baseColor = sampleTexture(d_imagedata_earth, imagewidth_earth, imageheight_earth, recEarth.u, recEarth.v);


            // // Sample the sun texture at the point where the shadowRay hits the Sun (tmpRec.u,tmpRec.v)
            // Vec3 sunTex(1.0f, 1.0f, 1.0f);
            // if (tmpRec.material.useTexture && d_imagedata_sun) {
            //     sunTex = sampleTexture(d_imagedata_sun, imagewidth_sun, imageheight_sun, tmpRec.u, tmpRec.v);
            // }

            // // Emitted radiance from the Sun surface (texture modulates emission color)
            // Vec3 sunEmission = tmpRec.material.emission * tmpRec.material.emissionStrength;
            // Vec3 radiance = sunTex * sunEmission;

            // // Simple Lambertian term (area-light integration is approximated)
            // float NdotL = fmaxf(N.dot(L), 0.0f);

            // // Attenuation with distance (optional). Sun is far but we include inverse-square falloff.
            // // For artistic control you can comment out / change the attenuation.
            // float attenuation = 1.0f / (distToSun * distToSun); // small scenes may need scaling
            // // We'll scale attenuation down to avoid too dark result; multiply by a constant to compensate:
            // float distanceScale = 4.0f; // tweak this value based on scene scale
            // attenuation *= distanceScale;

            // finalColor = radiance * NdotL * attenuation;
        } 
        // else {
        //     // Sun blocked: no direct light -> 0 (you can add ambient if desired)
        //     finalColor = Vec3(0.0f, 0.0f, 0.0f);
        // }

        // // If Earth uses its own texture for base albedo, multiply
        // Vec3 baseColor(1.0f, 1.0f, 1.0f);
        // if (recEarth.material.useTexture && d_imagedata_earth) {
        //     baseColor = sampleTexture(d_imagedata_earth, imagewidth_earth, imageheight_earth, recEarth.u, recEarth.v);
        // }

        return baseColor * finalColor;
    }

    // Miss: sky gradient
    //Vec3 unit_direction = r.direction().normalized();
    //float s = 0.5f * (unit_direction.y + 1.0f);
    //return (0.8f - s) * Vec3(1.0f, 1.0f, 1.0f) + s * Vec3(0.0f, 0.0f, 0.0f);
    return Vec3(0.0f, 0.0f, 0.0f); // black sky
}

    // float t1_hit, t2_hit;
    // bool hit1 = sphere1.hit(r, 0.001f, FLT_MAX, t1_hit);
    // bool hit2 = sphere2.hit(r, 0.001f, FLT_MAX, t2_hit);

    // Vec3 light_dir = Vec3(1, 1, 1).normalized();  // Directional light

    // if (hit1 && (!hit2 || t1_hit < t2_hit)) {
    //     Point3 p = r.at(t1_hit);
    //     Vec3 normal = (p - sphere1.center).normalized();
    //     float diff = fmaxf(normal.dot(light_dir), 0.0f);

    //     // spherical coordinates for sun texture mapping
    //     float u = 0.5f + atan2f(normal.z, normal.x) / (2.0f * PI);
    //     float v = 0.5f - asinf(normal.y) / PI;

    //     Vec3 sun_texture = sampleTexture(d_imagedata_sun, imagewidth_sun, imageheight_sun, u, v);
    //     //Vec3 texture_color = Vec3(0.1f, 0.1f, 0.1f);
    //     return diff * sun_texture;
    // }
    // else if (hit2) {
    //     Point3 p = r.at(t2_hit);
    //     Vec3 normal = (p - sphere2.center).normalized();
    //     float diff = fmaxf(normal.dot(light_dir), 0.0f);

    //     // spherical coordinates for earth texture mapping
    //     float u = 0.5f + atan2f(normal.z, normal.x) / (2.0f * PI);
    //     float v = 0.5f - asinf(normal.y) / PI;

    //    // Vec3 base_color = Vec3(0.2f, 0.2f, 1.0f);  // Light blue
    //    Vec3 earth_texture = sampleTexture(d_imagedata_earth, imagewidth_earth, imageheight_earth, u, v);
    //    return diff * earth_texture;
    // }

    // Vec3 unit_direction = r.direction().normalized(); // Use safe normalized() method
    // float s = 0.5f * (unit_direction.y + 1.0f);
    // return (0.8f - s) * Vec3(1.0f, 1.0f, 1.0f) + s * Vec3(0.0f, 0.0f, 0.0f); // Sky gradient
    // //return s * Vec3(0.0f, 0.0f, 0.0f); // Sky gradient

// }

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
