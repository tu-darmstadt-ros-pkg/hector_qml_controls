import QtQuick 2.3
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0

Item {
  id: root
  property bool loading
  default property alias control: loader.contentItem
  property alias skeleton: skeletonControl.contentItem
  property alias skeletonBackground: skeletonControl.background 

  onLoadingChanged: {
    skeletonAnimation.complete()
    skeletonMask.opacity = 1
  }

  implicitHeight: loader.contentItem.implicitHeight
  implicitWidth: loader.contentItem.implicitWidth
  width: loader.contentItem.width
  height: loader.contentItem.height

  Control {
    id: skeletonControl
    visible: false
    anchors.fill: parent
    contentItem: Rectangle {}
    background: Rectangle {
      anchors.fill: parent
      color: "lightgray"
    }
  }

  OpacityMask {
    id: skeletonMask
    visible: root.loading
    anchors.fill: parent
    source: skeletonControl.background
    maskSource: skeletonControl.contentItem

    SequentialAnimation {
      id: skeletonAnimation
      running: root.loading
      loops: Animation.Infinite
      PropertyAnimation {
        target: skeletonMask
        property: "opacity"
        to: 0
        duration: 2000
        easing.type: Easing.InCubic
      }
      PropertyAnimation {
        target: skeletonMask
        property: "opacity"
        to: 1
        duration: 1000
        easing.type: Easing.OutCubic
      }
    }
  }

  Control {
    id: loader
    visible: !root.loading
    anchors.fill: parent
  }
}