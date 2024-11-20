import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Ros2 1.0

Item {
  id: control
  implicitWidth: contentLayout.implicitWidth
  implicitHeight: contentLayout.implicitHeight
  enum TopicType {
    Action, Service, Topic
  }
  property int type: TopicComboBox.Topic
  property string messageType // Can be specified optionally to only show topics of a given type
  property bool autoLoad: false
  // Can be used to blacklist specific topics using regular expressions
  property var blacklist: [/[gs]et_loggers$/, /set_logger_level$/, /set_camera_info/, /set_parameters/]

  property alias currentIndex: comboBox.currentIndex
  property alias currentText: comboBox.currentText
  property alias editable: comboBox.editable
  property alias editText: comboBox.editText
  property alias model: comboBox.model
  property bool customValue: false

  GridLayout {
    id: contentLayout
    anchors.fill: parent
    columns: 2
    columnSpacing: 0
    RefreshButton {
      id: reloadButton
      Layout.fillHeight: true
      Layout.preferredWidth: height
      height: comboBox.height
      width: height
      onClicked: reload(true)
    }
    ComboBox {
      id: comboBox
      Layout.fillWidth: true
      // Workaround for a bug where selecting the last selected item after editing doesn't reset the text
      onActivated: editText = model[index]
      onCurrentIndexChanged: control.customValue = false
      onEditTextChanged: control.customValue = !model.includes(editText)
    }
    Rectangle {
      Layout.fillWidth: true
      Layout.columnSpan: 2
      implicitHeight: errorText.implicitHeight
      visible: errorText.length > 0

      Text {
        id: errorText
        anchors.fill: parent
      }
    }
  }

  onTypeChanged: autoLoad && reload(false)
  onMessageTypeChanged: autoLoad && reload(false)

  QtObject {
    id: d

    property var blacklistRegex: {
      if (typeof control.blacklist === 'string') return [new RegExp(control.blacklist)]
      var result = []
      if (!control.blacklist || !control.blacklist.length) return []
      for (var i = 0; i < control.blacklist.length; ++i) {
        result.push(typeof control.blacklist[i] === 'string' ? new RegExp(control.blacklist[i]) : control.blacklist[i])
      }
      return result
    }

    function isBlacklisted(topic) {
      for (var i = 0; i < d.blacklistRegex.length; ++i) {
        if (d.blacklistRegex[i].test(topic)) return true
      }
      return false
    }

    function updateModel(model) {
      let customValue = control.customValue
      let previousValue = comboBox.editText
      if (previousValue && model.includes(previousValue)) {
        var index = model.indexOf(previousValue)
        model.splice(index, 1)
        model.splice(0, 0, previousValue)
      }
      comboBox.model = model
      if (customValue && previousValue != comboBox.editText) comboBox.editText = previousValue
      reloadButton.animate = false
    }
  }

  function reload(animate) {
    errorText.text = ""
    reloadButton.animate = !!animate
    if (type == TopicComboBox.Service) {
      // Get list of services
      let service_servers = Ros2.getServiceNamesAndTypes()
      let services = []
      for (let name in service_servers) {
        if (d.isBlacklisted(name)) continue
        if (messageType && !service_servers[name].includes(messageType)) continue
        services.push(name)
      }
      d.updateModel(services.sort())
    } else if (type == TopicComboBox.Action) {
      // Get list of actions
      let action_servers = Ros2.getActionNamesAndTypes()
      let actions = []
      for (let name in action_servers) {
        if (d.isBlacklisted(name)) continue
        if (messageType && !action_servers[name].includes(messageType)) continue
        actions.push(name)
      }
      d.updateModel(actions.sort())
    } else if (type == TopicComboBox.Topic) {
      // Get list of topics
      var topics = messageType ? Ros2.queryTopics(messageType) : Ros2.queryTopics()
      var filteredTopics = []
      for (var i = 0; i < topics.length; ++i) {
        if (d.isBlacklisted(topics[i])) continue
        if (filteredTopics.indexOf(topics[i]) != -1) continue
        filteredTopics.push(topics[i])
      }
      d.updateModel(filteredTopics.sort())
    } else {
      d.updateModel([])
    }
  }
}
