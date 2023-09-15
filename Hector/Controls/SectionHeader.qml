import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

Item {
  id: root
  property alias text: textElement.text
  property alias font: textElement.font
  property color lineColor: "black"
  implicitHeight: textElement.implicitHeight
  implicitWidth: textElement.implicitWidth

  RowLayout {
    anchors.fill: parent

    Rectangle {
      Layout.preferredHeight: 1
      Layout.alignment: Qt.AlignVCenter
      Layout.fillWidth: true
      color: root.lineColor
    }

    Text {
      id: textElement
    }

    Rectangle {
      Layout.preferredHeight: 1
      Layout.alignment: Qt.AlignVCenter
      Layout.fillWidth: true
      color: root.lineColor
    }
  }
}
