#!/bin/bash
# If you copy this file to add another package to the qml import path, note that the filename of this script needs to be unique!

@[if DEVELSPACE]@
  case $QML2_IMPORT_PATH in
    *"@(PROJECT_SOURCE_DIR)"*) ;;
    *) export QML2_IMPORT_PATH="@(PROJECT_SOURCE_DIR):${QML2_IMPORT_PATH}"
  esac
@[else]@
  case $QML2_IMPORT_PATH in
    *"@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)"*) ;;
    *) export QML2_IMPORT_PATH="@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION):${QML2_IMPORT_PATH}"
  esac
@[end if]@
