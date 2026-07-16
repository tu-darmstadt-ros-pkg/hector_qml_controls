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
      // Use the managed instance so identity comparisons and its action manager stay valid
      let managed = robots.find(r => r.robot_id == robot.robot_id)
      if (!managed) {
        Ros2.error("Cannot set active robot: no robot with id '" + robot.robot_id + "' known.")
        return
      }
      activeRobot = managed
      Ros2.info("Active robot set to: " + activeRobot.name + " (" + activeRobot.namespace + ")")
    } else {
      activeRobot = null
    }
  }

  // Builds a { key: value } map from the announcement's parallel keys[]/values[] arrays.
  function buildConfig(message) {
    var cfg = {}
    if (!message.keys || !message.values) return cfg
    var keys = message.keys.toArray(), values = message.values.toArray()
    for (var i = 0; i < keys.length; ++i) cfg[keys[i]] = values[i]
    return cfg
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
    qos: Ros2.QoS().transient_local().reliable().keep_last(100)
    throttleRate: 0 // Important, otherwise we might miss announcements that arrive within one frame of each other
    onNewMessage: {
      if (!message.name || !message.ros_namespace) {
        Ros2.error("Invalid robot announcement message: " + JSON.stringify(message))
        return
      }

      let robot = robots.find(r => r.robot_id == message.id)
      if (!robot) {
        robot = robotComponent.createObject(root, {
          "robot_id": message.id,
          "name": message.name,
          "namespace": message.ros_namespace,
          "type": message.type,
          "configuration": buildConfig(message),
          "isReady": true
        })
        // Reassign instead of push so the `robots` property emits its change
        // signal; bindings like the multi-robot switcher refresh on discovery.
        robots = robots.concat(robot)
        Ros2.info("Discovered robot: " + robot.name + " (" + robot.namespace + ")")
        if (!activeRobot) {
          activeRobot = robot
          Ros2.info("Active robot set to: " + activeRobot.name + " (" + activeRobot.namespace + ")")
        }
      } else {
        Ros2.info("Updated robot announcement: " + message.name + " (" + message.ros_namespace + ")")
        robot.type = message.type
        robot.configuration = buildConfig(message)
        robot.isReady = true
      }
    }
  }
}

