import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {

  function execute(action, execution) {
    execution.state = RobotActionExecution.ExecutionState.Running
    d.client.sendRequestAsync(action.getParams(), function (result) {
      try { execution.result(result) } catch (e) { Ros2.error("Handling service result failed: " + e) }
      
      let state = result === false ? RobotActionExecution.ExecutionState.Failed : RobotActionExecution.ExecutionState.Succeeded

      // Mark execution done if it wasn't canceled in the mean time
      if (!execution.active) return
      execution.state = state
      execution.progress = result === false ? 0 : 1
      execution.active = false
      execution.executionFinished()
    })
    return true
  }

  function cancel(execution) {
    if (!execution.active) return true
    Ros2.debug("Services can not be canceled!")
    return false
  }

  function setup(action) {
    if (d.client && d.client.name == action.topic && d.client.type == action.messageType) return true
    d.client = Ros2.createServiceClient(action.topic, action.type)
    return true
  }

  function free(action) {
    d.client == null
    return true
  }


  QtObject {
    id: d
    property var client
  }
}

