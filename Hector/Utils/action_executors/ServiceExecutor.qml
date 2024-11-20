import QtQuick 2.3
import Ros 1.0
import ".."

Object {

  function execute(action, execution) {
    execution.state = RobotActionExecution.ExecutionState.Running
    Service.callAsync(action.topic, action.messageType, action.getParams(), function (result) {
      try { execution.result(result) } catch (e) { Ros.error("Handling service result failed: " + e) }
      
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
    Ros.debug("Services can not be canceled!")
    return false
  }

  function setup(action) {
    return true
  }

  function free(action) {
    return true
  }


  QtObject {
    id: d
  }
}

