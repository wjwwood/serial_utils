cmake_minimum_required(VERSION 2.4.6)

find_package(catkin)

option(SERIAL_UTILS_BUILD_WIHOUT_ROS "Build without ROS?" OFF)

if(${catkin_FOUND} AND NOT SERIAL_UTILS_BUILD_WIHOUT_ROS)
  # Build with ROS
  include(serial_utils_ros.cmake)
  # message("Building with ROS")
  build_serial_utils()
else()
  # Build normally
  include(serial_utils.cmake)
  message("Building stand alone")
  build_serial_utils()
endif()
