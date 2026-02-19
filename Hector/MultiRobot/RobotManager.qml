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
  property Robot activeRobot: null
  property var robots: []

  function setActiveRobot(robot) {
    if (robot) {
      activeRobot = robotComponent.createObject(root, {
        "robot_id": robot.robot_id,
        "name": robot.name || "",
        "namespace": robot.namespace,
        "configuration": robot.configuration || "default",
        "isReady": true
      })
    } else {
      activeRobot = null
    }
  }

  QtObject {
    id: d
  }

  Component {
    id: robotComponent
    Robot {}
  }

  Subscription {
    topic: "robot_announcement"
    messageType: "hector_multi_robot_msgs/msg/RobotAnnouncement"
    qos: Ros2.QoS().transient_local().reliable()
    onNewMessage: {
      if (!message.name || !message.ros_namespace) {
        Ros2.error("Invalid robot announcement message: " + JSON.stringify(message))
        return
      }

      let robot = robots.find(r => r.id == message.id)
      if (!robot) {
        robot = robotComponent.createObject(root, {
          "robot_id": message.id,
          "name": message.name,
          "namespace": message.ros_namespace,
          "configuration": message.configuration,
          "isReady": true
        })
        robots.push(robot)
        if (!activeRobot) {
          activeRobot = robot
        }
      } else {
        robot.configuration = message.configuration
        robot.isReady = true
      }
    }
  }
}

