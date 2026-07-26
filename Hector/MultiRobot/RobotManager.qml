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

  // Parses the announcement's visualizations into plain JS objects.
  // Relative topics resolve against the announcement's ros_namespace.
  function buildVisualizations(message) {
    if (!message.visualizations) return []
    return message.visualizations.toArray().map(function(viz) {
      var topic = viz.topic.startsWith("/") ? viz.topic : message.ros_namespace + "/" + viz.topic
      return ({
        key: viz.kind + "|" + topic, // stable identity across re-announcements
        name: viz.name,
        topic: topic,
        messageType: viz.message_type,
        kind: viz.kind,
        group: viz.group,
        defaultVisibility: viz.default_visibility,
        hints: buildConfig(viz)
      })
    })
  }

  // Parses the announcement's sensors into plain JS objects.
  // Relative topics (the value topic and the warn_topic hint) resolve against the
  // announcement's ros_namespace.
  function buildSensors(message) {
    if (!message.sensors) return []
    return message.sensors.toArray().map(function(sensor) {
      var topic = sensor.topic.startsWith("/") ? sensor.topic : message.ros_namespace + "/" + sensor.topic
      var hints = buildConfig(sensor)
      var warnTopic = hints.warn_topic || ""
      if (warnTopic && !warnTopic.startsWith("/")) warnTopic = message.ros_namespace + "/" + warnTopic
      return ({
        id: sensor.id,
        name: sensor.name || sensor.id,
        topic: topic,
        messageType: sensor.message_type,
        field: sensor.field,
        unit: sensor.unit,
        icon: sensor.icon,
        prefix: sensor.prefix || "",
        warnTopic: warnTopic,
        hints: hints
      })
    })
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
          "sensors": buildSensors(message),
          "isReady": true
        })
        robot.updateVisualizations(buildVisualizations(message))
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
        robot.sensors = buildSensors(message)
        robot.updateVisualizations(buildVisualizations(message))
        robot.isReady = true
      }
    }
  }
}

