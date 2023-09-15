import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.0

Item {
  id: root
  height: 40 // Default height
  implicitWidth: mainLayout.implicitWidth
  implicitHeight: mainLayout.implicitHeight
  property real iconMargin: 12
  property bool flat: false
  property real buttonRadius: 4
  property font shortcutFont: Qt.font({pixelSize: 12})
  property bool shortcutVisible: true
  property bool showText: false
  property bool editable: true
  property color selectedColor: "#888888"
  
  property var toolButtonComponent: Component {
    Button {
      id: control
      Layout.fillHeight: true
      Layout.preferredWidth: root.showText ? content.implicitWidth : root.height
      checkable: modelData.isSelected
      checked: modelData.isSelected
      flat: root.flat
      autoExclusive: true

      background: Rectangle {
        implicitWidth: root.height
        implicitHeight: root.height
        radius: root.buttonRadius
        visible: !control.flat
        opacity: enabled ? 1 : 0.3
        color: control.checked || control.pressed ? root.selectedColor : control.hovered ? "#aaaaaa" : "#cccccc"
        Text {
          visible: root.shortcutVisible
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: 6
          anchors.bottomMargin: 2
          font: root.shortcutFont
          text: modelData.shortcutKey
        }
      }

      RowLayout {
        id: content
        height: control.height
        Item {
          Layout.fillHeight: true
          Layout.preferredWidth: root.showText ? root.height - 8 : root.height
          Image {
            anchors.centerIn: parent
            source: modelData.iconSource
            width: parent.height - 2 * root.iconMargin
            height: parent.height - 2 * root.iconMargin
          }
        }

        Text {
          Layout.rightMargin: 16
          visible: root.showText
          text: modelData.name
          font.pixelSize: control.height - 2 * root.iconMargin
          verticalAlignment: Text.AlignVCenter
        }
      }

      ToolTip.text: modelData.name
      ToolTip.visible: hovered
      ToolTip.delay: 500

      onClicked: rviz.toolManager.currentTool = modelData
    }
  }

  RowLayout {
    id: mainLayout
    height: parent.height

    Repeater {
      model: rviz.toolManager.tools
      delegate: root.toolButtonComponent
    }

    Button {
      id: addButton
      visible: root.editable

      background: Rectangle {
        implicitWidth: root.height
        implicitHeight: root.height
        radius: root.buttonRadius
        visible: !addButton.flat
        opacity: enabled ? 1 : 0.3
        color: addButton.checked || addButton.pressed ? "#888888" : addButton.hovered ? "#aaaaaa" : "#cccccc"
      }

      AutoSizeText {
        text: "\u2795"
        color: "#2a4bde"
      }

      onClicked: rviz.toolManager.addTool()
    }

    Button {
      id: removeButton
      visible: root.editable

      background: Rectangle {
        implicitWidth: root.height
        implicitHeight: root.height
        radius: root.buttonRadius
        visible: !removeButton.flat
        opacity: enabled ? 1 : 0.3
        color: removeButton.checked || removeButton.pressed ? "#888888" : removeButton.hovered ? "#aaaaaa" : "#cccccc"
      }

      AutoSizeText {
        text: "\u2796"
        color: "#2a4bde"
      }

      onClicked: removeToolMenu.open()

      Menu {
        id: removeToolMenu
        Repeater {
          model: rviz.toolManager.tools
          MenuItem { text: modelData.name; onTriggered: rviz.toolManager.removeTool(modelData) }
        }
      }
    }
  }
}