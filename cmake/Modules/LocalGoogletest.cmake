message(CHECK_START "Fetching googletest")
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.13.0
    GIT_SHALLOW ON
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
set(BUILD_GMOCK ON CACHE BOOL "" FORCE)
FetchContent_GetProperties(googletest)
if(NOT googletest_POPULATED)
    FetchContent_Populate(googletest)

    set(BUILD_SHARED_LIBS_ORIG ${BUILD_SHARED_LIBS})
    set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "-")

    add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR} EXCLUDE_FROM_ALL)

    set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_ORIG} CACHE BOOL "-" FORCE)
endif()
message(CHECK_PASS "fetched")

set_target_properties(gtest gtest_main PROPERTIES AVIF_LOCAL ON)

add_library(GTest::gtest ALIAS gtest)
add_library(GTest::gtest_main ALIAS gtest_main)

set(GTEST_INCLUDE_DIRS ${googletest_SOURCE_DIR}/googletest/include)
set(GTEST_LIBRARY GTest::gtest)
set(GTEST_LIBRARIES ${GTEST_LIBRARY})
set(GTEST_MAIN_LIBRARY GTest::gtest_main)
set(GTEST_MAIN_LIBRARIES ${GTEST_MAIN_LIBRARY})

set(GTest_FOUND ON CACHE BOOL "")
