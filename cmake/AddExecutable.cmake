function(set_target_defaults)
    foreach(targetName ${ARGN})
        if(NOT TARGET "${targetName}")
            message(FATAL_ERROR "Invalid target: ${targetName}")
        endif()

        get_target_property(targetSourceDir ${targetName} SOURCE_DIR)

        target_include_directories(
            ${targetName}
            PRIVATE
            ${targetSourceDir}
            ${CMAKE_SOURCE_DIR}/include
            ${PROJECT_SOURCE_DIR}/include
        )

        # Set default properties
        set_target_properties(
            ${targetName}
            PROPERTIES
            CXX_STANDARD 17
            CXX_STANDARD_REQUIRED ON
        )
    endforeach()
endfunction()

function(executable targetName)
    add_executable(${targetName} ${ARGN})
    set_target_defaults(${targetName})
endfunction()