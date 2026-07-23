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
  //! Values intentionally equal Visualization.msg's DEFAULT_VISIBILITY_* constants.
  enum VisualizationMode {
    Off,
    WhenActive,
    On
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
  //! Robot type from the announcement, e.g. "wheeled" | "tracked" | "legged" | ...
  property string type: ""
  //! Parsed { key: value } map from the announcement's keys[]/values[] arrays.
  property var configuration: ({})
  //! Parsed visualizations from the announcement:
  //! [{ key, name, topic (absolute), messageType, kind, group, defaultVisibility, hints: {..} }]
  property var visualizations: []
  //! Session-only visibility mode per visualization key (Robot.VisualizationMode values).
  //! Initialized from the announcement's defaultVisibility.
  property var visualizationModes: ({})

  function setVisualizationMode(key, mode) {
    // Copy instead of mutating so the property change signal fires.
    // Note: Object.assign is unavailable here, the Hector.Utils Object type shadows the JS global.
    let modes = {}
    for (let k in visualizationModes) modes[k] = visualizationModes[k]
    modes[key] = mode
    visualizationModes = modes
  }

  //! Replaces the visualization list, keeping the session mode of entries that survive.
  function updateVisualizations(visualizations) {
    let modes = {}
    for (let i = 0; i < visualizations.length; ++i) {
      let viz = visualizations[i]
      modes[viz.key] = (viz.key in root.visualizationModes)
          ? root.visualizationModes[viz.key] : viz.defaultVisibility
    }
    root.visualizations = visualizations
    root.visualizationModes = modes
  }

  //! Robot namespace converted to a tf frame prefix ("/athena" -> "athena/", "" -> "").
  //! Frames forwarded to the global tf tree are prefixed with this.
  readonly property string tfPrefix: namespace.replace(/^\/+/, "").replace(/\/*$/, namespace ? "/" : "")
  //! The robot's base frame, already prefixed.
  readonly property string baseFrame: tfPrefix + "base_link"

  property var operationMode: Robot.OperationMode.Unknown
  readonly property var actionManager: RobotActionManager {
  }
  property bool isReady: false

  //! Name of the gamepad configuration the robot's gamepad manager currently has active.
  //! Empty if unknown.
  property string joyProfile: ""

  //! The robot's full gamepad mapping, null if unknown. Mirrors
  //! hector_gamepad_manager_msgs/msg/GamepadMapping as plain JS objects:
  //! { default_config: string,
  //!   configs: [{ name, description,
  //!               buttons: [{ index, plugin, actions: [{ event, function, description }] }],
  //!               axes: [{ index, plugin, function, description }] }],
  //!   config_switches: [{ index, config, description }] }
  //! Button indices 0-10 are physical, 11-24 virtual (an axis pushed past its deadzone).
  property var joyMapping: null

  //! True while the robot's teleop drive direction is reversed. False if unknown.
  property bool teleopDriveReversed: false

  QtObject {
    id: d
    property var currentAction: null

    function parseJoyMapping(message) {
      return ({
        default_config: message.default_config,
        configs: message.configs.toArray().map(function(config) {
          return ({
            name: config.name,
            description: config.description,
            buttons: config.buttons.toArray().map(function(button) {
              return ({
                index: button.index,
                plugin: button.plugin,
                actions: button.actions.toArray().map(function(action) {
                  return ({
                    event: action.event,
                    function: action.function,
                    description: action.description
                  })
                })
              })
            }),
            axes: config.axes.toArray().map(function(axis) {
              return ({
                index: axis.index,
                plugin: axis.plugin,
                function: axis.function,
                description: axis.description
              })
            })
          })
        }),
        config_switches: message.config_switches.toArray().map(function(config_switch) {
          return ({
            index: config_switch.index,
            config: config_switch.config,
            description: config_switch.description
          })
        })
      })
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
    topic: root.namespace + "/joy_teleop_profile"
    messageType: "std_msgs/msg/String"
    qos: Ros2.QoS().transient_local().reliable().keep_last(1)
    onNewMessage: function(message) { root.joyProfile = message.data }
  }

  // The mapping is immutable and published once, so the subscription only ever gets the latched
  // message and parsing it eagerly costs nothing.
  Subscription {
    topic: root.namespace + "/joy_mapping"
    messageType: "hector_gamepad_manager_msgs/msg/GamepadMapping"
    qos: Ros2.QoS().transient_local().reliable().keep_last(1)
    onNewMessage: function(message) { root.joyMapping = d.parseJoyMapping(message) }
  }

  Subscription {
    topic: root.namespace + "/joy_teleop_direction"
    messageType: "std_msgs/msg/Bool"
    throttleRate: 0
    qos: Ros2.QoS().transient_local().reliable().keep_last(1)
    onNewMessage: function(message) { root.teleopDriveReversed = message.data }
  }
}

