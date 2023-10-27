set(AVIF_LOCAL_GTEST_GIT_TAG v1.14.0)

message(CHECK_START "Fetching googletest")
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG ${AVIF_LOCAL_GTEST_GIT_TAG}
    GIT_SHALLOW ON
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
set(BUILD_GMOCK ON CACHE BOOL "" FORCE)

avif_fetchcontent_populate_cmake(googletest)
message(CHECK_PASS "fetched")

set_target_properties(gtest gtest_main PROPERTIES AVIF_LOCAL ON)

add_library(GTest::gtest ALIAS gtest)
add_library(GTest::gtest_main ALIAS gtest_main)


set(GTest_FOUND ON CACHE BOOL "")
