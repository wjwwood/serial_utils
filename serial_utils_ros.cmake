macro(build_serial_utils)
cmake_minimum_required(VERSION 2.8.3)
project(serial_utils)

find_package(catkin REQUIRED COMPONENTS serial)

find_package(Boost REQUIRED COMPONENTS system thread)

catkin_package(
  INCLUDE_DIRS include
  LIBRARIES serial_listener
  CATKIN_DEPENDS serial
  DEPENDS Boost
)

include_directories(include ${catkin_INCLUDE_DIRS})

## serial_listener library
add_library(serial_listener src/serial_listener.cc)
target_link_libraries(serial_listener ${serial_LIBRARIES} ${Boost_LIBRARIES})

install(TARGETS serial_listener
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})

install(DIRECTORY include/serial/
  DESTINATION ${CATKIN_GLOBAL_INCLUDE_DESTINATION}/serial
  FILES_MATCHING PATTERN "*.h")
endmacro()
