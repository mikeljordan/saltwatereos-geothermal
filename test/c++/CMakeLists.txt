# 0. CMake Minimum version
cmake_minimum_required(VERSION 3.3...3.12 FATAL_ERROR)

project(test_swEOS LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# set compiler flag
add_definitions("-Wno-array-bounds") # turn off this array bound check warning at this moment, this warning accurs at where dim!=3
add_definitions(-DUSE_OMP=1)

# 1. set path of SWEOS library
# set(SWEOS_DIR "${PROJECT_SOURCE_DIR}/../../Library" CACHE FILEPATH "Main path of SWEOS library")
set(SWEOS_DIR "${PROJECT_SOURCE_DIR}/../.." CACHE FILEPATH "Main path of SWEOS installation")
set(SWEOS_INCLUDE_DIR "${SWEOS_DIR}/Library/include")
set(SWEOS_LIB_DIR     "${SWEOS_DIR}/Library/lib")
if(EXISTS ${SWEOS_DIR})
#   message(STATUS "SWEOS head files found: ${SWEOS_DIR}/include")  
#   message(STATUS "SWEOS libraries found: ${SWEOS_DIR}/lib/libeosH2ONaCl.a")   
  message(STATUS "SWEOS head files found: ${SWEOS_INCLUDE_DIR}")  
  message(STATUS "SWEOS libraries found: ${SWEOS_LIB_DIR}/libeosH2ONaCl.a")  
else()
  message(FATAL_ERROR "Please specify path of SWEOS library which contains lib and include paths\n cmake -DSWEOS_DIR=path_of_SWEOS .. ")
endif()

# Manually set OpenMP flags for macOS Clang
if(APPLE)
    set(CMAKE_C_COMPILER clang)
    set(CMAKE_CXX_COMPILER clang++)

    # Try to find the latest libomp version from Homebrew
    # Use shell command to find the current libomp version
    execute_process(
        COMMAND brew --prefix libomp
        OUTPUT_VARIABLE LIBOMP_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(LIBOMP_PREFIX)
        message(STATUS "Found libomp at: ${LIBOMP_PREFIX}")
        set(OpenMP_CXX_FLAGS "-Xpreprocessor -fopenmp")
        set(OpenMP_EXE_LINKER_FLAGS "-lomp")
        
        # Add the include and library directories for OpenMP from libomp
        include_directories("${LIBOMP_PREFIX}/include")
        link_directories("${LIBOMP_PREFIX}/lib")
        
        # Set these variables for the message at the end
        set(LIBOMP_INCLUDE "${LIBOMP_PREFIX}/include")
        set(LIBOMP_LIB "${LIBOMP_PREFIX}/lib")
    else()
        # Fallback to searching common Homebrew locations
        message(STATUS "Trying to find libomp in common Homebrew locations...")
        
        # Look for libomp include directory
        file(GLOB LIBOMP_INCLUDE_PATHS
            /opt/homebrew/opt/libomp*/include
            /usr/local/opt/libomp*/include
        )
        
        # Look for libomp library directory
        file(GLOB LIBOMP_LIB_PATHS
            /opt/homebrew/opt/libomp*/lib
            /usr/local/opt/libomp*/lib
        )
        
        if(LIBOMP_INCLUDE_PATHS AND LIBOMP_LIB_PATHS)
            list(GET LIBOMP_INCLUDE_PATHS 0 LIBOMP_INCLUDE)
            list(GET LIBOMP_LIB_PATHS 0 LIBOMP_LIB)
            
            message(STATUS "Found libomp include: ${LIBOMP_INCLUDE}")
            message(STATUS "Found libomp lib: ${LIBOMP_LIB}")
            
            set(OpenMP_CXX_FLAGS "-Xpreprocessor -fopenmp")
            set(OpenMP_EXE_LINKER_FLAGS "-lomp")
            
            include_directories(${LIBOMP_INCLUDE})
            link_directories(${LIBOMP_LIB})
        else()
            # Last resort: try to install libomp
            message(FATAL_ERROR "libomp not found. Please install it with: brew install libomp")
        endif()
    endif()
else()
    # Set OpenMP flags for other platforms
    find_package(OpenMP REQUIRED)
    if(OPENMP_FOUND)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
    endif()
endif()

# Set source files and libraries
aux_source_directory(. SRC_MAIN)
include_directories(${SWEOS_INCLUDE_DIR}/include)

# Check if LIBOMP_INCLUDE was set, and if so, add it
if(LIBOMP_INCLUDE)
    include_directories(${LIBOMP_INCLUDE})
    link_directories(${SWEOS_LIB_DIR} ${LIBOMP_LIB})
else()
    link_directories(${SWEOS_DIR}/lib /usr/local/lib)
endif()

# Add USE_OMP definition to enable OpenMP
add_definitions(-DUSE_OMP=1)

# List of example files
list(APPEND Examples main test_omp)
foreach(example IN LISTS Examples)
    message(STATUS "example ${example}")
    add_executable(${example} ${example}.cpp)
    # Manually link the correct library file
    # target_link_libraries(${example} PRIVATE ${SWEOS_DIR}/lib/libeosH2ONaCl.a omp)
    target_link_libraries(${example} PRIVATE ${SWEOS_LIB_DIR}/libeosH2ONaCl.a omp)
endforeach()

add_custom_target(run
    COMMAND main
)

# Additional configuration messages
message(STATUS "")
message(STATUS "SWEOS_DIR lib path: ${SWEOS_DIR}/lib")
if(LIBOMP_INCLUDE)
    message(STATUS "libomp include: ${LIBOMP_INCLUDE}")
    message(STATUS "libomp lib: ${LIBOMP_LIB}")
endif()
message(STATUS " * Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS " * C compiler: ${CMAKE_C_COMPILER}")
message(STATUS " * C++ compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS " * Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")