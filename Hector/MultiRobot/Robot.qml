import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {
  id: root
  property string namespace: "/ec_swift"


  QtObject {
    id: d
    property var currentAction: null
  }
}

