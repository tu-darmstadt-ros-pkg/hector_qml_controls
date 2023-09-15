import QtQuick 2.5
import QtQuick.Layouts 1.1
import Hector.Utils 1.0

Item {
  id : control
  property string name
  property string message
  property int level
  property bool header
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
      height: header? Units.pt(largeTextPointSize) : Units.pt(smallTextPointSize)

      // The actual indicator
      Rectangle {
        id: indicator
        width: header ? Units.pt(largeTextPointSize) : Units.pt(smallTextPointSize)
        height: header ? Units.pt(largeTextPointSize) : Units.pt(smallTextPointSize)
        radius: header ? Units.pt(largeTextPointSize) : Units.pt(smallTextPointSize)
        color: level === 0 ? "limegreen" :
               level === 1 ? "orange" :
                             "red"
        anchors.horizontalCenter: parent.horizontalCenter
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
        font.bold: header
        font.pointSize: header ? largeTextPointSize : smallTextPointSize
      }

      // Status message, if any
      Text {
        id: messageText
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: control.message
        verticalAlignment: Text.AlignVCenter
        font.pointSize: smallTextPointSize
        font.italic: true
        visible: message
      }
    }
  }

  SimpleToolTip {
    text: control.message ? control.name + "\n" + control.message : control.name
    delay: 50
    visible: nameText.truncated || messageText.truncated
  }
}
