import QtQuick 2.3
import QtQuick.Controls 2.2
import Ros2 1.0
import Hector.Utils 1.0
import "execution"

Object {
  id: root
  signal actionRegistered(RobotAction action)
  signal actionUnregistered(RobotAction action)
  signal actionUpdated(RobotAction action)
  signal executionStarted(string uuid, RobotActionExecution execution)

  readonly property var activeExecutions: d.activeExecutions.filter(x => !x.anonymous)

  function getAction(uuid) {
    if (!uuid) return null
    let entry = d.actions[uuid]
    if (entry && entry._registerCount > 0) return entry.action
    return null
  }

  function registerAction(action) {
    if (action == null) {
      try {
        throw new Error("Tried to register null as action!")
      } catch (e) {
        Ros2.error("RobotActionManager: " + e.message + "\nStack:\n---\n" + e.stack)
      }
      return false
    }
    if (!action.uuid) action.uuid = Uuid.generate()
    let entry = d.actions[action.uuid]
    if (entry && entry.action.equals(action)) {
      entry._registerCount++
      return true
    }
    if (entry && entry._registerCount > 0) {
      // Active references exist — update in-place to preserve shared pointers
      Ros2.warn("Registered a different action with the same uuid '" + action.uuid + "'. " +
                "Use updateAction() instead. Updating in-place to preserve references.")
      _applyProperties(entry.action, action)
      entry._registerCount++
      actionUpdated(entry.action)
      return true
    }
    // No active references (or no entry) — safe to create new
    let newAction = _createAction(action)
    if (entry) {
      entry.action.destroy()
    }
    d.actions[action.uuid] = {_registerCount: 1, action: newAction}
    actionRegistered(newAction)
    return true
  }

  function updateAction(action) {
    let entry = d.actions[action.uuid]
    if (!entry) return false
    if (entry._locked) return false
    if (action !== entry.action) {
      _applyProperties(entry.action, action)
      actionUpdated(entry.action)
    }
    return true
  }

  function unregisterAction(action) {
    let entry = d.actions[action.uuid]
    if (!entry || entry._registerCount == 0) return
    entry._registerCount--
    if (entry._registerCount > 0) return
    actionUnregistered(entry.action)
  }

  //! Clones an inline subaction descriptor ({action: <object>, name?: ...}), replacing the
  //! inline action object with a created RobotAction so executors can read subaction.action.
  function _wrapInlineSubaction(subaction) {
    let wrapped = {}
    for (let key in subaction) wrapped[key] = subaction[key]
    wrapped.action = _createAction(subaction.action)
    return wrapped
  }

  function _createAction(action) {
    let subactions = []
    if (action.subactions) {
      for (let subaction of action.subactions) {
        if (typeof subaction.action === "string") subactions.push(subaction)
        else subactions.push(_wrapInlineSubaction(subaction))
      }
    }
    return actionComponent.createObject(root, {
      uuid: action.uuid,
      name: action.name,
      icon: action.icon,
      type: action.type,
      topic: action.topic,
      messageType: action.messageType,
      evaluateParams: Conversions.toBoolean(action.evaluateParams),
      params: action.params,
      subactions: subactions,
      parallel: Conversions.toBoolean(action.parallel),
      continueOnError: Conversions.toBoolean(action.continueOnError),
      anonymous: Conversions.toBoolean(action.anonymous)
    })
  }

  function _applyProperties(target, source) {
    target.name = source.name
    target.icon = source.icon
    target.type = source.type
    target.topic = source.topic
    target.messageType = source.messageType
    target.evaluateParams = Conversions.toBoolean(source.evaluateParams)
    target.params = source.params
    target.parallel = Conversions.toBoolean(source.parallel)
    target.continueOnError = Conversions.toBoolean(source.continueOnError)
    target.anonymous = Conversions.toBoolean(source.anonymous)
    // Destroy old anonymous subaction QML objects before replacing
    if (target.subactions) {
      for (let old of target.subactions) {
        if (typeof old.action !== "string" && old.action.destroy) old.action.destroy()
      }
    }
    let subactions = []
    if (source.subactions) {
      for (let subaction of source.subactions) {
        if (typeof subaction.action === "string") subactions.push(subaction)
        else subactions.push(_wrapInlineSubaction(subaction))
      }
    }
    target.subactions = subactions
  }


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

  //! Executes the given action. Note that if you only pass the uuid of the action, you must ensure that
  //! the action is registered before calling this function.
  //! If you pass an action object, the uuid of the action will be used to find the action.
  //! If the action is not registered, it will be registered automatically.
  //! @param anonymous If anonymous is true, the execution will be created as anonymous
  function execute(action_or_uuid, anonymous=false) {
    var execution = null
    if (action_or_uuid == null) {
      try {
        throw new Error("No action or uuid given to execute function!")
      } catch (e) {
        Ros2.error("RobotActionManager: " + e.message + "\nStack:\n---\n" + e.stack)
      }
      return false
    }
    try {
      // Get the action from the actionManager since that object will not be destroyed during execution
      // which is not guaranteed for the passed object
      let uuid = typeof action_or_uuid === 'string' ? action_or_uuid : action_or_uuid.uuid
      let action = getAction(uuid)
      if (action == null) {
        if (typeof action_or_uuid === 'string') {
          Ros2.error("Could not execute action with uuid '" + action_or_uuid + "'! No such action registered.")
          return false
        }
        if (!registerAction(action_or_uuid)) {
          Ros2.error("Could not execute action '" + action_or_uuid.name + "'! Could not register action.")
          return false
        }
        // registerAction may have assigned a generated uuid to an inline action, so re-read it.
        uuid = action_or_uuid.uuid
        action = getAction(uuid)
      }
      Ros2.debug("Execute action " + action.name + "...")
      var execution = getExecution(action)
      if (execution !== null) {
        if (execution.active) {
          Ros2.error("Could not execute " + action.name + " since it is already running!")
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
      Ros2.error("RobotActionManager: Executing robot action failed: " + e + "\nStack:\n---\n" + e.stack)
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
        Ros2.error("Could not cancel " + name + "! No active execution found.")
        return false
      }
      Ros2.debug("Canceling robot action '" + execution.action.name + "' with uuid: " + uuid)
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
      Ros2.error("RobotActionManager: Canceling robot action failed: " + e + "\nStack:\n---\n" + e.stack)
      return false
    }
  }

  Component {
    id: actionComponent
    RobotAction {}
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
        Ros2.warn("Register failed! Unsupported action: " + JSON.stringify(action))
        return false
      }
    } catch (e) {
      Ros2.error("Failed to register action: " + e + "\nStack:\n---\n" + e.stack)
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
        Ros2.warn("Unregister failed! Unsupported action: " + JSON.stringify(action))
        return false
      }
    } catch (e) {
      Ros2.error("Failed to unregister action: " + e + "\nStack:\n---\n" + e.stack)
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
    property var actions: ({})
    property var activeExecutions: []
    property ActionExecutor actionExecutor: ActionExecutor {}
    property CompositeExecutor compositeExecutor: CompositeExecutor { actionManager: root }
    property JavaScriptExecutor javascriptExecutor: JavaScriptExecutor {}
    property ServiceExecutor serviceExecutor: ServiceExecutor {}
    property ToggleExecutor toggleExecutor: ToggleExecutor { actionManager: root }
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