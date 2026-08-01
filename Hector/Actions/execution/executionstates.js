//! Helpers to interpret the RobotActionExecution.ExecutionState of one or more executions.
//! Importing documents need RobotActionExecution in scope, i.e. they have to import Hector.Actions.
const ExecutionState = RobotActionExecution.ExecutionState

//! True for states that are a result, i.e. that indicate the execution is over.
function isTerminal(state) {
  switch (state) {
    case ExecutionState.Timeout:
    case ExecutionState.Failed:
    case ExecutionState.Canceled:
    case ExecutionState.Succeeded:
    case ExecutionState.PartialFailure:
      return true
  }
  return false
}

//! True for states that indicate the execution is still going, i.e. that are not a result.
function isPending(state) {
  switch (state) {
    case ExecutionState.Waiting:
    case ExecutionState.Running:
    case ExecutionState.Canceling:
      return true
  }
  return false
}

//! Ranks execution states by relevance for a summary of multiple executions.
//! States of running executions rank above results and more severe results rank above less severe
//! ones, so the highest ranked state of a set of executions is the one worth showing.
function rank(state) {
  switch (state) {
    case ExecutionState.Running: return 8
    case ExecutionState.Canceling: return 7
    case ExecutionState.Waiting: return 6
    case ExecutionState.Failed: return 5
    case ExecutionState.Timeout: return 4
    case ExecutionState.PartialFailure: return 3
    case ExecutionState.Canceled: return 2
    case ExecutionState.Succeeded: return 1
  }
  return 0
}
