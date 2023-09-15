import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Utils 1.0

Control {
  id: control
  property bool round: true
  property bool flat: false
  property color color: "black"
  property color backgroundColor: "white"
  property string text
  padding: Units.pt(4)

  background: Rectangle {
    anchors.fill: parent
    visible: !control.flat
    radius: control.round ? Math.min(width, height) / 2 : 0
    color: control.backgroundColor
  }
  
  contentItem: Text {
    anchors.fill: parent
    anchors.margins: control.padding
    fontSizeMode: Text.Fit
    minimumPointSize: 6
    font.family: control.font.family
    font.pointSize: 1000
    horizontalAlignment: Text.AlignHCenter
    text: control.text
    color: control.color
  }
}