import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Utils 1.0
import Ros 1.0
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
    editVideoSource.load(configuration)
    previewCheckbox.checked = !!configuration.preview
    if (configuration.preview) editPreviewVideoSource.load(configuration.preview)
    cameraNameTextField.text = configuration.name
    cameraOrientationComboBox.currentIndex = configuration.orientation / 90
  }

  function reset() {
    editVideoSource.reset()
    editPreviewVideoSource.reset()
    cameraNameTextField.text = "Unnamed"
    cameraOrientationComboBox.currentIndex = 0
    previewCheckbox.checked = false
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

    Text {
      Layout.preferredWidth: Units.pt(60)
      text: "Name:"
      font { weight: Font.Bold }
    }

    TextField {
      id: cameraNameTextField
      Layout.fillWidth: true
      cursorVisible: focus
      selectByMouse: true
    }

    // ------------- VIDEO SOURCE --------------
    SectionHeader {
      Layout.columnSpan: 2
      Layout.fillWidth: true
      text: "Video Source"
    }

    EditVideoSource {
      id: editVideoSource
      Layout.columnSpan: 2
      Layout.fillWidth: true
    }

    Text {
      text: "Preview"
      font { weight: Font.Bold }
    }

    CheckBox {
      id: previewCheckbox
      Layout.alignment: Qt.AlignRight
    }

    EditVideoSource {
      id: editPreviewVideoSource
      Layout.columnSpan: 2
      Layout.fillWidth: true
      visible: previewCheckbox.checked
    }


    // ------------- VIDEO SETTINGS --------------
    SectionHeader {
      Layout.columnSpan: 2
      Layout.fillWidth: true
      text: "Settings"
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
    cameraNameTextField.selectAll()
    cameraNameTextField.focus = true
  }
  onAccepted: {
    var configuration = editVideoSource.configuration
    configuration.name = cameraNameTextField.text
    configuration.orientation = cameraOrientationComboBox.currentIndex * 90
    if (previewCheckbox.checked) {
      configuration.preview = editPreviewVideoSource.configuration
    }
    root.save(configuration)
    reset()
  }
}
