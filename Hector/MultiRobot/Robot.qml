import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {
  id: root
  property string robot_id: ""
  property string name: ""
  property string namespace: ""
  property string launch_config: ""
  property string driver_launch_config: ""
  property var status: ({
    battery_level: -1, // -1 means unknown, otherwise 0-1 range
    battery_voltage: -1, // -1 means unknown, otherwise in volts
    status_code: -1, // -1 means unknown, otherwise 0 is okay, !=0 is error
    status_message: ""
  })
  property var configuration: ({})
  property bool isReady: false


  QtObject {
    id: d
    property var currentAction: null
    property var lastConfigUpdate: 0

    function getLaunchConfigName(launch_config) {
      if (!launch_config || launch_config.length == 0) return "None"
      if (launch_config.length > 20) return "[custom]"
      return launch_config
    }
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

  Subscription {
    topic: root.namespace + "/launch_manager_status"
    onNewMessage: function(message) {
      let launch_config = d.getLaunchConfigName(message.launch_config || "")
      if ((launch_config == "None" || launch_config == "[custom]") && d.lastConfigUpdate > Date.now() - 5000) {
        return // Favor named launch configs for a while
      }
      d.lastConfigUpdate = Date.now()
      if (launch_config == root.launch_config) return // No change in launch config
      root.launch_config = launch_config
    }
  }
  Subscription {
    topic: root.namespace + "/driver_launch_manager_status"
    onNewMessage: function(message) {
      if (message.remote_hosts.length == 0) return
      let launch_config = d.getLaunchConfigName(message.launch_config || "")
      if (launch_config == root.launch_config) return // No change in launch config
      root.driver_launch_config = launch_config
    }
  }
}

