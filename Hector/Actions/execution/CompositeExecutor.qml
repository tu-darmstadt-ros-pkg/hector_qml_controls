import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

Object {

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
      successful &= RobotActionExecutionManager.cancel(execution.subexecutions[i].action, force)
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
        let subaction = RobotActionManager.getAction(action.subactions[i].action)
        Ros2.debug("Executing subaction: " + subaction.name)
        let subexecution = RobotActionExecutionManager.execute(subaction, true)
        if (!subexecution) {
          count_done++
          continue
        }
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
      let subaction = RobotActionManager.getAction(action.subactions[index].action)
      Ros2.debug("Executing subaction: " + subaction.name)
      let subexecution = RobotActionExecutionManager.execute(subaction, true)
      execution.subexecutions = [subexecution]
      execution.progress = [index / action.subactions.length, (index + 1) / action.subactions.length]
      let executedNext = false
      function executeNextSubaction() {
        if (executedNext) return
        executedNext = true
        executeSequentialAction(action, execution, index+1)
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

