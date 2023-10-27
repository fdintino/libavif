if(NOT DEFINED AVIF_LOCAL_LIBYUV_REPO)
    set(AVIF_LOCAL_LIBYUV_REPO "https://chromium.googlesource.com/libyuv/libyuv")
endif()
if(NOT DEFINED AVIF_LOCAL_LIBYUV_TAG)
    set(AVIF_LOCAL_LIBYUV_TAG "464c51a0353c71f08fe45f683d6a97a638d47833")
endif()

set(LIBYUV_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/libyuv")
if(ANDROID_ABI)
    set(LIBYUV_BINARY_DIR "${LIBYUV_BINARY_DIR}/${ANDROID_ABI}")
endif()
FetchContent_Declare(
    libyuv
    GIT_REPOSITORY "${AVIF_LOCAL_LIBYUV_REPO}"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/libyuv" BINARY_DIR "${LIBYUV_BINARY_DIR}"
    GIT_TAG "${AVIF_LOCAL_LIBYUV_TAG}"
    UPDATE_COMMAND ""
)

avif_fetchcontent_populate_cmake(libyuv)

set_property(TARGET yuv PROPERTY POSITION_INDEPENDENT_CODE ON)
set_target_properties(yuv PROPERTIES AVIF_LOCAL ON FOLDER "ext/libyuv")

add_library(yuv::yuv ALIAS yuv)

set(LIBYUV_INCLUDE_DIR "${AVIF_SOURCE_DIR}/ext/libyuv/include")

target_include_directories(yuv INTERFACE ${LIBYUV_INCLUDE_DIR})

set(libyuv_FOUND ON)

set(LIBYUV_VERSION_H "${LIBYUV_INCLUDE_DIR}/libyuv/version.h")
if(EXISTS ${LIBYUV_VERSION_H})
    # message(STATUS "Reading: ${LIBYUV_VERSION_H}")
    file(READ ${LIBYUV_VERSION_H} LIBYUV_VERSION_H_CONTENTS)
    string(REGEX MATCH "#define LIBYUV_VERSION ([0-9]+)" _ ${LIBYUV_VERSION_H_CONTENTS})
    set(LIBYUV_VERSION ${CMAKE_MATCH_1})
    # message(STATUS "libyuv version detected: ${LIBYUV_VERSION}")
endif()
if(NOT LIBYUV_VERSION)
    message(STATUS "libyuv version detection failed.")
endif()
