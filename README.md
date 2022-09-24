# cmake-require-content
Small cmake extension for preventing duplicate library errors with FetchContent

## USAGE  

In the project where FetchContent is being utilized perform the following near the top before fetching your dependent libraries:

```cmake
include(FetchContent)

FetchContent_Declare(
    cmake-require-content
    GIT_REPOSITORY "git@github.com:weagle08/cmake-require-content.git"
    GIT_TAG "main"
)
FetchContent_MakeAvailable(cmake-require-content)

include(RequireContent)

# now just use RequireContent instead of FetchContent_Declare and FetchContent_MakeAvailable
RequireContent(
    lib-name
    GIT_REPOSITORY "path/to/git/repo.git"
    GIT_TAG "commit/tag/branch"
)

add_executable(
    my-app-name PUBLIC
    "my/source/files"
)

target_link_libraries(
    my-app-name PUBLIC
    ...
    lib-name # must match name given in require content above
)
```
