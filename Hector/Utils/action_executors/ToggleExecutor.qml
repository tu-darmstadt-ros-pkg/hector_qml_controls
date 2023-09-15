import QtQuick 2.3
import Ros 1.0
import ".."

Object {

  function execute(action, execution) {
    execution.state = RobotActionExecution.ExecutionState.Running
    if (action._activeIndex == undefined) {
      Ros.warn("RobotActionExecutionManager: State of action '" + action.name + "' is not yet known. Assuming in state 0.")
    }
    
    let next = action._activeIndex == undefined ? 1 : action._activeIndex + 1
    if (next == action.subactions.length) next = 0
    let subexecution = RobotActionExecutionManager.execute(action.subactions[next].action, true)
    if (!subexecution) return false
    execution.subexecutions.push(subexecution)
    execution.subexecutionsChanged()

    function onFinished() {
      if (!execution.active) return
      execution.state = subexecution.state
      execution.active = false
      execution.executionFinished()
      if (action.topic || subexecution.state != RobotActionExecution.ExecutionState.Succeeded) return
      // If we don't have a state topic, we assume the state switched if successful
      action._activeIndex = next
    }
    
    subexecution.executionFinished.connect(onFinished)
    if (!subexecution.active) onFinished()
    return true
  }

  function cancel(execution, force) {
    if (!execution.active) return True
    execution.state = RobotActionExecution.ExecutionState.Canceling
    return RobotActionExecutionManager.cancel(execution.subexecutions[0].action, force)
  }

  function setup(action) {
    if (action.subactions.length == 0) {
      Ros.error("Register failed! No subactions for toggle RobotAction: " + action.name)
      return false
    }
    if (!action.topic) {
        // No feedback topic, set active index unless it was already set
        if (!action._activeIndex) action._activeIndex = 0
        return true
    }
    try {
      if (!d.subscribers[action.topic]) {
        d.subscribers[action.topic] = Ros.subscribe(action.topic, 10)
      }
      const parser = new Function("msg", action.params)
      function updateIndex(msg) {
        let next = msg && parser(msg)
        if (next == null) {
          next = action._activeIndex == undefined ? 1 : action._activeIndex + 1
        }
        action._activeIndex = next
      }
      d.subscribers[action.topic].newMessage.connect(updateIndex)
      if (!!d.subscribers[action.topic].message) updateIndex(d.subscribers[action.topic].message)
      return true
    } catch (e) {
      Ros.error("Failed to register action: " + e + "\nStack:\n---\n" + e.stack)
      return false
    }
    return true
  }

  function free(action) {
    return true
  }


  QtObject {
    id: d
    property var subscribers: ({})
  }
}

