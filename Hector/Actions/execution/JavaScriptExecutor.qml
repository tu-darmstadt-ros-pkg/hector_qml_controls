import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {

  function execute(action, execution) {
    execution.state = RobotActionExecution.ExecutionState.Running
    if (typeof action.params === 'function') action.params()
    else eval('(function () {' + action.params + '})()')
    execution.state = RobotActionExecution.ExecutionState.Succeeded
    execution.progress = 1
    execution.active = false
    execution.executionFinished()
    return true
  }

  function cancel(execution) {
    if (!execution.active) return true
    Ros2.debug("JavaScript can not be canceled!")
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

