if(AVIF_LOCAL_AVM)
    message(CHECK_START "Fetching avm")
else()
    message(CHECK_START "Fetching aom")
endif()

function(avif_set_aom_compile_options target)
    string(REPLACE " " ";" AOM_C_FLAGS_LIST "${AOM_C_FLAGS}")
    string(REPLACE " " ";" AOM_CXX_FLAGS_LIST "${AOM_CXX_FLAGS}")
    foreach(flag ${AOM_C_FLAGS_LIST})
        target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${flag}>)
    endforeach()
    foreach(flag ${AOM_CXX_FLAGS_LIST})
        target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${flag}>)
    endforeach()

    get_target_property(sources ${target} SOURCES)
    foreach(src ${sources})
        if(src MATCHES "TARGET_OBJECTS:")
            string(REGEX REPLACE "\\$<TARGET_OBJECTS:(.*)>" "\\1" source_target ${src})
            avif_set_aom_compile_options(${source_target})
        endif()
    endforeach()
endfunction()

if(AVIF_LOCAL_AVM)
    set(AOM_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/avm")
else()
    set(AOM_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ext/aom")
endif()
if(ANDROID_ABI)
    set(AOM_BINARY_DIR "${AOM_BINARY_DIR}/${ANDROID_ABI}")
endif()

if(NOT GIT_EXECUTABLE)
    find_package(Git QUIET)
    if(NOT GIT_EXECUTABLE)
        message(FATAL_ERROR "error: could not find git for clone of local aom")
    endif()
endif()

# The FetchContent module does not allow you to clone --single-branch and then checkout a commit
if(AVIF_LOCAL_AVM)
    FetchContent_Declare(
        libaom
        GIT_REPOSITORY "https://gitlab.com/AOMediaCodec/avm.git"
        SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/avm" BINARY_DIR "${AOM_BINARY_DIR}"
        GIT_TAG "research-v5.0.0"
        GIT_PROGRESS ON
        GIT_SHALLOW ON
        UPDATE_COMMAND ""
    )
else()
    FetchContent_Declare(
        libaom
        DOWNLOAD_COMMAND
            ${CMAKE_COMMAND} -E remove_directory <SOURCE_DIR> COMMAND ${GIT_EXECUTABLE} clone -b ironbark --single-branch
            https://aomedia.googlesource.com/aom <SOURCE_DIR> COMMAND ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> ${GIT_EXECUTABLE}
            checkout 67d97ee720d57b71c23e500007d8c54577615b89 SOURCE_DIR "${AVIF_SOURCE_DIR}/ext/aom" BINARY_DIR
            "${AOM_BINARY_DIR}"
        UPDATE_COMMAND "" USES_TERMINAL_DOWNLOAD ON
    )
endif()

set(BUILD_SHARED_LIBS_ORIG ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
set(CONFIG_PIC 1 CACHE INTERNAL "")
if(libyuv_FOUND)
    set(CONFIG_LIBYUV 0 CACHE INTERNAL "")
else()
    set(CONFIG_LIBYUV 1 CACHE INTERNAL "")
endif()
set(CONFIG_WEBM_IO 0 CACHE INTERNAL "")
set(ENABLE_DOCS 0 CACHE INTERNAL "")
set(ENABLE_EXAMPLES 0 CACHE INTERNAL "")
set(ENABLE_TESTDATA 0 CACHE INTERNAL "")
set(ENABLE_TESTS 0 CACHE INTERNAL "")
set(ENABLE_TOOLS 0 CACHE INTERNAL "")

# aom sets its compile options by setting variables like CMAKE_C_FLAGS_RELEASE using
# CACHE FORCE, which effectively adds those flags to all targets. We stash and restore
# the original values and call avif_set_aom_compile_options to instead set the flags on all aom
# targets
foreach(_aom_config_setting CMAKE_C_FLAGS CMAKE_CXX_FLAGS CMAKE_EXE_LINKER_FLAGS)
    foreach(_aom_config_type DEBUG RELEASE MINSIZEREL RELWITHDEBINFO)
        set(${_aom_config_setting}_${_aom_config_type}_ORIG ${${_aom_config_setting}_${_aom_config_type}})
    endforeach()
endforeach()

if(NOT libaom_POPULATED)
    FetchContent_Populate(libaom)
    enable_language(C CXX ASM ASM_NASM)
    add_subdirectory(${libaom_SOURCE_DIR} ${libaom_BINARY_DIR} EXCLUDE_FROM_ALL)

    avif_set_aom_compile_options(aom)

endif()

foreach(_aom_config_setting CMAKE_C_FLAGS CMAKE_CXX_FLAGS CMAKE_EXE_LINKER_FLAGS)
    foreach(_aom_config_type DEBUG RELEASE MINSIZEREL RELWITHDEBINFO)
        set(${_aom_config_setting}_${_aom_config_type} ${${_aom_config_setting}_${_aom_config_type}_ORIG} CACHE STRING "" FORCE)
        unset(${_aom_config_setting}_${_aom_config_type}_ORIG)
    endforeach()
endforeach()

set(CMAKE_C_FLAGS_${_TYPE} ${CMAKE_C_FLAGS_${_TYPE}_ORIG} CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_${_TYPE} ${CMAKE_CXX_FLAGS_${_TYPE}_ORIG} CACHE STRING "" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_${_TYPE} ${CMAKE_EXE_LINKER_FLAGS_${_TYPE}_ORIG} CACHE STRING "" FORCE)
set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_ORIG} CACHE BOOL "" FORCE)

# If we have libyuv, we disable CONFIG_LIBYUV so that aom does not include the libyuv
# sources from its third-party vendor library. But we still want AOM to have libyuv, only
# linked against this project's target. Here we update the value in aom_config.h and add libyuv
# to AOM's link libraries
if(libyuv_FOUND)
    file(READ ${AOM_BINARY_DIR}/config/aom_config.h AOM_CONFIG_H)
    if("${AOM_CONFIG_H}" MATCHES "CONFIG_LIBYUV 0")
        string(REPLACE "CONFIG_LIBYUV 0" "CONFIG_LIBYUV 1" AOM_CONFIG_H "${AOM_CONFIG_H}")
        file(WRITE ${AOM_BINARY_DIR}/config/aom_config.h "${AOM_CONFIG_H}")
    endif()
    target_link_libraries(aom PRIVATE $<TARGET_FILE:yuv::yuv>)
endif()

set_property(TARGET aom PROPERTY AVIF_LOCAL ON)

set(AOM_INCLUDE_DIR "${libaom_SOURCE_DIR}")
set(AOM_LIBRARY aom)
set(AOM_LIBRARIES ${AOM_LIBRARY})
target_include_directories(aom INTERFACE ${AOM_INCLUDE_DIR} ${AOM_BINARY_DIR})

if(AVIF_LOCAL_AVM)
    set(AVM_INCLUDE_DIR ${AOM_INCLUDE_DIR})
    set(AVM_LIBRARY ${AOM_LIBRARY})
    set(AVM_LIBRARIES ${AOM_LIBRARIES})
endif()

message(CHECK_PASS "fetched")
