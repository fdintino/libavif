set(AVIF_LOCAL_LIBARGPARSE_GIT_TAG ee74d1b53bd680748af14e737378de57e2a0a954)

FetchContent_Declare(
    libargparse
    GIT_REPOSITORY "https://github.com/kmurray/libargparse.git"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/libargparse" BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/libargparse"
    GIT_TAG ${AVIF_LOCAL_LIBARGPARSE_GIT_TAG}
    UPDATE_COMMAND ""
)
avif_fetchcontent_populate_cmake(libargparse)
