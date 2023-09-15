pragma Singleton
import QtQuick 2.3
import QtQuick.Controls 2.2
import Ros 1.0
import "."

Object {
  id: root

  function getAction(uuid) {
    if (!uuid) return null
    let entry = d.actions[uuid]
    if (entry && entry._registerCount > 0) return entry.action
    return null
  }

  function registerAction(action) {
    if (!action.uuid) action.uuid = Uuid.generate()
    let entry = d.actions[action.uuid]
    if (entry) {
      if (entry.action.equals(action)) {
        entry._registerCount++
        return true
      }
      if (entry._registerCount > 0) {
        Ros.error("Registered a different action with the same uuid '" + action.uuid + "' as an existing action. " +
                  "Action '" + entry.action.name + "' is overwritten by '" + action.name + "'.")
        Ros.warn("Action is:\n" + JSON.stringify(action) + "\nRegistered was:\n" + JSON.stringify(entry.action))
      }
      entry.action.destroy()
    }
    let cleanAction = cloneAction(action)
    if (!RobotActionExecutionManager._setupAction(cleanAction)) return false
    d.actions[action.uuid] = {_registerCount: 1, action: cleanAction}
    return true
  }

  function updateAction(action) {
    let execution = RobotActionExecutionManager.getExecution(action)
    if (execution) return false
    let entry = d.actions[action.uuid]
    RobotActionExecutionManager._freeResources(entry.action)
    if (action != entry.action) {
      entry.action.destroy()
      entry.action = cloneAction(action)
    }
    return RobotActionExecutionManager._setupAction(entry.action)
  }

  function unregisterAction(action) {
    let entry = d.actions[action.uuid]
    if (!entry || entry._registerCount == 0) return
    entry._registerCount--
    if (entry._registerCount > 0) return
    RobotActionExecutionManager._freeResources(entry.action)
  }

  function cloneAction(action) {
    let subactions = []
    if (action.subactions) {
      for (let subaction of action.subactions) {
        if (typeof subaction.action === "string") subactions.push(subaction)
        else subactions.push(cloneAction(subaction.action))
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
      anonymous: Conversions.toBoolean(action.anonymous)
    })
  }

  Component {
    id: actionComponent
    RobotAction {}
  }

  QtObject {
    id: d

    property var actions: ({})
  }
}