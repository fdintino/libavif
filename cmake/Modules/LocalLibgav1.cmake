set(AVIF_LOCAL_LIBGAV1_GIT_TAG "v0.19.0")

set(LIBGAV1_THREADPOOL_USE_STD_MUTEX 1 CACHE INTERNAL "")
set(LIBGAV1_ENABLE_EXAMPLES OFF CACHE INTERNAL "")
set(LIBGAV1_ENABLE_TESTS OFF CACHE INTERNAL "")
set(LIBGAV1_MAX_BITDEPTH 12 CACHE INTERNAL "")

set(LIBGAV1_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/libgav1")
if(ANDROID_ABI)
    set(LIBGAV1_BINARY_DIR "${LIBGAV1_BINARY_DIR}/${ANDROID_ABI}")
endif()

FetchContent_Declare(
    libgav1
    GIT_REPOSITORY "https://chromium.googlesource.com/codecs/libgav1"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/libgav1" BINARY_DIR "${LIBGAV1_BINARY_DIR}"
    GIT_TAG "${AVIF_LOCAL_LIBGAV1_GIT_TAG}"
    GIT_SHALLOW ON
    UPDATE_COMMAND ""
)

avif_fetchcontent_populate_cmake(libgav1)

set_property(TARGET libgav1_static PROPERTY AVIF_LOCAL ON FOLDER "ext/libgav1")
add_library(libgav1::libgav1 ALIAS libgav1_static)
