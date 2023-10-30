# - Try to find libyuv
# Once done this will define
#
#  LIBYUV_FOUND - system has libyuv
#  LIBYUV_INCLUDE_DIR - the libyuv include directory
#  LIBYUV_LIBRARIES - Link these to use libyuv
#
#=============================================================================
#  Copyright (c) 2020 Andreas Schneider <asn@cryptomilk.org>
#
#  Distributed under the OSI-approved BSD License (the "License");
#  see accompanying file Copyright.txt for details.
#
#  This software is distributed WITHOUT ANY WARRANTY; without even the
#  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the License for more information.
#=============================================================================
#
set(AVIF_LIBYUV_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ext/libyuv/build")

function(avif_build_local_libyuv)
    include(ExternalProject)

    set(AVIF_EXT_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}/ext/build")

    find_program(NINJA_EXECUTABLE NAMES ninja ninja-build REQUIRED)

    add_library(yuv STATIC IMPORTED GLOBAL)
    set(AVIF_LOCAL_LIBYUV_TAG "464c51a0353c71f08fe45f683d6a97a638d47833")
    set(LIBYUV_FOUND ON PARENT_SCOPE)

    set(EP_SOURCE_DIR "${PROJECT_SOURCE_DIR}/ext/libyuv")
    set(EP_BINARY_DIR "${EP_SOURCE_DIR}/build")

    if(ANDROID)
        list(APPEND CMAKE_PROGRAM_PATH "${ANDROID_TOOLCHAIN_ROOT}/bin")
        set(EP_BINARY_DIR "${EP_BINARY_DIR}/${ANDROID_ABI}")
        set(AVIF_EXT_INSTALL_PREFIX "${AVIF_EXT_INSTALL_PREFIX}/${ANDROID_ABI}")
    endif()

    file(MAKE_DIRECTORY ${AVIF_EXT_INSTALL_PREFIX}/include)

    ExternalProject_Add(
        libyuv
        GIT_REPOSITORY https://chromium.googlesource.com/libyuv/libyuv
        GIT_TAG ${AVIF_LOCAL_LIBYUV_TAG}
        SOURCE_DIR "${EP_SOURCE_DIR}"
        BINARY_DIR "${EP_BINARY_DIR}"
        UPDATE_COMMAND ""
        CMAKE_ARGS -DANDROID_ABI=${ANDROID_ABI}
                   -DBUILD_SHARED_LIBS=OFF
                   -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                   -DCMAKE_INSTALL_PREFIX=${AVIF_EXT_INSTALL_PREFIX}
                   -DCMAKE_MAKE_PROGRAM=${NINJA_EXECUTABLE}
                   -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
                   -DCMAKE_CROSSCOMPILING=${CMAKE_CROSSCOMPILING}
                   -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
                   -DCMAKE_FIND_LIBRARY_SUFFIXES=${CMAKE_FIND_LIBRARY_SUFFIXES}
                   -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib
                   -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
                   -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
                   -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
                   -DCMAKE_POSITION_INDEPENDENT_CODE=ON
                   -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        BUILD_COMMAND ${NINJA_EXECUTABLE} -C <BINARY_DIR>
        INSTALL_COMMAND ${NINJA_EXECUTABLE} -C <BINARY_DIR> install
        BUILD_BYPRODUCTS ${AVIF_EXT_INSTALL_PREFIX}/lib/${AVIF_LIBRARY_PREFIX}yuv${CMAKE_STATIC_LIBRARY_SUFFIX}
    )

    ExternalProject_Add_Step(
        libyuv mkdir_build
        COMMAND ${CMAKE_COMMAND} -E make_directory ${EP_BINARY_DIR}
        DEPENDEES download
        ALWAYS ON
    )

    set(LIBYUV_LIBRARY ${AVIF_EXT_INSTALL_PREFIX}/lib/${AVIF_LIBRARY_PREFIX}yuv${CMAKE_STATIC_LIBRARY_SUFFIX} PARENT_SCOPE)
    set(LIBYUV_INCLUDE_DIR ${AVIF_EXT_INSTALL_PREFIX}/include PARENT_SCOPE)

    set_target_properties(libyuv PROPERTIES FOLDER "ext/libyuv")
endfunction()

if(NOT TARGET libyuv::libyuv)
    if(AVIF_LOCAL_LIBYUV)
        avif_build_local_libyuv()
    else()
        find_package(PkgConfig QUIET)
        if(PKG_CONFIG_FOUND)
            pkg_check_modules(_LIBYUV libyuv)
        endif(PKG_CONFIG_FOUND)

        if(NOT LIBYUV_INCLUDE_DIR)
            find_path(LIBYUV_INCLUDE_DIR NAMES libyuv.h PATHS ${_LIBYUV_INCLUDE_DIRS})
        endif()

        if(NOT LIBYUV_LIBRARY)
            find_library(LIBYUV_LIBRARY NAMES yuv PATHS ${_LIBYUV_LIBRARY_DIRS})
        endif()
    endif()
    if(LIBYUV_LIBRARY)
        set(LIBYUV_LIBRARIES ${LIBYUV_LIBRARIES} ${LIBYUV_LIBRARY})
    endif(LIBYUV_LIBRARY)
    if(LIBYUV_INCLUDE_DIR AND NOT LIBYUV_VERSION)
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
    endif()

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(
        libyuv
        FOUND_VAR LIBYUV_FOUND
        REQUIRED_VARS LIBYUV_LIBRARY LIBYUV_LIBRARIES LIBYUV_INCLUDE_DIR
        VERSION_VAR _LIBYUV_VERSION
    )

    # show the LIBYUV_INCLUDE_DIR, LIBYUV_LIBRARY and LIBYUV_LIBRARIES variables only
    # in the advanced view
    mark_as_advanced(LIBYUV_INCLUDE_DIR LIBYUV_LIBRARY LIBYUV_LIBRARIES)

endif()
