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
  readonly property bool active: execution && !!execution.active
  readonly property string state: {
    if (!d.currentAction || d.currentAction.type !== 'toggle') return ''
    if (d.currentAction._activeIndex === undefined) return 'Unknown'
    return d.currentAction.subactions[d.currentAction._activeIndex].name || ''
  }

  function execute(anonymous=false) {
    if (!action || !robot) return
    robot.actionManager.execute(action, anonymous)
  }

  function cancel() {
    if (!action || !robot) return
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
    d.completed = true
    d.reconcile()
  }

  Component.onDestruction: d.unregister()

  // Guarded by d.completed so the initial property assignments don't register a second time
  onActionChanged: d.reconcile()
  onRobotChanged: d.reconcile()

  QtObject {
    id: d
    property bool completed: false
    property var currentAction: null
    // The manager the current action was registered with, so a robot change unregisters there
    property var registeredManager: null

    function unregister() {
      if (registeredManager && currentAction) registeredManager.unregisterAction(currentAction)
      registeredManager = null
      currentAction = null
    }

    function reconcile() {
      if (!completed) return
      unregister()
      if (!root.action || !root.robot) return
      root.robot.actionManager.registerAction(root.action)
      currentAction = root.robot.actionManager.getAction(root.action.uuid)
      registeredManager = root.robot.actionManager
      let execution = root.robot.actionManager.getExecution(root.action.uuid)
      if (execution !== null) root.execution = execution
    }
  }
}

