import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0
import "executionstates.js" as ExecutionStates

Object {

  function execute(action, execution) {
    var entry = d.actionClients[action.topic]
    if (!entry) {
      if (!setup(action)) {
        Ros2.error("Could not setup action client for " + action.name + " on topic " + action.topic)
        return false
      }
      entry = d.actionClients[action.topic]
    }
    var client = entry.client
    if (client.actionType !== action.messageType) {
      Ros2.error("Could not execute " + action.name + ": Action type mismatch! " +
                 "Action type is '" + action.messageType + "' but already existing client for this topic is of type '" + client.actionType + "'")
      return false
    }
    if (!client.ready) {
      Ros2.info("Action client not connected. Waiting for connection.")
      d.scheduleAction(client, action, execution)
    } else {
      d.sendActionGoal(client, action, execution)
    }
    return true
  }

  function cancel(execution) {
    if (!execution.active) return true
    let entry = d.actionClients[execution.action.topic]
    execution.state = RobotActionExecution.ExecutionState.Canceling
    if (!entry || !entry.client.ready || !execution.actionGoal) {
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
    let entry = d.actionClients[action.topic]
    if (entry) {
      if (entry.client.actionType === action.messageType) {
        entry.usageCount++
        return true
      }
      if (entry.usageCount > 0) {
        Ros2.error("Failed to create action client with type '" + action.messageType + "' on '" + action.topic + "'. " +
                  "I already have an action of type '" + entry.client.actionType + "' on this topic!")
        return false
      }
    }
    d.actionClients[action.topic] = {client: Ros2.createActionClient(action.topic, action.messageType), usageCount: 1}
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
    if (d.actionClients[action.topic].client.actionType === action.messageType) {
      d.actionClients[action.topic].usageCount--
      return true
    }
    Ros2.warn("Tried to unregister action that was not registered successfully.")
    return true
  }


  //! Grace period for the result response after the goal reached a terminal status.
  Component {
    id: resultTimeoutComponent
    Timer { interval: 5000 }
  }

  QtObject {
    id: d
    property var actionClients: ({})
    property var scheduledActions: []

    function statusToExecutionState(status) {
      if (status === ActionGoalStatus.Aborted)
        return RobotActionExecution.ExecutionState.Failed
      else if (status === ActionGoalStatus.Accepted)
        return RobotActionExecution.ExecutionState.Running
      else if (status === ActionGoalStatus.Canceled)
        return RobotActionExecution.ExecutionState.Canceled
      else if (status === ActionGoalStatus.Canceling)
        return RobotActionExecution.ExecutionState.Canceling
      else if (status === ActionGoalStatus.Executing)
        return RobotActionExecution.ExecutionState.Running
      else if (status === ActionGoalStatus.Succeeded)
        return RobotActionExecution.ExecutionState.Succeeded
      return RobotActionExecution.ExecutionState.Unknown
    }

    function sendActionGoal(client, action, execution) {
      d.removeScheduledAction(action) // No-op if not scheduled
      let resultTimeout = null

      function finish(state) {
        if (resultTimeout !== null) {
          resultTimeout.destroy()
          resultTimeout = null
        }
        // Already finished, e.g., because it was force canceled, or already destroyed
        if (!execution || !execution.active) return
        // An execution that ends without a terminal state, e.g. with an unknown result code, would
        // be indistinguishable from one that never ran, so report it as a failure.
        if (!ExecutionStates.isTerminal(state)) state = RobotActionExecution.ExecutionState.Failed
        execution.state = state
        if (state === RobotActionExecution.ExecutionState.Succeeded) {
          execution.progress = 1
        }
        execution.active = false
        execution.executionFinished()
      }

      execution.actionGoal = client.sendGoalAsync(action.getParams(), {
        onGoalResponse(goal) {
          if (goal == null) {
            finish(RobotActionExecution.ExecutionState.Failed)
            return
          }
          function onGoalStatusChanged() {
            if (!execution || !execution.active) return
            let state = d.statusToExecutionState(goal.status)
            if (!ExecutionStates.isTerminal(state)) {
              if (state === RobotActionExecution.ExecutionState.Unknown) return
              // Once canceling, don't fall back to running until the goal reaches a terminal state
              if (execution.state === RobotActionExecution.ExecutionState.Canceling) return
              execution.state = state
              return
            }
            // The goal status and the result response are independent, so the result may still be
            // outstanding. Wait for it since it carries the result message but do not stay active
            // forever if it never arrives.
            if (resultTimeout !== null) return
            resultTimeout = resultTimeoutComponent.createObject(null)
            resultTimeout.triggered.connect(function () {
              Ros2.warn("No result received for action '" + action.name + "' after the goal reached a " +
                        "terminal state. Finishing execution based on the goal status.")
              finish(state)
            })
            resultTimeout.start()
          }
          goal.statusChanged.connect(onGoalStatusChanged)
          onGoalStatusChanged() // In case the goal already reached a terminal state
        },
        onFeedback(goal, feedback) {
          // Feedback may still arrive after the execution was destroyed
          if (!execution) return
          execution.feedback(feedback)
        },
        onResult(result) {
            try { execution.result(result.result) } catch (e) {}
            Ros2.debug("Action result received: " + result.code)
            finish(d.statusToExecutionState(result.code))
        }
      })
      if (!execution.actionGoal) {
        // Without a goal handle the goal was never sent, e.g. because the params did not match the
        // action type, and none of the callbacks above will ever be invoked.
        Ros2.error("Could not send goal for action '" + action.name + "' on topic '" + action.topic + "'!")
        finish(RobotActionExecution.ExecutionState.Failed)
        return
      }
      execution.state = RobotActionExecution.ExecutionState.Running
    }

    function scheduleAction(client, action, execution) {
      var callback = function () {
        Ros2.info("Action client for " + action.name + " on topic " + action.topic + " is ready. Sending goal.")
        d.removeScheduledAction(action)
        d.sendActionGoal(client, action, execution)
      }
      client.onServerReadyChanged.connect(callback)
      actionClientConnectionTimer.running = true
      scheduledActions.push({client: client, action: action, execution: execution, callback: callback, start: new Date()})
    }

    function removeScheduledAction(action) {
      for (var i = 0; i < d.scheduledActions.length; ++i) {
        if (d.scheduledActions[i].action.uuid === action.uuid) {
          d.scheduledActions[i].client.onServerReadyChanged.disconnect(d.scheduledActions[i].callback)
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
        const now = new Date()
        for (let i = d.scheduledActions.length - 1; i >= 0; --i) {
          let scheduled = d.scheduledActions[i]
          if (scheduled.client.ready) {
            // sendActionGoal deschedules (and disconnects) the entry itself
            d.sendActionGoal(scheduled.client, scheduled.action, scheduled.execution)
            continue
          }
          if (now - scheduled.start < 10000) continue

          Ros2.warn("Timeout while waiting for action client to connect:" + scheduled.action.topic)
          scheduled.client.onServerReadyChanged.disconnect(scheduled.callback)
          scheduled.execution.state = RobotActionExecution.ExecutionState.Timeout
          scheduled.execution.active = false
          scheduled.execution.executionFinished()
          d.scheduledActions.splice(i, 1)
        }
      }
    }
  }
}

