# https://github.com/xbmc/xbmc/blob/b29d4d26b2a602659748b051308fa7b9f3f439b8/cmake/modules/FindDav1d.cmake
# - Try to find dav1d
# Once done this will define
#
#  DAV1D_FOUND - system has dav1d
#  DAV1D_INCLUDE_DIR - the dav1d include directory
#  DAV1D_LIBRARIES - Link these to use dav1d
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
set(AVIF_EXT_DIR ${PROJECT_SOURCE_DIR}/ext)
set(AVIF_EXT_INSTALL_PREFIX ${AVIF_EXT_DIR}/build)

function(avif_build_local_dav1d)
    set(AVIF_LOCAL_DAV1D_TAG "1.2.1")
    set(DAV1D_FOUND ON PARENT_SCOPE)

    find_program(NINJA_EXECUTABLE NAMES ninja ninja-build REQUIRED)
    find_program(MESON_EXECUTABLE meson REQUIRED)

    set(DAV1D_LIBRARY ${AVIF_EXT_INSTALL_PREFIX}/lib/libdav1d.a PARENT_SCOPE)
    set(DAV1D_INCLUDE_DIR ${AVIF_EXT_INSTALL_PREFIX}/include PARENT_SCOPE)
    set(DAV1D_VERSION ${AVIF_LOCAL_DAV1D_TAG} PARENT_SCOPE)

    set(EP_SOURCE_DIR ${AVIF_EXT_DIR}/dav1d)
    set(EP_BINARY_DIR "${PROJECT_SOURCE_DIR}/ext/dav1d/build")

    # Loosely based upon
    # https://github.com/BelledonneCommunications/linphone-sdk/blob/40373878e26ab10c31c7237f1a22758aac3939ab/cmake/ExternalDependencies.cmake#L360
    if(ANDROID)
        list(APPEND CMAKE_PROGRAM_PATH "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${ANDROID_HOST_TAG}/bin/")

        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7-a")
            set(ANDROID_ARCH "arm")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
            set(ANDROID_ARCH "aarch64")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
            set(ANDROID_ARCH "x86_64")
        else()
            set(ANDROID_ARCH "x86")
        endif()

        set(CROSS_FILE "${EP_SOURCE_DIR}/package/crossfiles/${ANDROID_ARCH}-android.meson")
    elseif(APPLE)
        # If we are cross compiling generate the corresponding file to use with meson
        if(IOS OR NOT CMAKE_SYSTEM_PROCESSOR STREQUAL CMAKE_HOST_SYSTEM_PROCESSOR)
            string(TOLOWER "${CMAKE_SYSTEM_NAME}" AVIF_SYSTEM_NAME)

            if(CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN")
                set(EP_SYSTEM_ENDIAN "big")
            else()
                set(EP_SYSTEM_ENDIAN "little")
            endif()

            if(NOT IOS AND CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
                set(EP_SYSTEM_PROCESSOR "aarch64")
            else()
                set(EP_SYSTEM_PROCESSOR "${CMAKE_SYSTEM_PROCESSOR}")
            endif()

            if(IOS)
                if(PLATFORM STREQUAL "Simulator")
                    set(EP_OSX_DEPLOYMENT_TARGET "-miphonesimulator-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
                else()
                    set(EP_OSX_DEPLOYMENT_TARGET "-mios-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
                endif()

                string(REGEX MATCH "^(arm*|aarch64)" ARM_ARCH "${CMAKE_SYSTEM_PROCESSOR}")
                if(ARM_ARCH AND NOT ${XCODE_VERSION} VERSION_LESS 7)
                    set(EP_ADDITIONAL_CFLAGS ", '-fembed-bitcode'")
                endif()
            else()
                set(EP_OSX_DEPLOYMENT_TARGET "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
            endif()

            set(CROSS_FILE "${PROJECT_BINARY_DIR}/crossfile-apple.meson")
            configure_file("cmake/Meson/crossfile-apple.meson.in" "${CROSS_FILE}")
        endif()
    endif()

    if(VERBOSE)
        set(QUIET OFF)
    else()
        set(QUIET ON)
    endif()

    if(CROSS_FILE)
        set(EXTRA_ARGS "--cross-file=${CROSS_FILE}")
    endif()

    file(MAKE_DIRECTORY ${AVIF_EXT_INSTALL_PREFIX}/include)

    ExternalProject_Add(
        dav1d
        GIT_REPOSITORY https://code.videolan.org/videolan/dav1d.git
        SOURCE_DIR "${EP_SOURCE_DIR}"
        BINARY_DIR "${EP_BINARY_DIR}"
        GIT_TAG ${AVIF_LOCAL_DAV1D_TAG}
        GIT_SHALLOW ON
        GIT_CLONE_FLAGS "--depth 1"
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND
            ${MESON_EXECUTABLE} --buildtype=release --default-library=static --prefix=${AVIF_EXT_INSTALL_PREFIX} --libdir=lib
            -Denable_asm=true -Denable_tools=false -Denable_examples=false -Denable_tests=false ${EXTRA_ARGS} ..
        BUILD_COMMAND ${NINJA_EXECUTABLE} -C <BINARY_DIR>
        INSTALL_COMMAND ${NINJA_EXECUTABLE} -C <BINARY_DIR> install
        BUILD_BYPRODUCTS ${AVIF_EXT_INSTALL_PREFIX}/lib/libdav1d.a
    )
    ExternalProject_Add_Step(
        dav1d mkdir_build
        COMMAND ${CMAKE_COMMAND} -E make_directory ${EP_BINARY_DIR}
        DEPENDEES download
        ALWAYS ON
    )
    set_target_properties(dav1d PROPERTIES FOLDER "ext/dav1d")
endfunction()

if(NOT TARGET dav1d::dav1d)
    if(AVIF_LOCAL_DAV1D)
        avif_build_local_dav1d()
    else()
        find_package(PkgConfig QUIET)
        if(PKG_CONFIG_FOUND)
            pkg_check_modules(_DAV1D dav1d)
            if(_DAV1D_FOUND)
                list(APPEND AVIF_PKG_CONFIG_REQUIRES dav1d)
                if(BUILD_SHARED_LIBS)
                    set(_PC_TYPE)
                else()
                    set(_PC_TYPE _STATIC)
                endif()
                set(DAV1D_LIBRARY_DIRS ${_DAV1D${_PC_TYPE}_LIBRARY_DIRS})
                set(DAV1D_LIBRARIES ${_DAV1D${_PC_TYPE}_LIBRARIES})
            endif()
        endif(PKG_CONFIG_FOUND)

        find_library(DAV1D_LIBRARY NAMES dav1d libdav1d HINTS ${DAV1D_LIBRARY_DIRS} NO_CACHE)

        find_path(DAV1D_INCLUDE_DIR NAMES dav1d/dav1d.h HINTS ${_DAV1D_INCLUDE_DIRS} NO_CACHE)

        set(DAV1D_VERSION ${_DAV1D_VERSION})
    endif()

    # Remove -ldav1d since it will be replaced with full dav1d library path
    if(DAV1D_LIBRARIES)
        list(REMOVE_ITEM DAV1D_LIBRARIES "dav1d")
    endif()
    set(DAV1D_LIBRARIES ${DAV1D_LIBRARY} ${DAV1D_LIBRARIES})

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(
        dav1d
        FOUND_VAR DAV1D_FOUND
        REQUIRED_VARS DAV1D_LIBRARY DAV1D_LIBRARIES DAV1D_INCLUDE_DIR
        VERSION_VAR DAV1D_VERSION
    )

    # show the DAV1D_INCLUDE_DIR, DAV1D_LIBRARY and DAV1D_LIBRARIES variables only
    # in the advanced view
    mark_as_advanced(DAV1D_INCLUDE_DIR DAV1D_LIBRARY DAV1D_LIBRARIES)

    if(DAV1D_FOUND)
        add_library(dav1d::dav1d UNKNOWN IMPORTED)
        set_target_properties(
            dav1d::dav1d PROPERTIES IMPORTED_LOCATION "${DAV1D_LIBRARY}" INTERFACE_INCLUDE_DIRECTORIES "${DAV1D_INCLUDE_DIR}"
        )
        set_property(GLOBAL APPEND PROPERTY AVIF_CODEC_LIBRARIES dav1d::dav1d)
        list(APPEND AVIF_CODEC_LIBRARIES dav1d::dav1d)

        if(TARGET dav1d)
            add_dependencies(dav1d::dav1d dav1d)
        endif()
    endif()
endif()
