import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Utils 1.0
import Hector.MultiRobot 1.0
import Ros2 1.0
import Ros2.CameraServer 1.0
import "internal"

Dialog {
  id: root
  parent: ApplicationWindow.overlay
  width: Units.pt(360)
  height: mainLayout.implicitHeight + Units.pt(120)
  x: parent.x + (parent.width - width) / 2
  y: parent.y + (parent.height - height) / 2
  title: "Edit camera"
  standardButtons: Dialog.Save | Dialog.Cancel
  focus: true

  property string _initialName: ""

  function _filteredCameras() {
    let cameras = CameraServer.cameras
    if (!showAllRobotsCheckBox.checked && RobotManager.activeRobot) {
      cameras = cameras.filter(function(camera) {
        return camera.server.robot === RobotManager.activeRobot.robot_id
      })
    }
    return cameras
  }

  function _streamLabel(stream, index) {
    let parts = []
    if (stream.width > 0 && stream.height > 0)
      parts.push(stream.width + "x" + stream.height)
    if (stream.codec)
      parts.push(stream.codec)
    if (stream.transport)
      parts.push(stream.transport)
    if (stream.framerate > 0)
      parts.push(stream.framerate + " fps")
    return "Stream " + index + (parts.length > 0 ? " (" + parts.join(", ") + ")" : "")
  }

  function _updateStreamModels() {
    let camera = cameraComboBox.selectedCamera
    let mainModel = [{"text": "Auto", "value": -1}]
    if (camera && camera.streams) {
      for (let i = 0; i < camera.streams.length; i++) {
        let label = _streamLabel(camera.streams[i], i)
        mainModel.push({"text": label, "value": i})
      }
    }
    let prevStreamValue = streamComboBox.currentValue
    streamComboBox.model = mainModel
    // Restore selection if possible
    if (prevStreamValue !== undefined) {
      let idx = mainModel.findIndex(function(item) { return item.value === prevStreamValue })
      streamComboBox.currentIndex = idx >= 0 ? idx : 0
    }
  }

  function load(configuration) {
    _initialName = configuration.name || ""
    // Show all robots if camera belongs to a different robot
    if (RobotManager.activeRobot && configuration.robot !== RobotManager.activeRobot.robot_id) {
      showAllRobotsCheckBox.checked = true
    } else {
      showAllRobotsCheckBox.checked = false
    }

    let cameras = _filteredCameras()
    cameraComboBox.model = cameras
    let index = cameras.findIndex(function(camera) {
      return camera.server.robot === configuration.robot && camera.cameraId === configuration.cameraId
    })
    if (index < 0) {
      // Camera not found, try showing all robots
      showAllRobotsCheckBox.checked = true
      cameras = _filteredCameras()
      cameraComboBox.model = cameras
      index = cameras.findIndex(function(camera) {
        return camera.server.robot === configuration.robot && camera.cameraId === configuration.cameraId
      })
    }
    cameraComboBox.currentIndex = Math.max(0, index)

    cameraNameTextField.text = _initialName
    cameraOrientationComboBox.currentIndex = (configuration.orientation || 0) / 90

    _updateStreamModels()

    // Set stream index
    let streamIndex = configuration.streamIndex !== undefined ? configuration.streamIndex : -1
    streamComboBox.currentIndex = Math.max(0, streamComboBox.indexOfValue(streamIndex))
  }

  function reset() {
    showAllRobotsCheckBox.checked = false
    cameraComboBox.model = _filteredCameras()
    cameraComboBox.currentIndex = 0
    _initialName = ""
    cameraNameTextField.text = ""
    cameraOrientationComboBox.currentIndex = 0
    _updateStreamModels()
    streamComboBox.currentIndex = 0
  }

  /*!
   *  Configuration is:
   *    * id: {robot}//{cameraId}//{streamIndex}
   *    * robot: string
   *    * cameraId: string
   *    * name: string
   *    * orientation: int - 0|90|180|270
   *    * streamIndex: int - -1 for auto
   */
  signal save(var configuration)

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent

    // ------------- VIDEO SOURCE --------------
    RowLayout {
      Layout.fillWidth: true
      Text {
        text: "Camera:"
        font { weight: Font.Bold }
      }
      Item { Layout.fillWidth: true }
      CheckBox {
        id: showAllRobotsCheckBox
        text: "Show all robots"
        checked: false
        onCheckedChanged: {
          let prevCamera = cameraComboBox.selectedCamera
          cameraComboBox.model = _filteredCameras()
          if (prevCamera) {
            let idx = cameraComboBox.model.findIndex(function(c) {
              return c.server.robot === prevCamera.server.robot && c.cameraId === prevCamera.cameraId
            })
            cameraComboBox.currentIndex = Math.max(0, idx)
          }
        }
      }
    }

    ComboBox {
      id: cameraComboBox
      Layout.fillWidth: true
      textRole: "name"
      property var selectedCamera: currentIndex >= 0 && model ? model[currentIndex] : null
      displayText: {
        if (!selectedCamera) return "Select camera"
        if (showAllRobotsCheckBox.checked)
          return selectedCamera.server.robot + " - " + selectedCamera.name
        return selectedCamera.name
      }
      delegate: ItemDelegate {
        width: cameraComboBox.width
        text: showAllRobotsCheckBox.checked
              ? modelData.server.robot + " - " + modelData.name
              : modelData.name
        highlighted: cameraComboBox.highlightedIndex === index
      }
      onSelectedCameraChanged: _updateStreamModels()
    }

    // ------------- STREAM SELECTION --------------
    SectionHeader {
      Layout.fillWidth: true
      text: "Stream"
    }

    Text {
      text: "Main stream:"
      font { weight: Font.Bold }
    }

    ComboBox {
      id: streamComboBox
      Layout.fillWidth: true
      textRole: "text"
      valueRole: "value"
      displayText: currentText || "Auto"
      enabled: !!cameraComboBox.selectedCamera
    }

    // ------------- VIDEO SETTINGS --------------
    SectionHeader {
      Layout.fillWidth: true
      text: "Settings"
    }

    Text {
      text: "Name:"
      font { weight: Font.Bold }
    }

    TextField {
      id: cameraNameTextField
      Layout.fillWidth: true
      cursorVisible: focus
      placeholderText: cameraComboBox.selectedCamera ? cameraComboBox.selectedCamera.name : "Camera name"
      selectByMouse: true
    }

    Text {
      text: "Rotation:"
      font { weight: Font.Bold }
    }

    ComboBox {
      id: cameraOrientationComboBox
      Layout.fillWidth: true
      model: [0, 90, 180, 270]
    }
  }

  Connections {
    target: CameraServer
    function onCamerasChanged() {
      let prevCamera = cameraComboBox.selectedCamera
      cameraComboBox.model = _filteredCameras()
      if (prevCamera) {
        let idx = cameraComboBox.model.findIndex(function(c) {
          return c.server.robot === prevCamera.server.robot && c.cameraId === prevCamera.cameraId
        })
        if (idx >= 0) cameraComboBox.currentIndex = idx
      }
    }
  }

  onAboutToShow: {
    cameraComboBox.model = _filteredCameras()
    _updateStreamModels()
    cameraNameTextField.selectAll()
    cameraNameTextField.focus = true
  }

  onAccepted: {
    let camera = cameraComboBox.selectedCamera
    if (!camera) return

    let streamIndex = streamComboBox.currentValue !== undefined ? streamComboBox.currentValue : -1
    let configuration = {
      id: camera.server.robot + '//' + camera.cameraId,
      robot: camera.server.robot,
      cameraId: camera.cameraId,
      name: cameraNameTextField.text || camera.name,
      orientation: cameraOrientationComboBox.currentIndex * 90,
      streamIndex: streamIndex
    }
    root.save(configuration)
    reset()
  }
}
