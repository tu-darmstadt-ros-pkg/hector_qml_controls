import QtQuick 2.3
import QtQuick.Controls 2.1

Item {
  id: root
  property bool indeterminate: false
  property bool displayInPercent: true
  property real from: 0
  property real to: 1
  property real value: 0
  property color foregroundTextColor: "white"
  property color foregroundColor: "black"
  property color backgroundTextColor: "black"
  property color backgroundColor: "lightgray"
  property string text

  QtObject {
    id: d
    readonly property real percent: (root.value - root.from) / (root.to - root.from)
    readonly property string displayText: root.displayInPercent ? Math.round(d.percent * 100).toFixed(0) + "%" : root.value
  }

  Rectangle {
    id: backgroundRectangle
    anchors.fill: parent
    color: backgroundColor
    height: 32

    AutoSizeText {
      color: backgroundTextColor
      text: root.text || d.displayText
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * Math.min(1, Math.max(0, d.percent))
      color: foregroundColor
      clip: true

      AutoSizeText {
        fillTarget: backgroundRectangle
        color: foregroundTextColor
        text: root.text || d.displayText
      }
    }
  }
}
