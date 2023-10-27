set(BUILD_SHARED_LIBS_ORIG ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "-")
set(ZLIB_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/zlib")
if(ANDROID_ABI)
    set(ZLIB_BINARY_DIR "${ZLIB_BINARY_DIR}/${ANDROID_ABI}")
endif()
FetchContent_Declare(
    zlib
    GIT_REPOSITORY "https://github.com/madler/zlib.git"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/zlib" BINARY_DIR "${ZLIB_BINARY_DIR}"
    GIT_TAG "v1.3"
    GIT_SHALLOW ON
    UPDATE_COMMAND ""
)
# Put the value of ZLIB_INCLUDE_DIR in the cache. This works around cmake behavior that has been updated by
# cmake policy CMP0102 in cmake 3.17. Remove the CACHE workaround when we require cmake 3.17 or later. See
# https://gitlab.kitware.com/cmake/cmake/-/issues/21343.
set(ZLIB_INCLUDE_DIR "${AVIF_SOURCE_DIR}/ext/zlib" CACHE PATH "zlib include dir")
# This include_directories() call must be before add_subdirectory(ext/zlib) to work around the
# zlib/CMakeLists.txt bug fixed by https://github.com/madler/zlib/pull/818.
include_directories(SYSTEM ${ZLIB_INCLUDE_DIR})
if(NOT zlib_POPULATED)
    FetchContent_Populate(zlib)
    add_subdirectory(${zlib_SOURCE_DIR} ${zlib_BINARY_DIR} EXCLUDE_FROM_ALL)
    # Re-enable example and example64 targets, as these are used by tests
    set_property(TARGET example PROPERTY EXCLUDE_FROM_ALL FALSE)
    if(TARGET example64)
        set_property(TARGET example64 PROPERTY EXCLUDE_FROM_ALL FALSE)
    endif()
endif()

target_include_directories(zlibstatic INTERFACE ${ZLIB_INCLUDE_DIR})

# This include_directories() call and the previous include_directories() call provide the zlib
# include directories for add_subdirectory(ext/libpng). Because we set PNG_BUILD_ZLIB,
# libpng/CMakeLists.txt won't call find_package(ZLIB REQUIRED) and will see an empty
# ${ZLIB_INCLUDE_DIRS}.
include_directories("${ZLIB_BINARY_DIR}")
set(CMAKE_DEBUG_POSTFIX "")

set(ZLIB_LIBRARY zlibstatic)

# This is the only way I could avoid libpng going crazy if it found awk.exe, seems benign otherwise
set(PREV_ANDROID ${ANDROID})
set(ANDROID TRUE)
set(PNG_BUILD_ZLIB "${AVIF_SOURCE_DIR}/ext/zlib" CACHE STRING "" FORCE)
set(PNG_SHARED OFF CACHE BOOL "")
set(PNG_TESTS OFF CACHE BOOL "")
set(PNG_EXECUTABLES OFF CACHE BOOL "")

set(LIBPNG_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/libpng")
if(ANDROID_ABI)
    set(LIBPNG_BINARY_DIR "${LIBPNG_BINARY_DIR}/${ANDROID_ABI}")
endif()

FetchContent_Declare(
    libpng
    GIT_REPOSITORY "https://github.com/glennrp/libpng.git"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/libpng" BINARY_DIR "${LIBPNG_BINARY_DIR}"
    GIT_TAG "v1.6.40"
    GIT_SHALLOW ON
    UPDATE_COMMAND ""
)

if(NOT libpng_POPULATED)
    FetchContent_Populate(libpng)
    add_subdirectory(${libpng_SOURCE_DIR} ${libpng_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

set(PNG_PNG_INCLUDE_DIR "${AVIF_SOURCE_DIR}/ext/libpng")
set(PNG_LIBRARY png_static)
include_directories("${LIBPNG_BINARY_DIR}")
set(ANDROID ${PREV_ANDROID})

set_target_properties(png_static zlibstatic PROPERTIES AVIF_LOCAL ON)
# target_include_directories(png_static INTERFACE ${PNG_PNG_INCLUDE_DIR})

set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_ORIG} CACHE BOOL "-" FORCE)
