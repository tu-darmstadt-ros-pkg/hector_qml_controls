import QtQuick 2.3
import Ros 1.0

Object {
  id: root
  property real timeout: 5000
  property var action: null
  property var execution: null
  readonly property bool active: execution && execution.active || false
  readonly property string state: {
    if (!d.currentAction || d.currentAction.type !== 'toggle') return ''
    if (d.currentAction._activeIndex === undefined) return 'Unknown'
    return d.currentAction.subactions[d.currentAction._activeIndex].name || ''
  }

  function execute(anonymous=false) {
    if (!action) return
    RobotActionExecutionManager.execute(action, anonymous)
  }

  function cancel() {
    if (!action) return
    RobotActionExecutionManager.cancel(action)
  }

  Connections {
    target: RobotActionExecutionManager
    onExecutionStarted: function (uuid, execution) {
      if (!action) return
      if (uuid && uuid == action.uuid) root.execution = execution
    }
  }

  Component.onCompleted: {
    if (!action) return
    RobotActionManager.registerAction(action)
    d.currentAction = RobotActionManager.getAction(action.uuid)
    var execution = RobotActionExecutionManager.getExecution(action.uuid)
    if (execution !== null) root.execution = execution
  }

  Component.onDestruction: {
    RobotActionManager.unregisterAction(action)
  }

  onActionChanged: {
    if (d.currentAction) RobotActionManager.unregisterAction(d.currentAction)
    d.currentAction = RobotActionManager.getAction(action.uuid)
    if (d.currentAction) RobotActionManager.registerAction(d.currentAction)
  }

  QtObject {
    id: d
    property var currentAction: null
  }
}

