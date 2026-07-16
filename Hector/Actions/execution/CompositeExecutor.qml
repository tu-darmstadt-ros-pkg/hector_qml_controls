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
      d.executeSequential(action, execution)
    }
    return true
  }

  function cancel(execution, force) {
    if (!execution.active) return true
    execution.state = RobotActionExecution.ExecutionState.Canceling
    let successful = true
    // Snapshot: canceling a subexecution can finish it synchronously, which splices
    // subexecutions mid-iteration (see onSubexecutionFinished) and would skip entries.
    for (let subexecution of execution.subexecutions.slice()) {
      if (!subexecution.active) continue // Already finished, nothing to cancel
      successful = actionManager.cancel(subexecution.action, force) && successful
    }
    return successful
  }

  function setup(action) {
    // An empty composite is a valid no-op: it may be registered before its subactions are populated
    // (e.g. a "Drive to waypoints" action registered up front, then filled in as waypoints are added).
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
      if (action.subactions.length === 0) {
        d.setExecutionFinished(execution, state)
        return
      }
      for(let i = 0; i < action.subactions.length; i++) {
        // Pass the subaction reference (uuid or inline action object) straight to execute,
        // which registers inline actions on demand. See ToggleExecutor for the same pattern.
        let subexecution = actionManager.execute(action.subactions[i].action, true)
        if (!subexecution) {
          // Subaction could not be started — count it as done but report partial failure
          state = RobotActionExecution.ExecutionState.PartialFailure
          count_done++
          execution.progress = [count_done / action.subactions.length, 1]
          if (count_done >= action.subactions.length) {
            d.setExecutionFinished(execution, state)
          }
          continue
        }
        Ros2.debug("Executing subaction: " + subexecution.action.name)
        let finishHandled = false
        function onSubexecutionFinished() {
          if (finishHandled) return
          finishHandled = true
          // If any subaction didn't succeed, the overall result is a partial failure.
          if (subexecution.state !== RobotActionExecution.ExecutionState.Succeeded) {
            state = RobotActionExecution.ExecutionState.PartialFailure
          }
          // Release the reference — the manager destroys finished executions, so keeping it
          // in subexecutions would leave a dangling entry for cancel() to trip over.
          let subIndex = execution.subexecutions.indexOf(subexecution)
          if (subIndex !== -1) {
            execution.subexecutions.splice(subIndex, 1)
            execution.subexecutionsChanged()
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

    //! @param state Tracks the current index and how many actions have failed
    function executeSequential(action, execution, state) {
      if (!state) state = {}
      if (!state.index) state.index = 0
      if (!state.failed) state.failed = 0
      if (execution.state === RobotActionExecution.ExecutionState.Canceling) {
        d.setExecutionFinished(execution, RobotActionExecution.ExecutionState.Canceled)
        return
      }
      if (state.index >= action.subactions.length) {
        d.setExecutionFinished(execution, state.failed > 0 ? RobotActionExecution.ExecutionState.PartialFailure
                                                           : RobotActionExecution.ExecutionState.Succeeded)
        return
      }
      let subexecution = actionManager.execute(action.subactions[state.index].action, true)
      if (!subexecution) {
        // Could not start this subaction (e.g. unknown uuid). Without continueOnError fail the whole
        // sequence rather than silently skipping it and reporting success.
        if (action.continueOnError) {
          state.index += 1
          state.failed += 1
          executeSequential(action, execution, state)
          return
        }
        d.setExecutionFinished(execution, RobotActionExecution.ExecutionState.Failed)
        return
      }
      Ros2.debug("Executing subaction: " + subexecution.action.name)
      execution.subexecutions = [subexecution]
      execution.progress = [state.index / action.subactions.length, (state.index + 1) / action.subactions.length]
      let executedNext = false
      function executeNextSubaction() {
        if (executedNext) return
        executedNext = true
        let succeeded = subexecution.state === RobotActionExecution.ExecutionState.Succeeded
        // Without continueOnError, stop and propagate the failure instead of advancing (and reporting
        // success) when a subaction didn't succeed, e.g. the server rejected or aborted the goal.
        if (!succeeded && !action.continueOnError) {
          d.setExecutionFinished(execution, subexecution.state)
          return
        }
        state.index += 1
        state.failed += (succeeded ? 0 : 1)
        executeSequential(action, execution, state)
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

