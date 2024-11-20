import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {

  function execute(action, execution) {
    var client = d.actionClients[action.topic]
    if (!client || client.actionType !== action.messageType) {
      Ros2.error("Could not execute " + action.name + ": No available client! Did you register the robot action before execution?")
      return false
    }
    if (!client.connected) {
      Ros2.info("Action client not connected. Waiting for connection.")
      d.scheduleAction(client, action, execution)
    } else {
      d.sendActionGoal(client, action, execution)
    }
    return true
  }

  function cancel(execution) {
    if (!execution.active) return true
    let client = d.actionClients[execution.action.topic]
    execution.state = RobotActionExecution.ExecutionState.Canceling
    if (!client.connected || !execution.actionGoal) {
      d.removeScheduledAction(execution.action)
      
      execution.state = RobotActionExecution.ExecutionState.Canceled
      execution.active = false
      execution.executionFinished()
      return true
    }
    execution.actionGoal.cancel()
    return true
  }

  function setup(action) {
    if (!action.messageType) {
      Ros2.error("Register failed! Action type is not available for RobotAction: " + action.name)
      return false
    }
    if (!action.topic) {
      Ros2.error("Register failed! Action topic is not available for RobotAction: " + action.name)
      return false
    }
    if (d.actionClients[action.topic]) {
      if (d.actionClients[action.topic].actionType === action.messageType) {
        d.actionClients[action.topic].usageCount++
        return true
      }
      if ( d.actionClients[action.topic].usageCount > 0 ) {
        Ros2.error("Failed to create action client with type '" + action.messageType + "' on '" + action.topic + "'. " +
                  "I already have an action of type '" + d.actionClients[action.topic].actionType + "' on this topic!")
        return false
      }
    }
    d.actionClients[action.topic] = Ros2.createActionClient(action.messageType, action.topic)
    d.actionClients[action.topic].usageCount = 1
    Ros2.debug("Created action client for '" + action.messageType + "' on " + action.topic)
    return true
  }

  function free(action) {
    if (!action.messageType) {
      Ros2.error("Unregister failed! Action type is not available for RobotAction: " + action.name)
      return false
    }
    if (!action.topic) {
      Ros2.error("Unregister failed! Action topic is not available for RobotAction: " + action.name)
      return false
    }
    if (!d.actionClients[action.topic]) {
      Ros2.warn("Tried to unregister action that is not registered.")
      return true // Warn but unregistering is successful if it wasn't registered in the first place.
    }
    if (d.actionClients[action.topic].actionType === action.messageType) {
      d.actionClients[action.topic].usageCount--
      return true
    }
    Ros2.warn("Tried to unregister action that was not registered successfully.")
    return true
  }


  QtObject {
    id: d
    property var actionClients: ({})
    property var scheduledActions: []

    function sendActionGoal(client, action, execution) {
      d.removeScheduledAction(action) // No-op if not scheduled
      execution.actionGoal = client.sendGoal(action.getParams(), function (goal) {
          if (goal.commState === ActionCommStates.DONE) {
            try { execution.result(goal.getResult()) } catch (e) {}
            let state = RobotActionExecution.ExecutionState.Unknown
            if (goal.terminalState.state === ActionTerminalStates.RECALLED)
              state = RobotActionExecution.ExecutionState.Canceled
            else if (goal.terminalState.state === ActionTerminalStates.REJECTED)
              state = RobotActionExecution.ExecutionState.Failed
            else if (goal.terminalState.state === ActionTerminalStates.PREEMPTED)
              state = RobotActionExecution.ExecutionState.Canceled
            else if (goal.terminalState.state === ActionTerminalStates.ABORTED)
              state = RobotActionExecution.ExecutionState.Failed
            else if (goal.terminalState.state === ActionTerminalStates.SUCCEEDED)
              state = RobotActionExecution.ExecutionState.Succeeded

            // Mark execution done if it wasn't canceled in the mean time
            if (!execution.active) return
            execution.state = state
            if (state === RobotActionExecution.ExecutionState.Succeeded) {
              execution.progress = 1
            }
            execution.active = false
            execution.executionFinished()
          }
        },
        function (goal, feedback) { execution.feedback(feedback) }
      )
      execution.state = RobotActionExecution.ExecutionState.Running
    }

    function scheduleAction(client, action, execution) {
      var callback = function () {
        d.removeScheduledAction(action)
        d.sendActionGoal(client, action, execution)
      }
      client.onConnectedChanged.connect(callback)
      actionClientConnectionTimer.running = true
      scheduledActions.push({client: client, action: action, execution: execution, callback: callback, start: new Date()})
    }

    function removeScheduledAction(action) {
      for (var i = 0; i < d.scheduledActions.length; ++i) {
        if (d.scheduledActions[i].action.uuid === action.uuid) {
          d.scheduledActions[i].client.onConnectedChanged.disconnect(d.scheduledActions[i].callback)
          d.scheduledActions.splice(i, 1)
          return
        }
      }
    }

    property Timer actionClientConnectionTimer: Timer {
      id: actionClientConnectionTimer
      interval: 100
      repeat: true
      onTriggered: {
        if (d.scheduledActions.length === 0) {
          running = false
          return
        }
        var now = new Date()
        for (var i = d.scheduledActions.length - 1; i >= 0; --i) {
          var scheduled = d.scheduledActions[i]
          if (scheduled.client.connected) {
            d.sendActionGoal(scheduled.client, scheduled.action, scheduled.execution)
            d.scheduledActions.splice(i, 1)
            continue
          }
          if (now - scheduled.start < 10000) continue

          Ros2.warn("Timeout while waiting for action client to connect:" + scheduled.action.topic)
          scheduled.client.onConnectedChanged.disconnect(scheduled.callback)
          scheduled.execution.state = RobotActionExecution.ExecutionState.Timeout
          scheduled.execution.active = false
          scheduled.execution.executionFinished()
          d.scheduledActions.splice(i, 1)
        }
      }
    }
  }
}

