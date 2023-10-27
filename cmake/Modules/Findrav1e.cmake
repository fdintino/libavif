# - Try to find rav1e
# Once done this will define
#
#  RAV1E_FOUND - system has rav1e
#  RAV1E_INCLUDE_DIR - the rav1e include directory
#  RAV1E_LIBRARIES - Link these to use rav1e
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

find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(RAV1E_PC rav1e)
    if(RAV1E_PC_FOUND)
        if(BUILD_SHARED_LIBS)
            set(_PC_TYPE)
        else()
            set(_PC_TYPE _STATIC)
        endif()
        set(RAV1E_LIBRARY_DIRS ${RAV1E_PC${_PC_TYPE}_LIBRARY_DIRS})
        set(RAV1E_LIBRARIES ${RAV1E_PC${_PC_TYPE}_LIBRARIES})
    endif()
endif(PKG_CONFIG_FOUND)

if(NOT RAV1E_INCLUDE_DIR)
    find_path(
        RAV1E_INCLUDE_DIR
        NAMES rav1e.h
        PATHS ${RAV1E_PC_INCLUDE_DIRS}
        PATH_SUFFIXES rav1e
    )
endif()

find_library(RAV1E_LIBRARY NAMES rav1e PATHS ${RAV1E_PC_LIBRARY_DIRS})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    rav1e
    FOUND_VAR RAV1E_FOUND
    REQUIRED_VARS RAV1E_LIBRARY RAV1E_LIBRARIES RAV1E_INCLUDE_DIR
    VERSION_VAR RAV1E_PC_VERSION
)

# show the RAV1E_INCLUDE_DIR, RAV1E_LIBRARY, RAV1E_LIBRARIES, and RAV1E_PC_FOUND variables only in the advanced view
mark_as_advanced(RAV1E_INCLUDE_DIR RAV1E_LIBRARY RAV1E_LIBRARIES RAV1E_PC_FOUND)

if(RAV1E_LIBRARY)
    if(NOT TARGET rav1e)
        add_library(rav1e STATIC IMPORTED GLOBAL)
        set_target_properties(rav1e PROPERTIES IMPORTED_LOCATION "${RAV1E_LIBRARY}")
        target_include_directories(rav1e INTERFACE ${RAV1E_INCLUDE_DIR})
        if(RAV1E_LIBRARIES)
            set(RAV1E_LINK_LIBRARIES ${RAV1E_LIBRARIES})
            list(REMOVE_ITEM RAV1E_LINK_LIBRARIES rav1e)
            if(WIN32)
                # Remove msvcrt from RAV1E_LIBRARIES since it's linked by default
                list(REMOVE_ITEM RAV1E_LINK_LIBRARIES "msvcrt.lib" "-lmsvcrt")

                # If we have system libraries that include kernel32 but not ntdll, add it to address
                # https://github.com/rust-lang/rust/issues/115813
                if("kernel32.lib" IN_LIST RAV1E_LINK_LIBRARIES AND NOT "ntdll.lib" IN_LIST RAV1E_LINK_LIBRARIES)
                    list(APPEND RAV1E_LINK_LIBRARIES "ntdll.lib")
                    # cygwin and msys2 libraries are formatted with a -l prefix
                elseif("-lkernel32" IN_LIST RAV1E_LINK_LIBRARIES AND NOT "-lntdll" IN_LIST RAV1E_LINK_LIBRARIES)
                    list(APPEND RAV1E_LINK_LIBRARIES "-lntdll")
                elseif("kernel32" IN_LIST RAV1E_LINK_LIBRARIES AND NOT "ntdll" IN_LIST RAV1E_LINK_LIBRARIES)
                    list(APPEND RAV1E_LINK_LIBRARIES "ntdll")
                endif()
            endif()
        else(RAV1E_LIBRARIES)
            if(WIN32)
                set(RAV1E_LINK_LIBRARIES ntdll.lib userenv.lib ws2_32.lib bcrypt.lib)
            elseif(UNIX AND NOT APPLE)
                set(RAV1E_LINK_LIBRARIES ${CMAKE_DL_LIBS}) # for backtrace
            endif()
        endif()
        if(RAV1E_LINK_LIBRARIES)
            target_link_libraries(rav1e INTERFACE ${RAV1E_LINK_LIBRARIES})
        endif()
    endif()

    if(NOT TARGET rav1e::rav1e)
        add_library(rav1e::rav1e ALIAS rav1e)
    endif()
    set(RAV1E_LIBRARY rav1e)
endif()

# show the RAV1E_INCLUDE_DIR, RAV1E_LIBRARY and RAV1E_LIBRARIES variables only
# in the advanced view
mark_as_advanced(RAV1E_INCLUDE_DIR RAV1E_LIBRARY RAV1E_LIBRARIES)
