# -*- mode: cmake; -*-

# version: 0.3.0

# Important directories
# =====================
#
# Source and build directories
# ----------------------------
#
# The following CMake variables are bound to directories that are
# important for the build process:
#
#  - ‘CMAKE_SOURCE_DIR’
#
#    The source direcory from which the top-most ‘CMakeLists.txt’ file
#    was invoked.  See also ‘CMAKE_BINARY_DIR’.
#
#  - ‘CMAKE_CURRENT_SOURCE_DIR’
#
#    The source directory containing the ‘CMakeLists.txt’ file that is
#    currently being processed (only changed during calls to
#    ‘add_subdirectory()’).  See also ‘CMAKE_CURRENT_BINARY_DIR’.
#
#  - ‘CMAKE_CURRENT_LIST_DIR’
#
#    The source directory containing the CMake file that is currently
#    being processed (changed during calls to ‘add_subdirectory()’ ánd
#    during calls to ‘include()’).  See also ‘CMAKE_CURRENT_LIST_FILE’
#    and ‘CMAKE_CURRENT_LIST_LINE’.
#
#  - ‘PROJECT_SOURCE_DIR’
#
#    The source directory of the most recent call to ‘project()’ in
#    the current or parent scope.  See also ‘PROJECT_BINARY_DIR’.
#
#  - ‘projectName_SOURCE_DIR’
#
#    The source directory of the most recent call to
#    ‘project(projectName)’ in the current or parent scope.  See also
#    ‘projectName_BINARY_DIR’.
#
#
# Installation directories
# ------------------------
#
# Loading the ‘GNUInstallDirs’ module sets the following installation
# directories:
#
# - ‘BINDIR’
#
#   Executables, scripts and symlinks intended for end users to run
#   directly.  Defaults to ‘bin’.
#
# - ‘DATADIR’
#
#   Read-only architecture-independent data such as images and other
#   resources.  Defaults to the same as ‘DATAROOTDIR’ and is the
#   preferred way to refer to locations for arbitrary project data not
#   covered by other defined locations.
#
# - ‘DATAROOTDIR’
#
#   Root point of read-only architecture-independent data.  Not
#   typically referred to directly, except perhaps to work around
#   caveats for ‘DOCDIR’.
#
# - ‘DOCDIR’
#
#   Generic documentation.  Defaults to
#   ‘DATAROOTDIR/doc/PROJECT_NAME’, where ‘PROJECT_NAME’ is the
#   project name set by the last observed ‘project()’ invocation.
#
#   Module ‘GNUInstallDirs’ sets the ‘DOCDIR’ path based on the
#   binding for ‘PROJECT_NAME’.
#
#   This is problematic for builds with multiple ‘project()’
#   invocations.  In such builds the binding for ‘PROJECT_NAME’ varies
#   throughout the build process.  We want the ‘DOCDIR’ binding to
#   reflect changes of the ‘PROJECT_NAME’ binding.
#
#   Unfortunately, the ‘GNUInstallDirs’ module sets cache variables
#   only if they are not already defined.  This implies that the value
#   of ‘CMAKE_INSTALL_DOCDIR’ is not changed during the build proces.
#   It static value is determined by where the ‘GNUInstallDirs’ module
#   is first included.
#
#   We must work around this instance of TDAI by explicitly setting
#   the ‘DOCDIR’ after each inclusion of the ‘GNUInstallDirs’ module.
#
# - ‘INCLUDEDIR’
#
#   Header files. Defaults to ‘include’.
#
# - ‘LIBDIR’
#
#   Libraries and object files.  Defaults to ‘lib’ or some variation
#   of that depending on the host/target platform (including possibly
#   a further architecture-specific subdirectory).
#
# - ‘LIBEXECDIR’
#
#   Executables not directly invoked by users, but might be run via
#   launch scripts or symlinks
#
# - ‘SBINDIR’
#
#   Similar to ‘BINDIR’ except intended for system admin use.
#   Defaults to ‘sbin’.

include(GNUInstallDirs)
set(CMAKE_INSTALL_DOCDIR ${CMAKE_INSTALL_DATAROOTDIR}/doc/${PROJECT_NAME})



# Base install location
# =====================
#
# The default value of ‘CMAKE_INSTALL_PREFIX’ is good on Windows:
# ‘C:\Program Files\${PROJECT_NAME}’
#
# But on Unix-based platforms it is ‘/usr/local’, which does not
# follow the File System Hierarchy (FHS) standard.  This standard
# requires that the base installation is project specific (and
# preferably also vendor-specific).
#
# We fix this by setting the non-Windows base install location
# explicitly.
#
# Notice that we explicitly check whether the current project is the
# top level of the source tree.  This ensures that we set the base
# install location once per build, even though one build may include a
# hierarchy of ‘project()’ invocations.

if(NOT WIN32 AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(CMAKE_INSTALL_PREFIX "/opt/triply.cc/${PROJECT_NAME}")
endif()



# C++ version
# ===========
#
# Setting the programming language standard is a bit clumsy in CMake:
# this must be done both globally and for each target individually.
#
#
# Global part
# -----------
#
# The programming language standard must be specified by the following
# three ‘set()’ commands, that preferably appear directly underneath
# the ‘project()’ declaration.
#
# The three ‘set()’ commands must appear together because:
#
#  - without ‘CMAKE_CXX_STANDARD_REQUIRED’ variable
#    ‘CMAKE_CXX_STANDARD’ has no effect, and
#
#  - many compilers set ‘CMAKE_CXX_EXTENSIONS’ and
#    ‘CMAKE_CXX_STANDARD’ with the same flag.
#
#
# Target-specific part
# --------------------
#
# The programming language standard must also be set for each
# individual target, since this allows the property to be applied to
# target consumers:
#
# ```cmake
# target_compile_features(${target} PUBLIC cxx_std_20)
# ```

set(CXX_EXTENSIONS OFF)
set(CXX_STANDARD 20)
set(CXX_STANDARD_REQUIRED ON)



# Allowed build types
# ===================
#
# When using a single-configuration generator, we want to set a
# default built type so that we do not need to set the
# ‘CMAKE_BUILD_TYPE’ flag manually all the time.
#
# While we're at it, we also want to ensure that ‘CMAKE_BUILD_TYPE’
# has a valid value when set explicitly.
#
# The following snippet will not have any effect on
# multi-configuration generators, which manage the selection of the
# build type themselves.
#
# For example, the follow snippet uses ‘Debug’ as the default build
# type, and checks whether the build type is one of ‘Debug’,
# ‘MinSizeRel’, ‘RelWithDebInfo’, ‘Release’:

get_property(is-multi-config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT is-multi-config)
  set(allowed-build-types Debug MinSizeRel RelWithDebInfo Release)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${allowed-build-types})
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "" FORCE)
  elseif(NOT CMAKE_BUILD_TYPE IN_LIST allowed-build-types)
    message(FATAL_ERROR "Invalid build type ‘${CMAKE_BUILD_TYPE}’.  Choose from ‘${allowed-build-types}’.")
  endif()
endif()



# Architecture tuning
# ===================
#
# Tune the binaries to the compilation context / machine hardware.
# This makes the build more performant, but also implied that they
# cannot be used on most other machine types.

option(use_arch "Whether or not code is optimized for one particular machine." OFF)



# Require out-of-source builds
# ============================
#
# The following emits an error when attempting to build from within a
# directory that contains a ‘CMakeLists.txt’ file.  This avoids one of
# the more common mistakes when intending to run an out-of-source
# build: to accidentally run the build from a regular project
# directory.
#
# This snippet does not disallow (accidentally) running the build from
# a source subdirectory that does not contain a ‘CMakeLists.txt’ file,
# but this is a less common mistake, since it is best practice to
# split up build instructions into multiple ‘CMakeLists.txt’ files,
# i.e., typically one in most source subdirectories.

option(use_out-of-source "Whether or not out-of-source builds are required." ON)
if(use_out-of-source)
  file(TO_CMAKE_PATH ${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt CMakeLists-location)
  if(EXISTS CMakeLists-location)
    message(FATAL_ERROR "This project requires out-of-source builds.")
  endif()
endif()



# Conan support
# =============
#
# The Conan/CMake project
# (https://github.com/conan-io/cmake-conan/raw/v0.16.1/conan.cmake)
# allows us to use Conan dependencies as regular CMake targets.
#
# The following snippet ensures that Conan/CMake is present in a
# locally cached file called ‘conan.cmake’.  The Conan dependencies
# must be described in a file called ‘conanfile.py’.
#
# Conan also supports a simplified text-based configuration format.
# The configuration files for that are called ‘conan.txt’.  While
# these files are shorter for simpler project, they lack important
# features that are almost always needed in real-world projects.  We
# therefore assume that the Conan configuration files always called
# ‘conanfile.py’.

if(NOT EXISTS ${CMAKE_BINARY_DIR}/conan.cmake)
  message(STATUS "Downloading conan.cmake 0.17.0")
  # Securely download files
  # -----------------------
  #
  # We sometimes want to download resources from the Internet during
  # the build.  When we do so, we want to guarantee that we can trust
  # the contents of such downloads, so they will all be over an secure
  # (SSL) connection.
  #
  # The following snippet shows how the Conan/CMake resource is
  # downloaded from Github.  Notice that we keep a log file, show the
  # download progress, set a timeout, and verify the status object.
  file(
    DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/0.17.0/conan.cmake"
    ${CMAKE_BINARY_DIR}/conan.cmake
    EXPECTED_HASH SHA256=3bef79da16c2e031dc429e1dac87a08b9226418b300ce004cc125a82687baeef
    INACTIVITY_TIMEOUT 1
    SHOW_PROGRESS
    STATUS status-object
    TLS_VERIFY ON)
  list(GET status-object 0 status-code)
  if(NOT status-code EQUAL 0)
    list(GET status-object 1 status-message)
    file(REMOVE ${CMAKE_BINARY_DIR}/conan.cmake)
    message(FATAL_ERROR "Could not download conan.cmake: ${status-message}")
  endif()
endif()
# Because CMAKE_BINARY_DIR was added to the CMAKE_MODULE_PATH, we can
# include ‘conan.cmake’ in the following way:
include(conan)

# Look for either ‘conanfile.py’ or ‘conanfile.txt’ (in that order).
find_file(conanfile
  NAMES conanfile.py conanfile.txt
  PATHS .
  REQUIRED)

# This allows Conan dependencies to be included as CMake
# targets in the following way:
#
# ```cmake
# target_link_libraries(someTarget
#   PUBLIC
#     CONAN_PKG::dependencyA
#   PRIVATE
#     CONAN_PKG::dependencyB)
# ```
conan_cmake_run(
  BASIC_SETUP CMAKE_TARGETS
  BUILD missing
  CONANFILE ${conanfile})



# Compiler caching
# ================
#
# Use compiler caching to speed up non-initial compilations of the
# same compilation unit.  Only supported by Clang and GCC.
#
# Notice that you must have CCache installed in order to use this
# feature.

option(use_compiler-cache "Whether or not to use compiler caching (Clang and GCC only)." ON)
if(use_compiler-cache)
  find_program(ccache-program ccache
    DOC "The path to the ‘ccache’ program.")
  if(ccache-program)
    set(CMAKE_CXX_COMPILER_LAUNCHER ${ccache-program})
  else()
    message(STATUS "Compiler caching is not supported on this machine.")
  endif()
endif()



# PIC/PIE/ASLR
# ============
#
# Use Position Independent Code (PIC) for executables (PIE); more
# secure because of Address Space Layout Randomization (ASLR).
#
# This is also required when using this library in the context of some
# other C/C++ projects (e.g., this is required for SWI-Prolog
# integration).

option(use_pie "Whether or not to use Position Independent Code (PIC) for executables (PIE)." ON)
if(use_pie)
  include(CheckPIESupported)
  check_pie_supported(
    LANGUAGES CXX
    OUTPUT_VARIABLE pie-out)
  if(NOT CMAKE_CXX_LINK_PIE_SUPPORTED)
    message(STATUS "PIE is not supported at link time: ${pie-out}.")
  endif()
endif()



# IPO/LTO
# =======
#
# Interprocedural Optimization (IPO) / Link Time Optimization (LTO).
#
# Allows the linker to look beyond compilation unit boundaries,
# potentially resulting in additional optimizations.

option(use_ipo "Whether or not to use Iterprocedural Optimization (IPO) / Link Time Optimization (LTO)." OFF)
if(use_ipo)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT ipo-result OUTPUT ipo-out)
  if(ipo-result)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
  else()
    message(STATUS "IPO is not supported: ${ipo-out}")
  endif()
endif()



# Warnings
# ========
#
# An interface library for setting generic options and warnings.
#
# Warnings-as-errors are best practice, but not achievable at the
# moment.

option(use_warnings-as-errors "Whether or not to treat compiler warnings as errors." OFF)
set(msvc-warnings
  /W4
  /w14242 # ‘identfier’: conversion from ‘type1’ to ‘type1’, possible loss of data.
  /w14254 # ‘operator’: conversion from ‘type1:field_bits’ to ‘type2:field_bits’, possible loss of data.
  /w14263 # ‘function’: member function does not override any base class virtual member function.
  /w14265 # ‘classname’: class has virtual functions, but destructor is not virtual instances of this class may not be destructed correctly.
  /w14287 # ‘operator’: unsigned/negative constant mismatch.
  /we4289 # nonstandard extension used: ‘variable’: loop control variable declared in the for-loop is used outside the for-loop scope.
  /w14296 # ‘operator’: expression is always ‘boolean_value’.
  /w14311 # ‘variable’: pointer truncation from ‘type1’ to ‘type2’.
  /w14545 # expression before comma evaluates to a function which is missing an argument list.
  /w14546 # function call before comma missing argument list.
  /w14547 # ‘operator’: operator before comma has no effect; expected operator with side-effect.
  /w14549 # ‘operator’: operator before comma has no effect; did you intend ‘operator’?
  /w14555 # expression has no effect; expected expression with side- effect.
  /w14619 # pragma warning: there is no warning number ‘number’.
  /w14640 # Enable warning on thread un-safe static member initialization.
  /w14826 # Conversion from ‘type1’ to ‘type_2’ is sign-extended. This may cause unexpected runtime behavior.
  /w14905 # Wide string literal cast to ‘LPSTR’.
  /w14906 # string literal cast to ‘LPWSTR’.
  /w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied.
  /permissive- # standards conformance mode for MSVC compiler.
)
set(clang-warnings
  -Wall
  -Wcast-align # Warn for potential performance problem casts.
  -Wconversion # Warn on type conversions that may lose data.
  -Wdouble-promotion # Warn if float is implicit promoted to double.
  -Wextra
  -Wformat=2 # Warn on security issues around functions that format output (i.e. ‘printf’).
  -Wnon-virtual-dtor # Warn the user if a class with virtual functions has a non-virtual destructor.  This helps catch memory errors that are hard to track down.
  -Wnull-dereference # Warn if a null dereference is detected.
  -Wold-style-cast # Warn for c-style casts.
  -Woverloaded-virtual # Warn if you overload (not override) a virtual function.
  -Wpedantic # Warn if non-standard C++ is used.
  -Wshadow # Warn the user if a variable declaration shadows one from a parent context.
  -Wsign-conversion # Warn on sign conversions.
  -Wunused # Warn on anything being unused.
)
if(use_warnings-as-errors)
  set(clang-warnings ${clang-warnings} -Werror)
  set(msvc-warnings ${msvc-warnings} /WX)
endif()
set(gcc-warnings
  ${clang-warnings}
  -Wduplicated-branches # Warn if if/else branches have duplicated code.
  -Wduplicated-cond # Warn if if/else chain has duplicated conditions.
  -Wlogical-op # Warn about logical operations being used where bitwise were probably wanted.
  -Wmisleading-indentation # Warn if identation implies blocks where blocks do not exist.
  -Wuseless-cast # Warn if you perform a cast to the same type.
)
add_library(generics INTERFACE)
add_library(triply::generics ALIAS generics)
target_compile_features(generics
  INTERFACE cxx_std_20)
target_compile_options(generics
  INTERFACE $<$<CONFIG:Debug>:
              $<IF:$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>>,
                ${clang-warnings},
                $<IF:$<CXX_COMPILER_ID:GNU>,
                  ${gcc-warnings},
                  $<$<BOOL:MSVC>:${msvc-warnings}>>>>)
if(use_arch)
  target_compile_options(generics
    INTERFACE -march=native)
endif()
install(TARGETS generics
  EXPORT ${PROJECT_NAME})



# Sanitizers
# ==========

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
  option(use_coverage_reporting "Enable coverage reporting for GCC and Clang." OFF)
  if(use_coverage_reporting)
    target_compile_options(generics INTERFACE --coverage -O0 -g)
    target_link_libraries(generics INTERFACE --coverage)
  endif()
  set(sanitizers "")
  option(use_sanitizer_address "Enable address sanitizer." OFF)
  if(use_sanitizer_address)
    list(APPEND sanitizers "address")
  endif()
  option(use_sanitizer_leak "Enable leak sanitizer." OFF)
  if(use_sanitizer_leak)
    list(APPEND sanitizers "leak")
  endif()
  option(use_sanitizer_undefined "Enable undefined behavior sanitizer." OFF)
  if(use_sanitizer_undefined)
    list(APPEND sanitizers "undefined")
  endif()
  option(use_sanitizer_thread "Enable thread sanitizer" OFF)
  if(use_sanitizer_thread)
    if("address" IN_LIST sanitizers OR "leak" IN_LIST sanitizers)
      message(FATAL_ERROR "Thread sanitizer does not work with address or leak sanitizers enabled.")
    else()
      list(APPEND sanitizers "thread")
    endif()
  endif()
  option(use_sanitizer_memory "Enable memory sanitizer." OFF)
  if(use_sanitizer_memory AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if("address" IN_LIST sanitizers OR "thread" IN_LIST sanitizers OR "leak" IN_LIST sanitizers)
      message(FATAL_ERROR "Clang memory sanitizer does not work with address, thread or leak sanitizers enabled.")
    else()
      list(APPEND sanitizers "memory")
    endif()
  endif()
  list(JOIN sanitizers "," sanitizersList)
endif()
if(sanitizersList)
  if(NOT "${sanitizersList}" STREQUAL "")
    target_compile_options(generics INTERFACE -fsanitize=${sanitizersList})
    target_link_libraries(generics INTERFACE -fsanitize=${sanitizersList})
  endif()
endif()



# Satic analysis
# ==============
#
# cppcheck
# --------

option(use_cppcheck "Whether to use cppcheck for static analysis." OFF)
if(use_cppcheck)
  find_program(cppcheck cppcheck)
  if(cppcheck)
    set(CMAKE_CXX_CPPCHECK ${cppcheck} --enable=all --suppress=missingIncludeSystem)
  else()
    message(FATAL_ERROR "Could not find cppcheck.")
  endif()
endif()


# clang-tidy
# ----------

option(use_clang_tidy "Whether to use clang-tidy for static analysis." OFF)
if (use_clang_tidy)
  find_program(clangTidy clang-tidy)
  if(clangTidy)
    set(CMAKE_CXX_CLANG_TIDY ${clangTidy})
    # Generate the file ‘compile_commands.json’ that is used by Clang
    # tools.
    #
    # Linking to the file ‘compile_commands.json’ from the project
    # root directory will enable Clang Tidy static analysis for your
    # source code.
    #
    # Creating file links is an OS-specific operation.  On Linux this done
    # in the following way:
    #
    # ```sh
    # ln -s {build-directory}/compile_commands.json {root-directory}
    # ```
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  else()
    message(FATAL_ERROR "Could not find clang-tidy.")
  endif()
endif()



# Documentation
# =============
#
# This requires that Doxygen is installed.

option(use_documentation "Generate documentation with Doxygen." OFF)
if(use_documentation)
  find_package(Doxygen
    REQUIRED dia dot mscgen)
  set(DOXYGEN_CALLER_GRAPH YES)
  set(DOXYGEN_CALL_GRAPH YES)
  # TODO: This does not work yet: warnings for these files still appear.
  set(DOXYGEN_EXCLUDE include/rdf/location.hpp include/rdf/lexer.hpp src/rdf/lexer.cpp)
  set(DOXYGEN_EXTRACT_ALL NO)
  set(DOXYGEN_QUIET YES)
  set(DOXYGEN_WARN_AS_ERROR NO)
  set(DOXYGEN_WARN_IF_UNDOCUMENTED YES)
  doxygen_add_docs(docs
    ${PROJECT_SOURCE_DIR}
    COMMENT "Generate documentation.")
endif()



# Library aliases
# ===============
#
# It is best practice to create a library alias ‘$project::$target’
# for every library that will be installed or packaged:
#
# ```cmake
# add_library(my-project::my-library ALIAS my-library)
# ```
#
# This has the following benefits:
#
#   - Undefined targets that contain a double colon (‘::’) are not
#     assumed to denote system libraries, so a typo in an aliased
#     target is detected at generation time (rather than at linking
#     time).
#
#   - Whether pulling in the library using ‘find_package()’ or
#     ‘add_subdirectory()’, the syntax in ‘target_link_libraries()’
#     stays the same.
#
#   - Targets that are neither an alias nor are imported cannot shadow
#     target names that contain a double colon (‘::’), so name
#     collisions are less likely.
