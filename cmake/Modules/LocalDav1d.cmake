if(NOT AVIF_LOCAL_DAV1D_TAG)
    set(AVIF_LOCAL_DAV1D_TAG "1.2.1")
endif()
if(NOT AVIF_LOCAL_DAV1D_REPO)
    set(AVIF_LOCAL_DAV1D_REPO "https://code.videolan.org/videolan/dav1d.git")
endif()

function(avif_build_local_dav1d)
    set(source_dir "${AVIF_SOURCE_DIR}/ext/dav1d")
    set(binary_dir "${CMAKE_CURRENT_BINARY_DIR}/ext/dav1d")

    find_program(NINJA_EXECUTABLE NAMES ninja ninja-build REQUIRED)
    find_program(MESON_EXECUTABLE meson REQUIRED)

    set(PATH $ENV{PATH})
    if(WIN32)
        string(REPLACE ";" "\$<SEMICOLON>" PATH "${PATH}")
    endif()
    if(ANDROID_TOOLCHAIN_ROOT)
        set(PATH "${ANDROID_TOOLCHAIN_ROOT}/bin$<IF:$<BOOL:${WIN32}>,$<SEMICOLON>,:>${PATH}")
    endif()

    if(ANDROID)
        list(APPEND CMAKE_PROGRAM_PATH "${ANDROID_TOOLCHAIN_ROOT}/bin")
        set(binary_dir "${binary_dir}/${ANDROID_ABI}")

        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7-a")
            set(android_arch "arm")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
            set(android_arch "aarch64")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
            set(android_arch "x86_64")
        else()
            set(android_arch "x86")
        endif()

        set(CROSS_FILE "${source_dir}/package/crossfiles/${android_arch}-android.meson")
    elseif(APPLE)
        # If we are cross compiling generate the corresponding file to use with meson
        if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL CMAKE_HOST_SYSTEM_PROCESSOR)
            string(TOLOWER "${CMAKE_SYSTEM_NAME}" cross_system_name)
            if(CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN")
                set(cross_system_endian "big")
            else()
                set(cross_system_endian "little")
            endif()
            if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
                set(cross_system_processor "aarch64")
            else()
                set(cross_system_processor "${CMAKE_SYSTEM_PROCESSOR}")
            endif()
            if(CMAKE_OSX_DEPLOYMENT_TARGET)
                set(cross_osx_deployment_target "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
            endif()

            set(CROSS_FILE "${PROJECT_BINARY_DIR}/crossfile-apple.meson")
            configure_file("cmake/Meson/crossfile-apple.meson.in" "${CROSS_FILE}")
        endif()
    endif()

    if(CROSS_FILE)
        set(EXTRA_ARGS "--cross-file=${CROSS_FILE}")
    endif()

    set(install_prefix "${binary_dir}/install.libavif")

    file(MAKE_DIRECTORY ${install_prefix}/include)

    ExternalProject_Add(
        dav1d
        GIT_REPOSITORY https://code.videolan.org/videolan/dav1d.git
        SOURCE_DIR "${source_dir}"
        PREFIX "${binary_dir}"
        INSTALL_DIR "${install_prefix}"
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
    set_target_properties(dav1d::dav1d PROPERTIES IMPORTED_LOCATION ${install_prefix}/lib/libdav1d.a AVIF_LOCAL ON)
    target_include_directories(dav1d::dav1d INTERFACE "${install_prefix}/include")
    target_link_directories(dav1d::dav1d INTERFACE ${install_prefix}/lib)
    add_dependencies(dav1d::dav1d dav1d)

    if(UNIX AND NOT APPLE)
        target_link_libraries(dav1d::dav1d INTERFACE ${CMAKE_DL_LIBS}) # for dlsym
    endif()

    set(DAV1D_FOUND ON PARENT_SCOPE)
    set(DAV1D_LIBRARY dav1d::dav1d PARENT_SCOPE)
    set(DAV1D_LIBRARY_DIRS ${install_prefix}/lib PARENT_SCOPE)
    set(DAV1D_INCLUDE_DIR ${install_prefix}/include PARENT_SCOPE)
    set(DAV1D_VERSION ${AVIF_LOCAL_DAV1D_TAG} PARENT_SCOPE)
    set_target_properties(dav1d::dav1d PROPERTIES FOLDER "ext/dav1d")
endfunction()

avif_build_local_dav1d()
