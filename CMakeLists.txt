cmake_minimum_required(VERSION 3.5.0)
project(hector_qml_controls VERSION 1.0.0)

find_package(ament_cmake REQUIRED)


#############
## Install ##
#############

install(DIRECTORY Hector DESTINATION share/${PROJECT_NAME})

ament_environment_hooks(register_hector_qml_controls.dsv.in)

ament_package()
