// #include "external/glew/include/GL/glew.h"
// #include "external/glfw/include/GLFW/glfw3.h"

// #include <cuda_gl_interop.h>
// #include <cuda_runtime.h>

// #include "include/camera.h"
// #include "renderer/ray_tracer.cuh"

// #include <iostream>

// const GLFWvidmode* mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
// int screenwidth = mode->width;
// int screenheight = mode->height;

// GLuint pbo = 0;
// struct cudaGraphicsResource *cuda_pbo_resource = nullptr;

// int current_width = screenwidth;
// int current_height = screenheight;

// // Forward declarations
// void createPBO(int width, int height);
// void cleanupPBO();
// void reshape(int width, int height);

// void createPBO(int width, int height)
// {
//     if (pbo)
//     {
//         cudaGraphicsUnregisterResource(cuda_pbo_resource);
//         glDeleteBuffers(1, &pbo);
//     }

//     glGenBuffers(1, &pbo);
//     glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
//     glBufferData(GL_PIXEL_UNPACK_BUFFER, width * height * 4, nullptr, GL_DYNAMIC_DRAW);
//     glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);

//     cudaGraphicsGLRegisterBuffer(&cuda_pbo_resource, pbo, cudaGraphicsMapFlagsWriteDiscard);
// }

// void render()
// {
//     uint8_t *dev_ptr = nullptr;
//     size_t size;

//     cudaGraphicsMapResources(1, &cuda_pbo_resource, 0);
//     cudaGraphicsResourceGetMappedPointer((void **)&dev_ptr, &size, cuda_pbo_resource);

//     launch_render(dev_ptr, current_width, current_height);

//     cudaGraphicsUnmapResources(1, &cuda_pbo_resource, 0);
// }

// void drawTexture()
// {
//     glClear(GL_COLOR_BUFFER_BIT);
//     glDrawPixels(current_width, current_height, GL_RGBA, GL_UNSIGNED_BYTE, 0);
// }

// // Resize callback
// void framebuffer_size_callback(GLFWwindow *window, int width, int height)
// {
//     current_width = width;
//     current_height = height;

//     glViewport(0, 0, width, height);
//     createPBO(width, height);
// }

// int main()
// {
//     if (!glfwInit())
//     {
//         std::cerr << "GLFW init failed\n";
//         return -1;
//     }

//     GLFWwindow *window = glfwCreateWindow(screenwidth, screenheight, "GPU-RTX", glfwGetPrimaryMonitor(), nullptr);
//     if (!window)
//     {
//         std::cerr << "Window creation failed\n";
//         glfwTerminate();
//         return -1;
//     }

//     glfwMakeContextCurrent(window);
//     glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

//     glewInit();

//     createPBO(current_width, current_height);
//     glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);

//     while (!glfwWindowShouldClose(window))
//     {
//         render();
//         drawTexture();
//         glfwSwapBuffers(window);
//         glfwPollEvents();
//     }

//     cudaGraphicsUnregisterResource(cuda_pbo_resource);
//     glDeleteBuffers(1, &pbo);
//     glfwTerminate();
//     return 0;
// }













// #include "external/glew/include/GL/glew.h"
// #include "external/glfw/include/GLFW/glfw3.h"

// #include <cuda_gl_interop.h>
// #include <cuda_runtime.h>

// #include "include/camera.h"
// #include "renderer/ray_tracer.cuh"

// #include <iostream>


// int screenwidth = 800;
// int screenheight = 600;


// int WIDTH;
// int HEIGHT;

// GLuint pbo = 0;
// struct cudaGraphicsResource *cuda_pbo_resource;

// // [NEW] Camera globals
// Vec3 cam_position(0.0f, 0.0f, 1.0f);
// Vec3 cam_direction(0.0f, 0.0f, -1.0f);
// Vec3 cam_up(0.0f, 1.0f, 0.0f);
// float yaw = -90.0f;
// float pitch = 0.0f;
// float speed = 0.1f;
// float lastX, lastY;
// bool firstMouse = true;

// Camera cam;

// void createPBO()
// {
//     glGenBuffers(1, &pbo);
//     glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
//     glBufferData(GL_PIXEL_UNPACK_BUFFER, WIDTH * HEIGHT * 4, nullptr, GL_DYNAMIC_DRAW);
//     glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);

//     cudaGraphicsGLRegisterBuffer(&cuda_pbo_resource, pbo, cudaGraphicsMapFlagsWriteDiscard);
// }

// // [NEW] Keyboard movement
// void processInput(GLFWwindow *window)
// {
//     Vec3 forward = cam_direction.normalized();
//     Vec3 right = forward.cross(cam_up).normalized();

//     if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
//         cam_position += speed * forward;
//     if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
//         cam_position -= speed * forward;
//     if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
//         cam_position -= speed * right;
//     if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
//         cam_position += speed * right;
// }

// // [NEW] Mouse callback
// void mouse_callback(GLFWwindow* window, double xpos, double ypos)
// {
//     if (firstMouse)
//     {
//         lastX = xpos;
//         lastY = ypos;
//         firstMouse = false;
//     }

//     float xoffset = xpos - lastX;
//     float yoffset = lastY - ypos;
//     lastX = xpos;
//     lastY = ypos;

//     float sensitivity = 0.1f;
//     xoffset *= sensitivity;
//     yoffset *= sensitivity;

//     yaw += xoffset;
//     pitch += yoffset;

//     if (pitch > 89.0f) pitch = 89.0f;
//     if (pitch < -89.0f) pitch = -89.0f;

//     float radYaw = yaw * M_PI / 180.0f;
//     float radPitch = pitch * M_PI / 180.0f;

//     cam_direction.x = cos(radYaw) * cos(radPitch);
//     cam_direction.y = sin(radPitch);
//     cam_direction.z = sin(radYaw) * cos(radPitch);
//     cam_direction = cam_direction.normalized();
// }

// void render()
// {
//     uint8_t *dev_ptr = nullptr;
//     size_t size;

//     cudaGraphicsMapResources(1, &cuda_pbo_resource, 0);
//     cudaGraphicsResourceGetMappedPointer((void **)&dev_ptr, &size, cuda_pbo_resource);

//     launch_render(dev_ptr, WIDTH, HEIGHT, cam);

//     cudaGraphicsUnmapResources(1, &cuda_pbo_resource, 0);
// }

// void drawTexture()
// {
//     glClear(GL_COLOR_BUFFER_BIT);
//     glDrawPixels(WIDTH, HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, 0);
// }

// int main()
// {
//     if (!glfwInit())
//     {
//         std::cerr << "GLFW init failed\n";
//         return -1;
//     }

//     const GLFWvidmode* mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
//     int screenwidth = mode->width;
//     int screenheight = mode->height;

//     WIDTH = screenwidth;
//     HEIGHT = screenheight;

//     float aspect_ratio = static_cast<float>(WIDTH) / static_cast<float>(HEIGHT);

//     GLFWwindow *window = glfwCreateWindow(WIDTH, HEIGHT, "GPU-RTX", nullptr, nullptr);
//     if (!window)
//     {
//         std::cerr << "Window creation failed\n";
//         glfwTerminate();
//         return -1;
//     }

//     glfwMakeContextCurrent(window);
//     glewInit();

//     createPBO();
//     glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);

//     while (!glfwWindowShouldClose(window))
//     {
//         render();
//         drawTexture();
//         glfwSwapBuffers(window);
//         glfwPollEvents();
//     }

//     cudaGraphicsUnregisterResource(cuda_pbo_resource);
//     glDeleteBuffers(1, &pbo);
//     glfwTerminate();
//     return 0;
// }
























#include "external/glew/include/GL/glew.h"
#include "external/glfw/include/GLFW/glfw3.h"

#include <cuda_gl_interop.h>
#include <cuda_runtime.h>

#include "include/camera.h"
#include "renderer/ray_tracer.cuh"

#include <iostream>
#include <cmath>

#include <cmath>

#define STB_IMAGE_IMPLEMENTATION
#include "../external/stb-master/stb_image.h"

#define DEG2RAD (M_PI / 180.0f)

int screenwidth = 800;
int screenheight = 600;

int WIDTH;
int HEIGHT;

int imagewidth, imageheight, channels;
unsigned char* imagedata = stbi_load("earth.jpg", &imagewidth, &imageheight, &channels, 3);

GLuint pbo = 0;
struct cudaGraphicsResource *cuda_pbo_resource;


// === Camera Globals ===
Vec3 cam_position(0.0f, 0.0f, 1.0f);
Vec3 cam_direction(0.0f, 0.0f, -1.0f);
Vec3 cam_up(0.0f, 1.0f, 0.0f);
float yaw = -90.0f;
float pitch = 0.0f;
float speed = 0.05f;
float lastX, lastY;
bool firstMouse = true;


Camera cam(
    Point3(0.0f, 0.0f, 3.0f),
    Point3(0.0f, 0.0f, 0.0f),
    Vec3(0.0f, 1.0f, 0.0f),
    90.0f,
    4.0f / 3.0f  // Dummy aspect ratio
);


void createPBO()
{
    glGenBuffers(1, &pbo);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
    glBufferData(GL_PIXEL_UNPACK_BUFFER, WIDTH * HEIGHT * 4, nullptr, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);

    cudaGraphicsGLRegisterBuffer(&cuda_pbo_resource, pbo, cudaGraphicsMapFlagsWriteDiscard);
}


void getGPUMemoryUsage(size_t& free_mem, size_t& total_mem)
{
    cudaMemGetInfo(&free_mem, &total_mem);
}


// === Keyboard Input ===
void processInput(GLFWwindow *window)
{
    Vec3 forward = cam_direction.normalized();
    Vec3 right = forward.cross(cam_up).normalized();

    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        cam_position += speed * forward;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        cam_position -= speed * forward;
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        cam_position -= speed * right;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        cam_position += speed * right;

    // 👇 Exit on Escape
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, 1);
}

// === Mouse Movement Callback ===
void mouse_callback(GLFWwindow* window, double xpos, double ypos)
{
    if (firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos;
    lastX = xpos;
    lastY = ypos;

    float sensitivity = 0.1f;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw += xoffset;
    pitch += yoffset;

    if (pitch > 89.0f) pitch = 89.0f;
    if (pitch < -89.0f) pitch = -89.0f;

    float radYaw = yaw * DEG2RAD;
    float radPitch = pitch * DEG2RAD;

    cam_direction.x = cos(radYaw) * cos(radPitch);
    cam_direction.y = sin(radPitch);
    cam_direction.z = sin(radYaw) * cos(radPitch);
    cam_direction = cam_direction.normalized();
}

// === Rendering Frame ===
void render()
{
    // Recalculate Camera
    float vfov = 90.0f;
    float aspect_ratio = static_cast<float>(WIDTH) / static_cast<float>(HEIGHT);
    Point3 lookFrom = cam_position;
    Point3 lookAt = cam_position + cam_direction;

    // Update camera with new position and orientation
    cam = Camera(lookFrom, lookAt, cam_up, 90.0f, aspect_ratio);

    uint8_t *dev_ptr = nullptr;
    size_t size;

    cudaGraphicsMapResources(1, &cuda_pbo_resource, 0);
    cudaGraphicsResourceGetMappedPointer((void **)&dev_ptr, &size, cuda_pbo_resource);

    launch_render(dev_ptr, WIDTH, HEIGHT, cam);

    cudaGraphicsUnmapResources(1, &cuda_pbo_resource, 0);

    std::cout << "Camera Position: "
          << cam_position.x << ", "
          << cam_position.y << ", "
          << cam_position.z << std::endl;
}

// === Drawing to Screen ===
void drawTexture()
{
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawPixels(WIDTH, HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, 0);
}


int main()
{
    std::cout << "Program started..." << std::endl;
    
    if (!glfwInit())
    {
        std::cerr << "GLFW init failed\n";
        return -1;
    }

    const GLFWvidmode* mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
    screenwidth = mode->width;
    screenheight = mode->height;

    WIDTH = screenwidth;
    HEIGHT = screenheight;

    float aspect_ratio = static_cast<float>(WIDTH) / static_cast<float>(HEIGHT);

    GLFWwindow *window = glfwCreateWindow(WIDTH, HEIGHT, "GPU-RTX", nullptr, nullptr);
    if (!window)
    {
        std::cerr << "Window creation failed\n";
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glewInit();

    Camera cam(
        Point3(0.0f, 0.0f, 3.0f),
        Point3(0.0f, 0.0f, 0.0f),
        Vec3(0.0f, 1.0f, 0.0f),
        90.0f,
        static_cast<float>(WIDTH) / HEIGHT
    );


    // Register mouse callback
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    createPBO();
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);


    while (!glfwWindowShouldClose(window))
    {
        processInput(window);
        render();
        drawTexture();
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // cudaGraphicsUnregisterResource(cuda_pbo_resource);
    // glDeleteBuffers(1, &pbo);
    // glfwTerminate();
    // return 0;

    if (cuda_pbo_resource)
        cudaGraphicsUnregisterResource(cuda_pbo_resource);

    glDeleteBuffers(1, &pbo);
    stbi_image_free(imagedata);
    glfwTerminate();
    return 0;
}



