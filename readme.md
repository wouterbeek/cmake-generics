# CMake Generics

Use the following snippet to your `CMakeLists.txt` file to use the
generics in this project:

```cmake
list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})
if(NOT EXISTS ${CMAKE_BINARY_DIR}/Generics.cmake)
  message(STATUS "Downloading CMake Generics 0.3.4")
  file(
    DOWNLOAD "https://github.com/wouterbeek/cmake-generics/raw/0.3.4/Generics.cmake"
    ${CMAKE_BINARY_DIR}/Generics.cmake
    INACTIVITY_TIMEOUT 1
    SHOW_PROGRESS
    STATUS status-object
    TLS_VERIFY ON)
  list(GET status-object 0 status-code)
  if(NOT status-code EQUAL 0)
    list(GET status-object 1 status-message)
    file(REMOVE ${CMAKE_BINARY_DIR}/Generics.cmake)
    message(FATAL_ERROR "Could not download Generics.cmake: " ${status-message})
  endif()
endif()
include(Generics)
```
