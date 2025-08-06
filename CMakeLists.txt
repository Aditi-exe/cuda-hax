cmake_minimum_required(VERSION 3.18)
project(GPU_RTX LANGUAGES C CXX CUDA)

# Use dynamic runtime to avoid LNK4098 conflicts (i.e., /MD or /MDd)
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
endif()


# Output dir
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# C++ and CUDA standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_SEPARABLE_COMPILATION ON)

# Include directories
include_directories(
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/renderer
    ${PROJECT_SOURCE_DIR}/external/glfw/include
    ${PROJECT_SOURCE_DIR}/external/glew/include
)

# Link directories (adjust for your structure)
link_directories(
    ${PROJECT_SOURCE_DIR}/external/glfw/lib-vc2022
    ${PROJECT_SOURCE_DIR}/external/glew/lib/Release/x64
)

# Source files
set(SOURCES
    main.cpp
    renderer/ray_tracer.cu
)

# Executable
add_executable(GPU-RTX ${SOURCES})

# Ensure .cpp is compiled as C++, not CUDA
set_source_files_properties(main.cpp PROPERTIES LANGUAGE CXX)

# Add static GLEW flag if needed
# add_definitions(-DGLEW_STATIC) # Uncomment only if using glew32s.lib

# Link libraries
target_link_libraries(GPU-RTX
    PRIVATE
    glfw3
    glew32
    OpenGL32
    cuda
)

# Include paths for NVCC (redundant safety)
target_include_directories(GPU-RTX PRIVATE ${PROJECT_SOURCE_DIR}/include)
