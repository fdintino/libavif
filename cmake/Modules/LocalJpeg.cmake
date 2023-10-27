set(BUILD_SHARED_LIBS_ORIG ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "-")
set(JPEG_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/libjpeg")
if(ANDROID_ABI)
    set(JPEG_BINARY_DIR "${JPEG_BINARY_DIR}/${ANDROID_ABI}")
endif()
FetchContent_Declare(
    libjpeg
    GIT_REPOSITORY "https://github.com/joedrago/libjpeg.git"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/libjpeg" BINARY_DIR "${JPEG_BINARY_DIR}"
    GIT_PROGRESS ON
    GIT_SHALLOW ON
    UPDATE_COMMAND ""
)

if(NOT libjpeg_POPULATED)
    FetchContent_Populate(libjpeg)
    add_subdirectory(${libjpeg_SOURCE_DIR} ${libjpeg_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()
set_property(TARGET jpeg PROPERTY AVIF_LOCAL ON)
add_library(JPEG::JPEG ALIAS jpeg)
set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_ORIG} CACHE BOOL "-" FORCE)
set(JPEG_INCLUDE_DIR "${AVIF_SOURCE_DIR}/ext/libjpeg")
target_include_directories(jpeg INTERFACE ${JPEG_INCLUDE_DIR})
set(JPEG_LIBRARY JPEG::JPEG)
