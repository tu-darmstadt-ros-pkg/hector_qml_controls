pragma Singleton
import QtQuick 2.3
import QtQuick.Controls 2.2
import Ros2 1.0
import Hector.Utils 1.0

Object {
  id: root
  signal actionRegistered(RobotAction action)
  signal actionUnregistered(RobotAction action)
  signal actionUpdated(RobotAction newAction, RobotAction oldAction)

  function getAction(uuid) {
    if (!uuid) return null
    let entry = d.actions[uuid]
    if (entry && entry._registerCount > 0) return entry.action
    return null
  }

  function registerAction(action) {
    if (!action.uuid) action.uuid = Uuid.generate()
    let entry = d.actions[action.uuid]
    if (entry && entry.action.equals(action)) {
      entry._registerCount++
      return true
    }
    let cleanAction = cloneAction(action)
    if (entry) {
      if (entry._registerCount > 0) {
        Ros2.error("Registered a different action with the same uuid '" + action.uuid + "' as an existing action. " +
                  "Action '" + entry.action.name + "' is overwritten by '" + action.name + "'.")
        Ros2.warn("Action is:\n" + JSON.stringify(action) + "\nRegistered was:\n" + JSON.stringify(entry.action))
        actionUnregistered(entry.action)
      }
      entry.action.destroy()
    }
    d.actions[action.uuid] = {_registerCount: 1, action: cleanAction}
    actionRegistered(cleanAction)
    return true
  }

  function updateAction(action) {
    let entry = d.actions[action.uuid]
    if (entry._locked) return false
    if (action != entry.action) {
      let tmp = entry.action
      entry.action = cloneAction(action)
      actionUpdated(entry.action, tmp)
      tmp.destroy()
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