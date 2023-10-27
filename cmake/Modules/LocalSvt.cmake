set(AVIF_LOCAL_SVT_GIT_TAG "v1.7.0")

set(SVT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/SVT-AV1")
if(ANDROID_ABI)
    set(SVT_BINARY_DIR "${SVT_BINARY_DIR}/${ANDROID_ABI}")
endif()

# Workaround https://gitlab.kitware.com/cmake/cmake/-/issues/25042 by enabling ASM before ASM_NASM
if(NOT CMAKE_ASM_COMPILER)
    include(CheckLanguage)
    check_language(ASM)
    if(CMAKE_ASM_COMPILER)
        enable_language(ASM)
    endif()
endif()
if(NOT CMAKE_ASM_NASM_COMPILER)
    include(CheckLanguage)
    check_language(ASM_NASM)
    if(CMAKE_ASM_NASM_COMPILER)
        enable_language(ASM_NASM)
    endif()
endif()

FetchContent_Declare(
    svt
    GIT_REPOSITORY "https://gitlab.com/AOMediaCodec/SVT-AV1.git"
    SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/SVT-AV1" BINARY_DIR "${SVT_BINARY_DIR}"
    GIT_TAG "${AVIF_LOCAL_SVT_GIT_TAG}"
    UPDATE_COMMAND ""
    GIT_SHALLOW ON
)

set(BUILD_DEC OFF CACHE BOOL "")
set(BUILD_APPS OFF CACHE BOOL "")
set(NATIVE OFF CACHE BOOL "")

set(CMAKE_BUILD_TYPE_ORIG ${CMAKE_BUILD_TYPE})
set(CMAKE_BUILD_TYPE Release CACHE INTERNAL "")

avif_fetchcontent_populate_cmake(svt)

set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE_ORIG} CACHE STRING "" FORCE)

set(SVT_INCLUDE_DIR ${svt_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${SVT_INCLUDE_DIR}/svt-av1)

file(GLOB _svt_header_files ${svt_SOURCE_DIR}/Source/API/*.h)

set(_svt_header_byproducts)

foreach(_svt_header_file ${_svt_header_files})
    get_filename_component(_svt_header_name "${_svt_header_file}" NAME)
    set(_svt_header_output ${SVT_INCLUDE_DIR}/svt-av1/${_svt_header_name})
    add_custom_command(
        OUTPUT ${_svt_header_output}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${_svt_header_file} ${_svt_header_output}
        DEPENDS ${_svt_header_file}
        VERBATIM
    )
    list(APPEND _svt_header_byproducts ${_svt_header_output})
endforeach()

add_custom_target(_svt_install_headers DEPENDS ${_svt_header_byproducts})
add_dependencies(SvtAv1Enc _svt_install_headers)
set_target_properties(SvtAv1Enc PROPERTIES AVIF_LOCAL ON FOLDER "ext/SVT-AV1")

target_include_directories(SvtAv1Enc INTERFACE ${SVT_INCLUDE_DIR})
