import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {
  property var actionManager

  function execute(action, execution) {
    execution.state = RobotActionExecution.ExecutionState.Running
    if (action._activeIndex == undefined) {
      Ros2.warn("RobotActionManager: State of action '" + action.name + "' is not yet known. Assuming in state 0.")
    }
    
    let next = action._activeIndex == undefined ? 1 : action._activeIndex + 1
    if (next == action.subactions.length) next = 0
    let subexecution = actionManager.execute(action.subactions[next].action, true)
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
    if (!execution.active) return true
    execution.state = RobotActionExecution.ExecutionState.Canceling
    return actionManager.cancel(execution.subexecutions[0].action, force)
  }

  function setup(action) {
    if (action.subactions.length == 0) {
      Ros2.error("Register failed! No subactions for toggle RobotAction: " + action.name)
      return false
    }
    if (!action.topic) {
        // No feedback topic, set active index unless it was already set
        if (!action._activeIndex) action._activeIndex = 0
        return true
    }
    try {
      if (!d.subscribers[action.topic]) {
        d.subscribers[action.topic] = {subscriber: Ros2.createSubscription(action.topic, 10), handlers: ({})}
      }
      let entry = d.subscribers[action.topic]
      if (entry.handlers[action.uuid]) return true // Already set up for this action
      const parser = new Function("msg", action.params)
      function updateIndex(msg) {
        let next = msg && parser(msg)
        if (next == null) {
          next = action._activeIndex == undefined ? 1 : action._activeIndex + 1
        }
        action._activeIndex = next
      }
      entry.subscriber.newMessage.connect(updateIndex)
      entry.handlers[action.uuid] = updateIndex
      if (!!entry.subscriber.message) updateIndex(entry.subscriber.message)
      return true
    } catch (e) {
      Ros2.error("Failed to register action: " + e + "\nStack:\n---\n" + e.stack)
      return false
    }
  }

  function free(action) {
    if (!action.topic) return true
    let entry = d.subscribers[action.topic]
    if (!entry || !entry.handlers[action.uuid]) return true
    entry.subscriber.newMessage.disconnect(entry.handlers[action.uuid])
    delete entry.handlers[action.uuid]
    return true
  }


  QtObject {
    id: d
    property var subscribers: ({})
  }
}

