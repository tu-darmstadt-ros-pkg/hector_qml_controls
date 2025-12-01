import QtQuick 2.3
import Ros2 1.0
import Hector.Actions 1.0
import Hector.Utils 1.0

Object {
  id: root
  enum Type {
    Wheeled,
    Tracked,
    Legged,
    Quadrotor
  }
  enum OperationMode {
    Unknown,
    Safe,
    Teleoperation,
    Manipulation,
    Autonomous
  }
  property string robot_id: ""
  property string name: ""
  property string namespace: ""
  property LaunchManagerInterface launch_manager: LaunchManagerInterface {
    namespace: root.namespace
    name: "launch_manager"
  }
  property LaunchManagerInterface driver_launch_manager: LaunchManagerInterface {
    namespace: root.namespace
    name: "driver_launch_manager"
  }
  property var status: ({
    battery_level: -1, // -1 means unknown, otherwise 0-1 range
    battery_voltage: -1, // -1 means unknown, otherwise in volts
    status_code: -1, // -1 means unknown, otherwise 0 is okay, !=0 is error
    status_message: ""
  })
  property var configuration: ({})
  property var operationMode: Robot.OperationMode.Unknown
  readonly property var actionManager: RobotActionManager {
  }
  property bool isReady: false


  QtObject {
    id: d
    property var currentAction: null
  }

  Subscription {
    topic: root.namespace + "/robot_status"
    messageType: "hector_multi_robot_msgs/msg/RobotStatus"
    onNewMessage: function(message) {
      if (message.robot_id != root.robot_id) return // Wrong robot
      root.status = ({
        battery_level: message.battery_level,
        battery_voltage: message.battery_voltage,
        status_code: message.status_code,
        status_message: message.status_message || ""
      })
    }
  }
}

