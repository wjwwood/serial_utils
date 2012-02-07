macro(build_serial_utils)
## Project Setup
cmake_minimum_required(VERSION 2.4.6)

if(COMMAND cmake_policy)
    cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)

project(serial_utils)

## Configurations

# Use clang if available
IF(EXISTS /usr/bin/clang)
  set(CMAKE_CXX_COMPILER /usr/bin/clang++)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "")
  # set(CMAKE_CXX_FLAGS "-ferror-limit=5 -std=c++0x -stdlib=libc++")
  set(CMAKE_CXX_FLAGS "-ferror-limit=5 -Wall -Weffc++ -pedantic -pedantic-errors -Wextra  -Wall -Waggregate-return -Wcast-align -Wcast-qual  -Wchar-subscripts  -Wcomment -Wconversion -Wdisabled-optimization -Wfloat-equal  -Wformat  -Wformat=2 -Wformat-nonliteral -Wformat-security  -Wformat-y2k -Wimplicit  -Wimport  -Winit-self  -Winline -Winvalid-pch   -Wlong-long -Wmissing-braces -Wmissing-field-initializers -Wmissing-format-attribute   -Wmissing-include-dirs -Wmissing-noreturn -Wpacked -Wparentheses  -Wpointer-arith -Wredundant-decls -Wreturn-type -Wsequence-point  -Wshadow -Wsign-compare  -Wstack-protector -Wstrict-aliasing -Wstrict-aliasing=2 -Wswitch  -Wswitch-default -Wswitch-enum -Wtrigraphs  -Wuninitialized -Wunknown-pragmas  -Wunreachable-code -Wunused -Wunused-function  -Wunused-label  -Wunused-parameter -Wunused-value  -Wunused-variable  -Wvariadic-macros -Wvolatile-register-var  -Wwrite-strings")
  set(CMAKE_BUILD_TYPE Debug)
ENDIF(EXISTS /usr/bin/clang)

option(SERIAL_UTILS_BUILD_TESTS "Build all of the Serial utils tests." OFF)
option(SERIAL_UTILS_BUILD_EXAMPLES "Build all of the Serial utils examples." OFF)

# Allow for building shared libs override
IF(NOT BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS OFF)
ENDIF(NOT BUILD_SHARED_LIBS)

# Set the default path for built executables to the "bin" directory
IF(NOT DEFINED(EXECUTABLE_OUTPUT_PATH))
    set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
ENDIF(NOT DEFINED(EXECUTABLE_OUTPUT_PATH))
# set the default path for built libraries to the "lib" directory
IF(NOT DEFINED(LIBRARY_OUTPUT_PATH))
    set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)
ENDIF(NOT DEFINED(LIBRARY_OUTPUT_PATH))

## Configure the build system

# Add the include folder to the include path
include_directories(${PROJECT_SOURCE_DIR}/include)

# Add default source files
set(SERIAL_UTILS_SRCS src/serial_listener.cc)
# Add default header files
set(SERIAL_UTILS_HEADERS include/serial/utils/serial_listener.h)

# Find serial
IF(NOT serial_FOUND)
    find_package(serial REQUIRED)
ENDIF(NOT serial_FOUND)

include_directories(${serial_INCLUDE_DIRS})

set(SERIAL_UTILS_LINK_LIBS ${serial_LIBRARIES})

# Find Boost, if it hasn't already been found
IF(NOT Boost_FOUND OR NOT Boost_THREAD_FOUND)
    find_package(Boost COMPONENTS thread REQUIRED)
ENDIF(NOT Boost_FOUND OR NOT Boost_THREAD_FOUND)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

list(APPEND SERIAL_UTILS_LINK_LIBS ${Boost_THREAD_LIBRARY})

## Build the Serial Library

# Compile the Library
add_library(serial_utils ${SERIAL_UTILS_SRCS})
target_link_libraries(serial_utils ${SERIAL_UTILS_LINK_LIBS})

## Build Examples

# If asked to
IF(SERIAL_UTILS_BUILD_EXAMPLES)
    # Compile the Serial Listener Test program
    add_executable(serial_listener_example
                   examples/serial_listener_example.cc)
    # Link the Test program to the Serial library
    target_link_libraries(serial_listener_example serial_utils serial)
ENDIF(SERIAL_UTILS_BUILD_EXAMPLES)

## Build tests

# If asked to
IF(SERIAL_UTILS_BUILD_TESTS)
    # Find Google Test
    enable_testing()
    find_package(GTest REQUIRED)
    include_directories(${GTEST_INCLUDE_DIRS})

    # Compile the Serial Listener Test program
    add_executable(serial_listener_tests tests/serial_listener_tests.cc)
    # Link the Test program to the serial_utils library
    target_link_libraries(serial_listener_tests ${GTEST_BOTH_LIBRARIES}
                          serial_utils serial)

    # Compile the concurrent queue tests
    add_executable(concurrent_queue_tests tests/concurrent_queue_tests.cc)
    target_link_libraries(concurrent_queue_tests ${GTEST_BOTH_LIBRARIES}
                          ${Boost_THREAD_LIBRARY})

    add_test(AllTestsIntest_serial_listener serial_listener_listener_tests)
ENDIF(SERIAL_UTILS_BUILD_TESTS)

## Setup install and uninstall

# Unless asked not to...
IF(NOT SERIAL_UTILS_DONT_CONFIGURE_INSTALL)
    # Configure make install
    IF(NOT CMAKE_INSTALL_PREFIX)
        SET(CMAKE_INSTALL_PREFIX /usr/local)
    ENDIF(NOT CMAKE_INSTALL_PREFIX)
    
    INSTALL(TARGETS serial_utils
      RUNTIME DESTINATION bin
      LIBRARY DESTINATION lib
      ARCHIVE DESTINATION lib
    )
    
    INSTALL(FILES include/serial/utils/serial_listener.h
            DESTINATION include/serial/utils)
    
    IF(NOT CMAKE_FIND_INSTALL_PATH)
        set(CMAKE_FIND_INSTALL_PATH ${CMAKE_ROOT})
    ENDIF(NOT CMAKE_FIND_INSTALL_PATH)
    
    INSTALL(FILES Findserial_utils.cmake
            DESTINATION ${CMAKE_FIND_INSTALL_PATH}/Modules/)
    
    ADD_CUSTOM_TARGET(uninstall @echo uninstall package)
    
    IF (UNIX)
      ADD_CUSTOM_COMMAND(
        COMMENT "uninstall package"
        COMMAND xargs ARGS rm < install_manifest.txt
        
        TARGET  uninstall
      )
    ELSE(UNIX)
      ADD_CUSTOM_COMMAND(
        COMMENT "uninstall only implemented in unix"
        TARGET  uninstall
      )
    ENDIF(UNIX)
ENDIF(NOT SERIAL_UTILS_DONT_CONFIGURE_INSTALL)
endmacro(build_serial_utils)
