import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Utils 1.0
import Ros2 1.0

Item {
  id: root
  property string type: typeComboBox.currentText
  property var configuration: {
    if (type == "ROS")
      return {type: type, topic: topicComboBox.editText, transport: transportComboBox.editText}
    return {type: type, url: urlTextField.text, codec: codecComboBox.currentText}
  }

  function load(configuration) {
    reset()
    if (configuration.type) {
      typeComboBox.currentIndex = typeComboBox.find(configuration.type, Qt.MatchFixedString)
    }
    if (configuration.topic) topicComboBox.editText = configuration.topic
    if (configuration.transport) transportComboBox.editText = configuration.transport
    if (configuration.url) urlTextField.text = configuration.url
    if (configuration.codec) codecComboBox.currentIndex = codecComboBox.find(configuration.codec, Qt.MatchFixedString)
  }

  function reset() {
    typeComboBox.currentIndex = 0
    topicComboBox.editText = ""
    transportComboBox.currentIndex = -1
    transportComboBox.currentIndex = 0
    urlTextField.text = ""
    codecComboBox.currentIndex = 0
  }

  implicitHeight: mainLayout.implicitHeight
  implicitWidth: mainLayout.implicitWidth

  Component.onCompleted: {
    topicComboBox.model = Ros2.queryTopics("sensor_msgs/msg/Image").sort()
  }

  GridLayout {
    id: mainLayout
    anchors.fill: parent
    columns: 2

    Text {
      Layout.preferredWidth: Units.pt(60)
      text: "Type:"
      font { weight: Font.Bold }
    }

    ComboBox {
      Layout.fillWidth: true
      id: typeComboBox
      model: ["ROS", "RTSP"]
    }

    // -------------- ROS SETTINGS ---------------
    Text {
      text: "Topic:"
      font { weight: Font.Bold }
      visible: typeComboBox.currentText == "ROS"
    }

    ComboBox {
      id: topicComboBox
      Layout.fillWidth: true
      editable: true
      onEditTextChanged: {
        var transports = ["raw"]
        var topics = []
        if (editText.length > 0) {
          topics = Ros2.queryTopics().filter(function (x) { return x.startsWith(editText + "/") })
          topics = topics.map(function (x) { return x.substr(editText.length + 1)})
          topics = topics.filter(function(x) { return x.indexOf("/") === -1 })
        }
        transportComboBox.model = transports.concat(topics).sort()
      }
      visible: typeComboBox.currentText == "ROS"
    }

    Text {
      text: "Transport:"
      font { weight: Font.Bold }
      visible: typeComboBox.currentText == "ROS"
    }

    ComboBox {
      id: transportComboBox
      Layout.fillWidth: true
      editable: true
      model: ["raw"]
      visible: typeComboBox.currentText == "ROS"
    }

    // -------------- RTSP SETTINGS --------------
    Text {
      text: "URL:"
      font { weight: Font.Bold }
      visible: typeComboBox.currentText == "RTSP"
    }

    TextField {
      id: urlTextField
      Layout.fillWidth: true
      visible: typeComboBox.currentText == "RTSP"
      cursorVisible: focus
      selectByMouse: true
    }

    Text {
      text: "Codec:"
      font { weight: Font.Bold }
      visible: typeComboBox.currentText == "RTSP"
    }

    ComboBox {
      id: codecComboBox
      Layout.fillWidth: true
      model: ["h264", "h265"]
      visible: typeComboBox.currentText == "RTSP"
    }
  }
}