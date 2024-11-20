import QtQuick 2.3
import Ros 1.0

// Don't forget to reflect changes in RobotActionManagers cloneAction function
// And if you change one of these properties remember to call updateAction in the RobotActionManager
QtObject {
  property string uuid
  property string name
  property var icon
  property string type: "none"
  property string topic
  property string messageType
  property bool evaluateParams: false
  property var params
  property var subactions: []
  property bool parallel: false
  //! Whether this is an anonymous action which automatically makes all executions of this action anonymous
  property bool anonymous: false
  property var _activeIndex: undefined

  function getIndexOfSubaction(action_or_uuid) {
    if (!action_or_uuid) return null
    let uuid = typeof action_or_uuid === "string" ? action_or_uuid : action_or_uuid.uuid
    for (let index = 0; index <= subactions.length; ++index) {
      let subaction_uuid = typeof subactions[index].action === "string" ? subactions[index].action : subactions[index].action.uuid
      if (subaction_uuid === uuid) return index
    }
    return -1
  }

  function getParams() {
    var result = params
    if (evaluateParams) {
      if (typeof result === 'string') result = eval('(function () {' + result + '})()')
      else if (typeof result === 'function') result = result()
    }
    if (typeof result === 'string') result = JSON.parse(result)
    if (typeof result === 'function') Ros.error("RobotAction param was function but evaluateParams is not true!")
    return result
  }

  function equals(action) {
    if (!action) return false
    if (action.type === "composite") {
      if (subactions.length != action.subactions.length) return false
      for (let i = 0; i < subactions.length; ++i) {
        if (typeof subactions[i].action === "string") {
          if (subactions[i].action === action.subactions[i].action) continue
          return false
        }
        // If it's not an uuid, it's an anonymous action and we compare recursively
        if (!subactions[i].action.equals(action.subactions[i].action)) return false
      }
    }
    return uuid === action.uuid && name === action.name && type === action.type && topic === action.topic &&
           messageType === action.messageType && evaluateParams === Conversions.toBoolean(action.evaluateParams) &&
           params === action.params && parallel === Conversions.toBoolean(action.parallel) &&
           anonymous === Conversions.toBoolean(action.anonymous)
  }
}
