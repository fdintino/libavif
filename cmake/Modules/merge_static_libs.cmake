function(merge_static_libs new_target target unmerged_libs)
  set(args ${ARGN})

  foreach(lib ${args})
    if("${lib}" MATCHES "(\\${CMAKE_STATIC_LIBRARY_SUFFIX}|dav1d\.a)$")
      list(APPEND libs "${lib}")
    else()
      list(APPEND unmerged_libs "${lib}")
    endif()
  endforeach()

  add_library(${new_target} INTERFACE)
  target_link_libraries(${new_target} INTERFACE ${target})
  add_dependencies(${new_target} ${new_target}_cmd_target)

  add_custom_target(
    ${new_target}_cmd_target ALL
    DEPENDS ${new_target}_cmd
    COMMENT "Merge static libraries")

  add_custom_command(
    OUTPUT ${new_target}_cmd
    DEPENDS ${target} ${libs}
    COMMENT "Merge static libraries"
    COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE:${target}> $<TARGET_FILE:${target}>.tmp
  )

  if(APPLE)
    add_custom_command(
      OUTPUT ${new_target}_cmd APPEND
      COMMAND xcrun libtool -static -o $<TARGET_FILE:${target}> $<TARGET_FILE:${target}>.tmp ${libs}
    )
  elseif(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU|Intel|IntelLLVM)$")
    add_custom_command(
      OUTPUT ${new_target}_cmd APPEND
      COMMAND ${CMAKE_COMMAND} -E echo CREATE $<TARGET_FILE:${target}> >script.ar
      COMMAND ${CMAKE_COMMAND} -E echo ADDLIB $<TARGET_FILE:${target}>.tmp >>script.ar
    )

    foreach(lib ${libs})
      add_custom_command(OUTPUT ${new_target}_cmd APPEND
        COMMAND ${CMAKE_COMMAND} -E echo ADDLIB ${lib} >>script.ar
      )
    endforeach()

    add_custom_command(
      OUTPUT ${new_target}_cmd APPEND
      COMMAND ${CMAKE_COMMAND} -E echo SAVE >>script.ar
      COMMAND ${CMAKE_COMMAND} -E echo END >>script.ar
      COMMAND ${CMAKE_AR} -M <script.ar
      COMMAND ${CMAKE_COMMAND} -E remove script.ar
    )
  elseif(MSVC)
    if(CMAKE_LIBTOOL)
      set(BUNDLE_TOOL ${CMAKE_LIBTOOL})
    else()
      find_program(BUNDLE_TOOL lib HINTS "${CMAKE_C_COMPILER}/..")

      if(NOT BUNDLE_TOOL)
        message(FATAL_ERROR "Cannot locate lib.exe to bundle libraries")
      endif()
    endif()

    add_custom_command(
      OUTPUT ${new_target}_cmd APPEND
      COMMAND ${BUNDLE_TOOL} /NOLOGO /OUT:$<TARGET_FILE:${target}> $<TARGET_FILE:${target}>.tmp ${libs}
    )
  else()
    message(FATAL_ERROR "Unsupported platform for static link merging")
  endif()

  add_custom_command(
    OUTPUT ${new_target}_cmd APPEND
    COMMAND ${CMAKE_COMMAND} -E remove $<TARGET_FILE:${target}>.tmp
  )

  set_source_files_properties(${new_target}_cmd PROPERTIES SYMBOLIC "true")
endfunction()
