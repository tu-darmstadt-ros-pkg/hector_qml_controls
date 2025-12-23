import QtQuick 2.5
import QtQuick.Layouts 1.1
import Hector.Utils 1.0

Item {
  id: control

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

    Rectangle {
      width: Units.pt(largeTextPointSize)
      height: header
              ? Units.pt(largeTextPointSize)
              : Units.pt(smallTextPointSize)

      Rectangle {
        width: header
               ? Units.pt(largeTextPointSize)
               : Units.pt(smallTextPointSize)
        height: header
                ? Units.pt(largeTextPointSize)
                : Units.pt(smallTextPointSize)
        radius: header
                ? Units.pt(largeTextPointSize)
                : Units.pt(smallTextPointSize)
        color: level === 0 ? "limegreen" 
             : level === 1 ? "orange" 
                           : "red"
        anchors.horizontalCenter: parent.horizontalCenter
      }

      SimpleToolTip {
        text: level === 0 ? "OK" 
            : level === 1 ? "Info"
                          : "Error"
        visible: true
      }
    }

    ColumnLayout {
      Text {
        Layout.fillWidth: true
        elide: Text.ElideMiddle
        text: control.name
        font.bold: header
        font.pointSize: header ? largeTextPointSize : smallTextPointSize

        SimpleToolTip {
          text: control.name
          visible: truncated
        }
      }

      Text {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: control.message
        font.pointSize: smallTextPointSize
        font.italic: true
        visible: message && message.length > 0

        SimpleToolTip {
          text: control.message
          visible: truncated
        }
      }
    }
  }
}
