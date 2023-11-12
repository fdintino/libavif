FetchContent_Declare(
    libjpeg
    GIT_REPOSITORY "https://github.com/joedrago/libjpeg.git"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/libjpeg" BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/libjpeg"
    GIT_SHALLOW ON
    UPDATE_COMMAND ""
)
avif_fetchcontent_populate_cmake(libjpeg)

set_property(TARGET jpeg PROPERTY AVIF_LOCAL ON)
set(JPEG_INCLUDE_DIR "${AVIF_SOURCE_DIR}/ext/libjpeg")
target_include_directories(jpeg INTERFACE ${JPEG_INCLUDE_DIR})

add_library(JPEG::JPEG ALIAS jpeg)
set(JPEG_LIBRARY JPEG::JPEG)
