import QtQuick 2.3
import Ros2 1.0
import Hector.Actions 1.0
import Hector.MultiRobot 1.0

Object {
  id: root
  property real timeout: 15000
  property var action: null
  property var execution: null
  property Robot robot: null
  readonly property bool active: execution && execution.active || false
  readonly property string state: {
    if (!d.currentAction || d.currentAction.type !== 'toggle') return ''
    if (d.currentAction._activeIndex === undefined) return 'Unknown'
    return d.currentAction.subactions[d.currentAction._activeIndex].name || ''
  }

  function execute(anonymous=false) {
    if (!action) return
    robot.actionManager.execute(action, anonymous)
  }

  function cancel() {
    if (!action) return
    robot.actionManager.cancel(action)
  }

  Connections {
    target: robot && robot.actionManager
    function onExecutionStarted(uuid, execution) {
      if (!action) return
      if (uuid && uuid == action.uuid) root.execution = execution
    }
  }

  Component.onCompleted: {
    if (!action || !robot) return
    robot.actionManager.registerAction(action)
    d.currentAction = robot.actionManager.getAction(action.uuid)
    var execution = robot.actionManager.getExecution(action.uuid)
    if (execution !== null) root.execution = execution
  }

  Component.onDestruction: {
    if (!robot || !action) return
    robot.actionManager.unregisterAction(action)
  }

  onActionChanged: {
    if (!robot) return
    if (d.currentAction) robot.actionManager.unregisterAction(d.currentAction)
    robot.actionManager.registerAction(action.uuid)
    d.currentAction = robot.actionManager.getAction(action.uuid)
  }

  onRobotChanged: {
    if (!action) return
    robot.actionManager.registerAction(action.uuid)
    d.currentAction = robot.actionManager.getAction(action.uuid)
  }

  QtObject {
    id: d
    property var currentAction: null
  }
}

