import QtQuick
import QtQuick.Controls.Basic

MouseArea {
  anchors.fill: parent
  property string text
  property int delay: 500

  hoverEnabled: true
  propagateComposedEvents: true
  acceptedButtons: Qt.NoButton


  ToolTip.visible: containsMouse
  ToolTip.delay: delay
  ToolTip.text: text
}
