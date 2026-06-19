import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {
  property var actionManager

  function execute(action, execution) {
    execution.state = RobotActionExecution.ExecutionState.Running
    if (action.parallel) {
      d.executeParallel(action, execution)
    } else {
      d.executeSequential(action, execution, 0)
    }
    return true
  }

  function cancel(execution, force) {
    if (!execution.active) return true
    execution.state = RobotActionExecution.ExecutionState.Canceling
    let successful = true
    for(var i = 0; i < execution.subexecutions.length; i++) {
      successful &= actionManager.cancel(execution.subexecutions[i].action, force)
    }
    return successful
  }

  function setup(action) {
    if (action.subactions.length == 0) {
      Ros2.error("Register failed! No subactions for composite RobotAction: " + action.name)
      return false
    }
    return true
  }

  function free(action) {
    return true
  }


  QtObject {
    id: d

    function executeParallel(action, execution) {
      let count_done = 0
      let state = RobotActionExecution.ExecutionState.Succeeded
      for(let i = 0; i < action.subactions.length; i++) {
        // Pass the subaction reference (uuid or inline action object) straight to execute,
        // which registers inline actions on demand. See ToggleExecutor for the same pattern.
        let subexecution = actionManager.execute(action.subactions[i].action, true)
        if (!subexecution) {
          count_done++
          continue
        }
        Ros2.debug("Executing subaction: " + subexecution.action.name)
        let finishHandled = false
        function onSubexecutionFinished() {
          if (finishHandled) return
          finishHandled = true
          // Use any non succeeded state but failed will override other states
          if (state !== RobotActionExecution.ExecutionState.Succeeded) {
            state = RobotActionExecution.ExecutionState.PartialFailure
          }
          count_done++
          execution.progress = [count_done / action.subactions.length, 1]
          if (count_done >= action.subactions.length) {
            d.setExecutionFinished(execution, state)
          }
        }

        execution.subexecutions.push(subexecution)
        execution.subexecutionsChanged()
        subexecution.executionFinished.connect(onSubexecutionFinished)
        if (!subexecution.active) {   // action's already finished
          onSubexecutionFinished() 
        }
      }
    }

    function executeSequential(action, execution, index) {
      if (execution.state === RobotActionExecution.ExecutionState.Canceling) {
        d.setExecutionFinished(execution, RobotActionExecution.ExecutionState.Canceled)
        return
      }
      if (index >= action.subactions.length) {
        d.setExecutionFinished(execution, RobotActionExecution.ExecutionState.Succeeded)
        return
      }
      let subexecution = actionManager.execute(action.subactions[index].action, true)
      if (!subexecution) {
        // Could not start this subaction (e.g. unknown uuid) — fail the whole sequence
        // rather than silently skipping it and reporting success.
        d.setExecutionFinished(execution, RobotActionExecution.ExecutionState.Failed)
        return
      }
      Ros2.debug("Executing subaction: " + subexecution.action.name)
      execution.subexecutions = [subexecution]
      execution.progress = [index / action.subactions.length, (index + 1) / action.subactions.length]
      let executedNext = false
      function executeNextSubaction() {
        if (executedNext) return
        executedNext = true
        executeSequential(action, execution, index+1)
      }

      subexecution.executionFinished.connect(executeNextSubaction)
      if (!subexecution.active) {
        // in case the action finished before the slot is connected
        executeNextSubaction()
      }
    }

    function setExecutionFinished(execution, state) {
      if (!execution.active) return
      execution.active = false
      execution.state = state
      if (state === RobotActionExecution.ExecutionState.Succeeded) {
        execution.progress = 1
      }
      execution.executionFinished()
    }
  }
}

