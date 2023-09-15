import QtQuick 2.3
import QtQuick.Controls 2.2
import Hector.Utils 1.0

Rectangle {
  property alias text: textItem.text
  property alias textColor: textItem.color
  property alias font: textItem.font
  implicitWidth: textItem.implicitWidth + 2 * horizontalPadding
  implicitHeight: textItem.implicitHeight + 2 * verticalPadding
  property real horizontalPadding: Units.pt(8)
  property real verticalPadding: Units.pt(4)
  radius: 0.5 * height

  Text {
    id: textItem
    anchors.centerIn: parent
  }
}
