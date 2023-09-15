import QtQuick 2.5
import QtQuick.Controls 2.1

// Displays loading animation as long as text is empty
Item {
  id: root
  property alias font: objectTypeText.font
  property alias color: objectTypeText.color
  property alias text: objectTypeText.text
  property alias skeletonColor: skeletonRectangle.color
  implicitHeight: fontMetrics.height

  onTextChanged: skeletonAnimation.complete()

  FontMetrics {
    id: fontMetrics
    font: objectTypeText.font
  }
  Text { id: objectTypeText; text: "Manometer" }

  Rectangle {
    id: skeletonRectangle
    visible: root.text == ""
    anchors.fill: parent
    anchors.topMargin: 1
    anchors.bottomMargin: 1
    color: "lightgray"
    SequentialAnimation {
      id: skeletonAnimation
      running: root.text == ""
      loops: Animation.Infinite
      PropertyAnimation {
        target: skeletonRectangle
        property: "opacity"
        to: 0
        duration: 2000
        easing.type: Easing.InCubic
      }
      PropertyAnimation {
        target: skeletonRectangle
        property: "opacity"
        to: 1
        duration: 1000
        easing.type: Easing.OutCubic
      }
    }
  }
}