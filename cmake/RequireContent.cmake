# # Combines FectchContent_Declare and FetchContent_MakeAvailable and attempts to prevent duplicate library errors

include(FetchContent)

function(isLoaded targetName resultVal)
    get_property(targetList GLOBAL PROPERTY "RequiredContent_Fetched_Targets")
    list(FIND targetList "${targetName}" existingIdx)

    if(existingIdx GREATER_EQUAL "0")
        message(STATUS "Target ${targetName} is already loaded.")
        set(${resultVal} 1 PARENT_SCOPE)
    else()
        message(STATUS "Target ${targetName} is not loaded")
        set(${resultVal} 0 PARENT_SCOPE)
    endif()
endfunction()

macro(is_debugging_enabled outVar)
    get_property(${outVar} GLOBAL PROPERTY DebugMode)
endmacro()

macro(skip_if_no_debugging)
    is_debugging_enabled(_dbgEnabled)

    if(NOT _dbgEnabled)
        return()
    endif()
endmacro()

function(debug_message)
    skip_if_no_debugging()

    cmake_parse_arguments(
        ARG
        ""
        "CONTEXT"
        "MESSAGE"
        ${ARGN}
    )

    is_debug_context_enabled(ctxEnabled ${ARG_CONTEXT})

    if(NOT ctxEnabled)
        return()
    endif()

    if(ARG_CONTEXT)
        list(APPEND fullMessage "[#][${ARG_CONTEXT}] ")
    else()
        list(APPEND fullMessage "[#][*] ")
    endif()

    if(NOT ARG_MESSAGE)
        list(APPEND fullMessage ${ARG_UNPARSED_ARGUMENTS})
    else()
        list(APPEND fullMessage ${ARG_MESSAGE})
    endif()

    message(${fullMessage})
endfunction()

function(message_debug)
    debug_message(${ARGN})
endfunction()

macro(_map_fetched_target sourceTarget destTarget)
    FetchContent_GetProperties(
        ${sourceTarget}
        SOURCE_DIR ${destTarget}_SOURCE_DIR
        BINARY_DIR ${destTarget}_BINARY_DIR
        POPULATED ${destTarget}_POPULATED
    )
    set(${destTarget}_SOURCE_DIR "${${destTarget}_SOURCE_DIR}" PARENT_SCOPE)
    set(${destTarget}_BINARY_DIR "${${destTarget}_BINARY_DIR}" PARENT_SCOPE)
    set(${destTarget}_POPULATED "${${destTarget}_POPULATED}" PARENT_SCOPE)
    message_debug("${destTarget}_SOURCE_DIR: ${${destTarget}_SOURCE_DIR}" CONTEXT "RequireContent")
    message_debug("${destTarget}_BINARY_DIR: ${${destTarget}_BINARY_DIR}" CONTEXT "RequireContent")
    message_debug("${destTarget}_POPULATED: ${${destTarget}_POPULATED}" CONTEXT "RequireContent")
endmacro()

function(RequireContent targetName)
    cmake_parse_arguments(
        ARG
        "NO_WARNINGS;OFFLINE"
        "COMMENT;DISPLAY_NAME;GIT_REPOSITORY;URL"
        ""
        ${ARGN}
    )

    get_property(fetchedTargets GLOBAL PROPERTY "RequiredContent_Fetched_Targets")
    message_debug("RequiredContent_Fetched_Targets: ${fetchedTargets}" CONTEXT "RequireContent")
    list(FIND fetchedTargets "${targetName}" existingIdx)

    if(existingIdx GREATER_EQUAL "0")
        message_debug("Found previously fetched target: ${targetName}" CONTEXT "RequireContent")
        _map_fetched_target(${targetName} ${targetName})
        return()
    endif()

    get_property(fetchedSources GLOBAL PROPERTY "RequireContent_Fetched_Sources")
    get_property(fetchedConfigs GLOBAL PROPERTY "RequireContent_Fetched_Configs")
    list(APPEND extraConfigData ${ARG_UNPARSED_ARGUMENTS})
    list(SORT extraConfigData)

    # Replace semi-colons with pipes so they won't be interpreted as list items.
    string(REPLACE ";" "|" extraConfigData "${extraConfigData}")

    if(ARG_GIT_REPOSITORY OR ARG_URL)
        if(ARG_GIT_REPOSITORY)
            set(sourceArg GIT_REPOSITORY)
            set(sourceVal "${ARG_GIT_REPOSITORY}")
        elseif(ARG_URL)
            set(sourceArg URL)
            set(sourceVal "${ARG_URL}")
        endif()

        # Replace semi-colons with pipes so they won't be interpreted as list items.
        string(REPLACE ";" "|" normalizedVal "${sourceVal}")

        if(fetchedSources)
            list(LENGTH fetchedSources fetchedSourcesLength)

            # Can't use list(FIND) here as it always searches from the front of the list.
            math(EXPR maxIdx "${fetchedSourcesLength}-1")

            foreach(foundIdx RANGE ${maxIdx})
                list(GET fetchedSources ${foundIdx} fetchedSource)

                if("${fetchedSource}" STREQUAL "${normalizedVal}")
                    if(fetchedConfigs AND fetchedTargets)
                        # Ensure all the lists are the same length.
                        list(LENGTH fetchedConfigs fetchedConfigsLength)
                        list(LENGTH fetchedTargets fetchedTargetsLength)

                        if(fetchedSourcesLength EQUAL fetchedConfigsLength AND
                            fetchedSourcesLength EQUAL fetchedTargetsLength)
                            list(GET fetchedConfigs ${foundIdx} fetchedConfig)

                            if("${getchedConfig}" STREQUAL "${extraConfigData}")
                                # Found a previously fetched target. Grab the target name and set up variables to
                                # match the previouly populated ones for the target.
                                message_debug(
                                    "Found previously fetched target '${targetName}' as '${fetchedTarget}'"
                                    CONTEXT "RequireContent")
                                list(GET fetchedTargets ${foundIdx} fetchedTarget)
                                _map_fetched_target(${fetchedTarget} ${targetName})
                                return()
                            endif()
                        endif()
                    endif()
                endif()
            endforeach()
        endif()
    endif()

    if(NOT ARG_DISPLAY_NAME)
        if(sourceVal)
            get_filename_component(ARG_DISPLAY_NAME "${sourceVal}" NAME_WLE)
        else()
            set(ARG_DISPLAY_NAME "${targetName}")
        endif()
    endif()

    if(ARG_OFFLINE OR BUILD_OFFLINE)
        set(FETCHCONTENT_FULLY_DISCONNECTED ON)
    endif()

    if(NOT ARG_COMMENT)
        if(FETCHCONTENT_FULLY_DISCONNECTED)
            set(ARG_COMMENT "Fetching ${ARG_DISPLAY_NAME} (offline) ...")
        else()
            set(ARG_COMMENT "Fetching ${ARG_DISPLAY_NAME} ...")
        endif()
    endif()

    FetchContent_Declare(
        ${targetName}
        ${sourceArg}
        ${sourceVal}
        ${ARG_UNPARSED_ARGUMENTS}
    )

    if(NOT ${targetName}_POPULATED)
        message(STATUS "${ARG_COMMENT}")
        FetchContent_Populate(${targetName})
        _map_fetched_target(${targetName} ${targetName})

        if(ARG_GIT_REPOSITORY OR ARG_URL)
            message_debug("Remembering source for target ${targetName}: ${normalizedVal}"
                CONTEXT "RequireContent")
            message_debug("Remembering config data for target ${targetName}: ${extraConfigData}"
                CONTEXT "RequireContent")
            message_debug("Remembering fetched target: ${targetName}" CONTEXT "RequireContent")
            set_property(GLOBAL APPEND PROPERTY "RequireContent_Fetched_Sources" "${normalizedVal}")
            set_property(GLOBAL APPEND PROPERTY "RequireContent_Fetched_Configs" "${extraConfigData}")
            set_property(GLOBAL APPEND PROPERTY "RequiredContent_Fetched_Targets" "${targetName}")
            get_property(fetchedTargets GLOBAL PROPERTY "RequiredContent_Fetched_Targets")
            string(REPLACE ";" ", " fetchedTargets "${fetchedTargets}")
            message_debug("RequiredContent_Fetched_Targets: ${fetchedTargets}" CONTEXT "RequireContent")
        endif()

        if(EXISTS ${${targetName}_SOURCE_DIR}/CMakeLists.txt)
            add_subdirectory(${${targetName}_SOURCE_DIR} ${${targetName}_BINARY_DIR})
        endif()
    endif()
endfunction()
