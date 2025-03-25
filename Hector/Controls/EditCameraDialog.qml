import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.CameraServer 1.0
import Hector.Utils 1.0
import Ros2 1.0
import "internal"

Dialog {
  id: root
  parent: ApplicationWindow.overlay
  width: Units.pt(320)
  height: mainLayout.implicitHeight + Units.pt(120)
  x: parent.x + (parent.width - width) / 2
  y: parent.y + (parent.height - height) / 2
  title: "Add camera"
  standardButtons: Dialog.Save | Dialog.Cancel
  focus: true

  function load(configuration) {
    let index = cameraComboBox.model.findIndex(function(camera) {
      return camera.name === configuration.camera
    })
    if (index < 0) {
      cameraComboBox.model = [configuration.camera].concat(cameraComboBox.model)
      index = 0
    }
    cameraComboBox.currentIndex = index
    cameraNameTextField.text = configuration.name
    cameraOrientationComboBox.currentIndex = configuration.orientation / 90
  }

  function reset() {
    cameraComboBox.currentIndex = 0
    cameraNameTextField.text = ""
    cameraOrientationComboBox.currentIndex = 0
  }

  /*!
   *  Configuration is:
   *    * name: string
   *    * type: "ros|rtsp"
   *    * orientation: int - 0|90|180|270
   *    * if type == ros:
   *       * topic: string
   *       * transport: string
   *    * if type == rtsp:
   *       * url: string
   *       * codec: "h264|h265"
   */
  signal save(var configuration)

  GridLayout {
    id: mainLayout
    anchors.fill: parent
    columns: 2

    // ------------- VIDEO SOURCE --------------

    Text {
      Layout.preferredWidth: Units.pt(60)
      text: "Camera:"
      font { weight: Font.Bold }
    }

    ComboBox {
      id: cameraComboBox
      Layout.fillWidth: true
      textRole: "name"
    }
    
    // ------------- VIDEO SETTINGS --------------
    SectionHeader {
      Layout.columnSpan: 2
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
  onAboutToShow: {
    cameraComboBox.model = CameraServer.cameras
    cameraNameTextField.selectAll()
    cameraNameTextField.focus = true
  }
  onAccepted: {
    let camera = cameraComboBox.currentValue
    if (!camera) {
      return false
    }
    let configuration = {
      id: camera.robot + '//' + camera.cameraId,
      robot: camera.robot,
      cameraId: camera.cameraId,
      name: cameraNameTextField.text || camera.name,
      orientation: cameraOrientationComboBox.currentIndex * 90
    }
    root.save(configuration)
    reset()
  }
}
