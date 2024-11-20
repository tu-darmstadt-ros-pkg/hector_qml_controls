import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {

  function execute(action, execution) {
    var publisher = d.publishers[action.topic]
    if (!publisher || publisher.type !== action.messageType) {
      Ros2.error("Could not execute " + action.name + ": No available publisher! Did you register the robot action before execution?")
      return false
    }
    execution.state = RobotActionExecution.ExecutionState.Running
    publisher.publish(action.getParams())
    
    execution.state = RobotActionExecution.ExecutionState.Succeeded
    execution.progress = 1
    execution.active = false
    execution.executionFinished()
    return true
  }

  function cancel(execution) {
    if (!execution.active) return true
    Ros2.debug("Topics can not be canceled!")
    return false
  }

  function setup(action) {
    if (!action.messageType) {
      Ros2.error("Register failed! Publisher type is not set for RobotAction: " + action.name)
      return false
    }
    if (!action.topic) {
      Ros2.error("Register failed! Publisher topic is not set for RobotAction: " + action.name)
      return false
    }
    if (d.publishers[action.topic]) {
      if (d.publishers[action.topic].type === action.messageType) {
        d.publishers[action.topic].usageCount++
        return true
      }
      if (d.publishers[action.topic].usageCount > 0) {
        Ros2.error("Failed to create publisher with type '" + action.messageType + "' on '" + action.topic + "'. " +
                  "I already have a publisher of type '" + d.publishers[action.topic].type + "' on this topic!")
        return false
      }
    }
    d.publishers[action.topic] = Ros2.advertise(action.messageType, action.topic, 10, false)
    d.publishers[action.topic].usageCount = 1
    Ros2.debug("Advertised publisher for '" + action.messageType + "' on " + action.topic)
    return true
  }

  function free(action) {
    if (!action.messageType) {
      Ros2.error("Unregister failed! Publisher type is not set for RobotAction: " + action.name)
      return false
    }
    if (!action.topic) {
      Ros2.error("Unregister failed! Publisher topic is not set for RobotAction: " + action.name)
      return false
    }
    if (!d.publishers[action.topic]) {
      Ros2.warn("Tried to unregister publisher that is not registered.")
      return true // Warn but unregistering is successful if it wasn't registered in the first place.
    }
    if (d.publishers[action.topic].actionType === action.messageType) {
      d.publishers[action.topic].usageCount--
      return true
    }
    Ros2.warn("Tried to unregister topic that was not registered successfully.")
    return true
  }


  QtObject {
    id: d
    property var publishers: ({})
  }
}

