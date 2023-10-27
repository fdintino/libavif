find_program(CARGO_CINSTALL cargo-cinstall HINTS "$ENV{HOME}/.cargo/bin")

if(CARGO_CINSTALL)
    add_executable(cargo-cinstall IMPORTED GLOBAL)
    set_property(TARGET cargo-cinstall PROPERTY IMPORTED_LOCATION ${CARGO_CINSTALL})
endif()

FetchContent_Declare(
    Corrosion
    GIT_REPOSITORY https://github.com/corrosion-rs/corrosion.git
    GIT_TAG v0.4.4
    GIT_SHALLOW ON
)

if(APPLE)
    if(CMAKE_OSX_ARCHITECTURES STREQUAL "arm64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(Rust_CARGO_TARGET "aarch64-apple-darwin")
    endif()
endif()

FetchContent_MakeAvailable(Corrosion)

if(NOT TARGET cargo-cinstall)
    FetchContent_Declare(
        cargoc
        GIT_REPOSITORY https://github.com/lu-zero/cargo-c.git
        GIT_TAG v0.9.27
        GIT_SHALLOW ON
    )
    FetchContent_MakeAvailable(cargoc)

    corrosion_import_crate(
        MANIFEST_PATH ${cargoc_SOURCE_DIR}/Cargo.toml PROFILE release IMPORTED_CRATES MYVAR_IMPORTED_CRATES FEATURES
        vendored-openssl
    )

    set(CARGO_CINSTALL $<TARGET_FILE:cargo-cinstall>)
endif()

FetchContent_Declare(
    rav1e
    GIT_REPOSITORY https://github.com/xiph/rav1e.git
    GIT_TAG v0.6.6
    GIT_SHALLOW ON
)
FetchContent_MakeAvailable(rav1e)

set(RAV1E_LIBRARY_FILE
    ${CMAKE_CURRENT_BINARY_DIR}/ext/rav1e/usr/lib/${CMAKE_STATIC_LIBRARY_PREFIX}rav1e${CMAKE_STATIC_LIBRARY_SUFFIX}
)
set(RAV1E_ENVVARS)
if(CMAKE_C_IMPLICIT_LINK_DIRECTORIES MATCHES "alpine-linux-musl")
    list(APPEND RAV1E_ENVVARS "RUSTFLAGS=-C link-args=-Wl,-z,stack-size=2097152 -C target-feature=-crt-static")
endif()
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_OSX_SYSROOT)
    list(APPEND RAV1E_ENVVARS "SDKROOT=${CMAKE_OSX_SYSROOT}")
endif()
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_OSX_DEPLOYMENT_TARGET)
    list(APPEND RAV1E_ENVVARS "MACOSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()

add_custom_target(
    rav1e
    COMMAND ${CMAKE_COMMAND} -E env ${RAV1E_ENVVARS} ${CARGO_CINSTALL} cinstall -v --release --library-type=staticlib
            --prefix=/usr --target ${Rust_CARGO_TARGET_CACHED} --destdir ${CMAKE_CURRENT_BINARY_DIR}/ext/rav1e
    DEPENDS cargo-cinstall
    BYPRODUCTS ${RAV1E_LIBRARY_FILE}
    USES_TERMINAL
    WORKING_DIRECTORY ${rav1e_SOURCE_DIR}
)
set(RAV1E_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/rav1e/usr/include/rav1e")
file(MAKE_DIRECTORY ${RAV1E_INCLUDE_DIR})
set(RAV1E_FOUND ON)

add_library(rav1e::rav1e STATIC IMPORTED)
add_dependencies(rav1e::rav1e rav1e)
target_link_libraries(rav1e::rav1e INTERFACE "${Rust_CARGO_TARGET_LINK_NATIVE_LIBS}")
set_target_properties(rav1e::rav1e PROPERTIES IMPORTED_LOCATION "${RAV1E_LIBRARY_FILE}" AVIF_LOCAL ON)
target_include_directories(rav1e::rav1e INTERFACE "${RAV1E_INCLUDE_DIR}")

set(RAV1E_LIBRARY rav1e::rav1e)
