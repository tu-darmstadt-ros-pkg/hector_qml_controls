pragma Singleton
import QtQuick 2.3
import QtQuick.Controls 2.2
import Ros 1.0
import "."
import "action_executors"

Object {
  id: root
  readonly property var activeExecutions: d.activeExecutions.filter(x => !x.anonymous)
  signal executionStarted(string uuid, RobotActionExecution execution)

  function getExecution(action_or_uuid) {
    if (!action_or_uuid) return null
    let uuid = typeof action_or_uuid === 'string' ? action_or_uuid : action_or_uuid.uuid
    if (!uuid) return null
    for (let execution of d.activeExecutions) {
      if (execution.action.uuid === uuid) {
        return execution
      }
    }
    return null
  }

  //! Executes the given action. Note that it will retrieve the action from the RobotActionManager.
  //! Hence, if the passed action differs from the action registered with the RobotActionManager,
  //! the changes will not be reflected.
  //! @param anonymous If anonymous is true, the execution will be created as anonymous
  function execute(action_or_uuid, anonymous=false) {
    var execution = null
    try {
      // Get the action from the RobotActionManager since that object will not be destroyed during execution
      // which is not guaranteed for the passed object
      let uuid = typeof action_or_uuid === 'string' ? action_or_uuid : action_or_uuid.uuid
      let action = RobotActionManager.getAction(uuid)
      if (action == null) {
        Ros.error("Could not execute action as it was not registered with the RobotActionManager! This is necessary to ensure the object won't be destroyed during execution.")
        return false
      }
      Ros.debug("Execute action " + action.name + "...")
      var execution = getExecution(action)
      if (execution !== null) {
        if (execution.active) {
          Ros.error("Could not execute " + action.name + " since it is already running!")
          return false
        }
        // When executing again, remove finished execution
        d.removeExecution(execution)
      }
      
      execution = executionComponent.createObject(d, {active: true, state: RobotActionExecution.ExecutionState.Waiting, action: action})
      execution.anonymous = anonymous || action.anonymous || false
      d.addExecution(execution)
      executionStarted(action.uuid, execution)
      let startedSuccessfully = true
      switch (action.type) {
        case 'action':
          startedSuccessfully = d.actionExecutor.execute(action, execution)
          break
        case 'composite':
          startedSuccessfully = d.compositeExecutor.execute(action, execution)
          break
        case 'javascript':
          startedSuccessfully = d.javascriptExecutor.execute(action, execution)
          break
        case 'service':
          startedSuccessfully = d.serviceExecutor.execute(action, execution)
          break
        case 'topic':
          startedSuccessfully = d.topicExecutor.execute(action, execution)
          break
        case "toggle":
          startedSuccessfully = d.toggleExecutor.execute(action, execution)
          break
      }
      if (!startedSuccessfully) {
        execution.state = RobotActionExecution.ExecutionState.Failed
        execution.active = false
        execution.executionFinished()
      }
      return execution
    } catch (e) {
      Ros.error("RobotActionExecutionManager: Executing robot action failed: " + e + "\nStack:\n---\n" + e.stack)
      if (execution) {
        execution.state = RobotActionExecution.ExecutionState.Failed
        execution.active = false
        execution.executionFinished()
      }
      return false
    }
  }

  /*!
   *  Cancels the given action.
   *  @param action_or_uuid The action or the uuid of the action that is canceled
   *  @param force If true, don't wait for a response before setting the execution to canceled. Default: false
   *  @return True if canceled successfully, false otherwise
   */
  function cancel(action_or_uuid, force = false) {
    try {
      let uuid = typeof action_or_uuid === 'string' ? action_or_uuid : action_or_uuid.uuid
      var execution = getExecution(uuid)
      if (execution == null) {
        let name = typeof action_or_uuid === 'string' ? "action with uuid " + uuid : action_or_uuid.name
        Ros.error("Could not cancel " + name + "! No active execution found.")
        return false
      }
      Ros.debug("Canceling robot action '" + execution.action.name + "' with uuid: " + uuid)
      if (!execution.active) return false // No need to cancel
      let result = true
      switch (execution.action.type) {
        case 'action':
          result = d.actionExecutor.cancel(execution, force)
          break
        case 'composite':
          result = d.compositeExecutor.cancel(execution, force)
          break
        case 'javascript':
          result = d.javascriptExecutor.cancel(execution, force)
          break
        case 'service':
          result = d.serviceExecutor.cancel(execution, force)
          break
        case 'toggle':
          result = d.toggleExecutor.cancel(execution, force)
          break
        case 'topic':
          result = d.topicExecutor.cancel(execution, force)
          break
      }
      if (!force || !execution.active) return result

      // Might still be running but we force cancelation
      execution.state = RobotActionExecution.ExecutionState.Canceled
      execution.active = false
      execution.executionFinished()
      return result
    } catch (e) {
      Ros.error("RobotActionExecutionManager: Canceling robot action failed: " + e + "\nStack:\n---\n" + e.stack)
      return false
    }
  }

  //! Internal function to set up action for later execution
  function _setupAction(action) {
    try {
      switch (action.type) {
      case 'action':
        return d.actionExecutor.setup(action)
      case 'composite':
        return d.compositeExecutor.setup(action)
      case 'javascript':
        return d.javascriptExecutor.setup(action)
      case 'service':
        return d.serviceExecutor.setup(action)
      case 'toggle':
        return d.toggleExecutor.setup(action)
      case 'topic':
        return d.topicExecutor.setup(action)
      case 'none':
        return true
      default:
        Ros.warn("Register failed! Unsupported action: " + JSON.stringify(action))
        return false
      }
    } catch (e) {
      Ros.error("Failed to register action: " + e + "\nStack:\n---\n" + e.stack)
      return false
    }
  }

  //! Internal function to free resources for reuse
  function _freeResources(action) {
    try {
      switch (action.type) {
      case 'action':
        return d.actionExecutor.free(action)
      case 'composite':
        return d.compositeExecutor.free(action)
      case 'javascript':
        return d.javascriptExecutor.free(action)
      case 'service':
        return d.serviceExecutor.free(action)
      case 'toggle':
        return d.toggleExecutor.free(action)
      case 'topic':
        return d.topicExecutor.free(action)
      case 'none':
        return true
      default:
        Ros.warn("Unregister failed! Unsupported action: " + JSON.stringify(action))
        return false
      }
    } catch (e) {
      Ros.error("Failed to unregister action: " + e + "\nStack:\n---\n" + e.stack)
      return false
    }
  }

  Component {
    id: executionComponent
    RobotActionExecution {}
  }

  Component {
    id: delayTimerComponent
    Timer { interval: 5000 }
  }

  QtObject {
    id: d
    property var activeExecutions: []
    property ActionExecutor actionExecutor: ActionExecutor {}
    property CompositeExecutor compositeExecutor: CompositeExecutor {}
    property JavaScriptExecutor javascriptExecutor: JavaScriptExecutor {}
    property ServiceExecutor serviceExecutor: ServiceExecutor {}
    property ToggleExecutor toggleExecutor: ToggleExecutor {}
    property TopicExecutor topicExecutor: TopicExecutor {}

    function addExecution(execution) {
      d.activeExecutions.push(execution)
      let delay = delayTimerComponent.createObject(null)
      delay.triggered.connect(function() {
        removeExecution(execution)
        delay.destroy()
      })
      execution.executionFinished.connect(delay.start)
      if (!execution.active) delay.start()
      if (!execution.anonymous) d.activeExecutionsChanged()
    }

    function removeExecution(execution) {
      var index = d.activeExecutions.indexOf(execution)
      if (index === -1) return
      d.activeExecutions.splice(index, 1)
      if (!execution.anonymous) d.activeExecutionsChanged()
    }
  }
}
