find_package(ignition-transport6 REQUIRED)

list(APPEND catkin_INCLUDE_DIRS ${ignition-transport6_INCLUDE_DIRS})
list(APPEND catkin_LIBRARIES ${ignition-transport6_LIBRARIES} ${Protobuf_LIBRARIES})