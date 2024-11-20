import QtQuick 2.3
import Ros 1.0

Object {
  property RobotAction action: RobotAction { type: "none" }
  enum ExecutionState {
    Unknown,
    //! The execution is currently waiting to start (e.g. if the action client is still connecting)
    Waiting,
    Running,
    Canceling,
    Timeout,
    Failed,
    Canceled,
    Succeeded,
    PartialFailure
  }
  property int state: RobotActionExecution.ExecutionState.Waiting
  //! Indicates whether the action is currently executing.
  //! Once active changes to false, whether the action finished or was canceled can be obtained by checking the execution state.
  property bool active: true
  //! Progress is false if not available, otherwise a floating point number from 0 to 1 (0 to 100%) or an array
  //! of two floating point numbers representing a lower and upper bound of the progress
  property var progress: false
  //! For action robot actions
  property var actionGoal: null
  //! For composites and toggle actions
  property var subexecutions: []
  //! Indicates if it's an anonymous execution, e.g., the execution of a subaction, and should not be displayed
  property bool anonymous: false
  signal feedback(var feedback)
  signal result(var result)
  signal executionFinished()

  property string statusText: {
    if (action && action.type && ["composite", "toggle"].includes(action.type)) {
      if (subexecutions.length !== 1) return ""
      return "Executing: " + subexecutions[0].action.name
    }
    if (state === RobotActionExecution.ExecutionState.Waiting) return "Waiting to start..."
    if (state === RobotActionExecution.ExecutionState.Canceling) return "Canceling..."
    if (state === RobotActionExecution.ExecutionState.Timeout) return "Timeout while executing!"
    if (state === RobotActionExecution.ExecutionState.Failed) return "Execution failed!"
    if (state === RobotActionExecution.ExecutionState.PartialFailure) return "Partial execution failure!"
    if (state === RobotActionExecution.ExecutionState.Canceled) return "Execution canceled."
    if (state === RobotActionExecution.ExecutionState.Succeeded) return "Execution finished."
    return ""
  }
}
