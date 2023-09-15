import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Ros 1.0

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

    function loadServices(result) {
      if (!result) {
        comboBox.model = []
        errorText.text = "Failed to get services! Make sure rosapi_node is running!"
        return
      }
      var topics = []
      for (var i = 0; i < result.services.length; ++i) {
        if (d.isBlacklisted(result.services.at(i))) continue
        if (topics.indexOf(result.services.at(i)) != -1) continue
        topics.push(result.services.at(i))
      }
      d.updateModel(topics.sort())
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
      if (messageType) {
        Service.callAsync("/rosapi/services", "rosapi/ServicesForType", {type: messageType}, d.loadServices)
      } else {
        Service.callAsync("/rosapi/services", "rosapi/Services", {}, d.loadServices)
      }
    } else if (type == TopicComboBox.Action) {
      // Get list of actions
      Service.callAsync("/rosapi/action_servers", "rosapi/GetActionServers", {}, function (result) {
        if (!result) {
          comboBox.model = []
          errorText.text = "Failed to get action servers! Make sure rosapi_node is running!"
          return
        }
        var actions = []
        for (var i = 0; i < result.action_servers.length; ++i) {
          if (d.isBlacklisted(result.action_servers.at(i))) continue
          if (actions.indexOf(result.action_servers.at(i)) != -1) continue
          if (messageType && Ros.queryTopicType(result.action_servers.at(i) + "/goal") != messageType + "Goal") continue
          actions.push(result.action_servers.at(i))
        }
        d.updateModel(actions.sort())
      })
    } else if (type == TopicComboBox.Topic) {
      // Get list of topics
      var topics = messageType ? Ros.queryTopics(messageType) : Ros.queryTopics()
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
