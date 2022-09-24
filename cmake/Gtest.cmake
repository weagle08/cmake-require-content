include(RequireContent)

macro(import_gtest)
    set(gtest_force_shared_crt ON CACHE "" INTERNAL)
    RequireContent(
        gtest-extern
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG release-1.11.0
    )

    message(STATUS "****GOOGLE C/C++ TEST SUITE INCLUDED****")
endmacro()