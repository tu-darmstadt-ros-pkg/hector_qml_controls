import QtQuick 2.3
import QtQuick.Controls 2.2

MouseArea {
  anchors.fill: parent
  property string text
  property int delay: 500

  hoverEnabled: true

  ToolTip.visible: containsMouse
  ToolTip.delay: delay
  ToolTip.text: text
}
