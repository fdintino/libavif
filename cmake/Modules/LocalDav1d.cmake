if(NOT AVIF_LOCAL_DAV1D_TAG)
    set(AVIF_LOCAL_DAV1D_TAG "1.2.1")
endif()
if(NOT AVIF_LOCAL_DAV1D_REPO)
    set(AVIF_LOCAL_DAV1D_REPO "https://code.videolan.org/videolan/dav1d.git")
endif()

function(avif_build_local_dav1d)
    set(EP_SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/dav1d")
    set(EP_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/dav1d")

    find_program(NINJA_EXECUTABLE NAMES ninja ninja-build REQUIRED)
    find_program(MESON_EXECUTABLE meson REQUIRED)

    set(PATH $ENV{PATH})
    if(WIN32)
        string(REPLACE ";" "\$<SEMICOLON>" PATH "${PATH}")
    endif()
    if(ANDROID_TOOLCHAIN_ROOT)
        if(WIN32)
            set(sep "\$<SEMICOLON>")
        else()
            set(sep ":")
        endif()
        set(PATH "${ANDROID_TOOLCHAIN_ROOT}/bin${sep}${PATH}")
    endif()

    if(ANDROID)
        list(APPEND CMAKE_PROGRAM_PATH "${ANDROID_TOOLCHAIN_ROOT}/bin")
        set(EP_BINARY_DIR "${EP_BINARY_DIR}/${ANDROID_ABI}")

        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7-a")
            set(DAV1D_ANDROID_ARCH "arm")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
            set(DAV1D_ANDROID_ARCH "aarch64")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
            set(DAV1D_ANDROID_ARCH "x86_64")
        else()
            set(DAV1D_ANDROID_ARCH "x86")
        endif()

        set(CROSS_FILE "${EP_SOURCE_DIR}/package/crossfiles/${DAV1D_ANDROID_ARCH}-android.meson")
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

    if(CROSS_FILE)
        set(EXTRA_ARGS "--cross-file=${CROSS_FILE}")
    endif()

    set(EP_INSTALL_PREFIX "${EP_BINARY_DIR}/install.libavif")

    file(MAKE_DIRECTORY ${EP_INSTALL_PREFIX}/include)

    ExternalProject_Add(
        dav1d
        GIT_REPOSITORY https://code.videolan.org/videolan/dav1d.git
        SOURCE_DIR "${EP_SOURCE_DIR}"
        PREFIX "${EP_BINARY_DIR}"
        INSTALL_DIR "${EP_INSTALL_PREFIX}"
        LIST_SEPARATOR |
        GIT_TAG ${AVIF_LOCAL_DAV1D_TAG}
        GIT_SHALLOW ON
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND
            ${CMAKE_COMMAND} -E env "PATH=${PATH}" ${MESON_EXECUTABLE} setup --buildtype=release --default-library=static
            --prefix=<INSTALL_DIR> --libdir=lib -Denable_asm=true -Denable_tools=false -Denable_examples=false
            -Denable_tests=false ${EXTRA_ARGS} <SOURCE_DIR>
        BUILD_COMMAND ${CMAKE_COMMAND} -E env "PATH=${PATH}" ${NINJA_EXECUTABLE} -C <BINARY_DIR>
        INSTALL_COMMAND ${CMAKE_COMMAND} -E env "PATH=${PATH}" ${NINJA_EXECUTABLE} -C <BINARY_DIR> install
        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libdav1d.a
    )

    add_library(dav1d::dav1d STATIC IMPORTED)
    set_target_properties(dav1d::dav1d PROPERTIES IMPORTED_LOCATION ${EP_INSTALL_PREFIX}/lib/libdav1d.a AVIF_LOCAL ON)
    target_include_directories(dav1d::dav1d INTERFACE "${EP_INSTALL_PREFIX}/include")
    target_link_directories(dav1d::dav1d INTERFACE ${EP_INSTALL_PREFIX}/lib)
    add_dependencies(dav1d::dav1d dav1d)

    if(UNIX AND NOT APPLE)
        target_link_libraries(dav1d::dav1d INTERFACE ${CMAKE_DL_LIBS}) # for dlsym
    endif()

    set(DAV1D_FOUND ON PARENT_SCOPE)
    set(DAV1D_LIBRARY dav1d::dav1d PARENT_SCOPE)
    set(DAV1D_LIBRARY_DIRS ${EP_INSTALL_PREFIX}/lib PARENT_SCOPE)
    set(DAV1D_INCLUDE_DIR ${EP_INSTALL_PREFIX}/include PARENT_SCOPE)
    set(DAV1D_VERSION ${AVIF_LOCAL_DAV1D_TAG} PARENT_SCOPE)
    set_target_properties(dav1d::dav1d PROPERTIES FOLDER "ext/dav1d")
endfunction()

avif_build_local_dav1d()
