import QtQuick 2.5
import QtQuick.Layouts 1.1
import Hector.Utils 1.0

Item {
  id : control
  property string name
  property string command
  property int status
  property int smallTextPointSize: 9
  property int largeTextPointSize: 11

  implicitHeight: rowLayout.implicitHeight

  RowLayout {
    id: rowLayout
    anchors.fill: parent

    // Outer rectangle in which the indicator dot is centered
    Rectangle {
      id: indicatorPlaceholder
      width: Units.pt(largeTextPointSize)
      height: Units.pt(largeTextPointSize)

      // The actual indicator
      Rectangle {
        id: indicator
        width: Units.pt(largeTextPointSize)
        height: Units.pt(largeTextPointSize)
        radius: Units.pt(largeTextPointSize)
        color: status === 0 ? "limegreen" : "red"
        anchors.horizontalCenter: parent.horizontalCenter
      }
      SimpleToolTip {
        text: status === 0 ? "Running" : "Aborted"
        visible: true
      }
    }

    ColumnLayout {
      // Status name
      Text {
        id: nameText
        Layout.fillWidth: true
        elide: Text.ElideMiddle
        text: control.name
        verticalAlignment: Text.AlignVCenter
        font.pointSize: largeTextPointSize

        SimpleToolTip {
          text: control.name
          visible: nameText.truncated
        }
      }

      // Status command, if any
      Text {
        id: commandText
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: control.command
        verticalAlignment: Text.AlignVCenter
        font.pointSize: smallTextPointSize
        font.italic: true
        visible: command

        SimpleToolTip {
          text: control.command
          visible: commandText.truncated
        }
      }
    }
  }
}
