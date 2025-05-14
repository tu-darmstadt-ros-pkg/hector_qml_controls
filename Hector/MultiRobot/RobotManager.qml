pragma Singleton
import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

// Manages the available robots
// Robots should announce themselves on the /robot_announcement topic
// and the RobotManager will create a Robot object for each robot
// The RobotManager will also manage the active robot
// and the active robot will be the one that is currently being controlled

Object {
  id: root
  property Robot activeRobot: robotComponent.createObject(root)
  property var robots: []

  QtObject {
    id: d
  }

  Component {
    id: robotComponent
    Robot {}
  }
}

