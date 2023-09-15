import QtQuick 2.3
import QtQuick.Controls 2.1

Item {
  id: root
  //! Exact progress value between 0 and 1, or bounds (array of [min, max] progress)
  property var value: [0, 1]
  property alias foregroundColor: progressBar.color
  property alias backgroundColor: backgroundRectangle.color
  property alias indefiniteColor: indefiniteProgressBar.color

  Rectangle {
    id: backgroundRectangle
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    color: "lightgray"
    clip: true
    x: progressBar.width
    width: {
      if (!root.value || root.value.length !== 2) return parent.width
      return root.value[1] * parent.width - x
    }
    Rectangle {
      id: indefiniteProgressBar
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      color: "gray"
      width: root.width / 3
      x: -parent.width
      PropertyAnimation on x {
        from: -backgroundRectangle.width
        to: backgroundRectangle.width
        duration: 2000
        running: !root.value || root.value.length == 2
        loops: Animation.Infinite
      }
    }
  }

  Rectangle {
    id: progressBar
    anchors.bottom: parent.bottom
    anchors.top: parent.top
    anchors.left: parent.left
    color: "black"
    width: {
      if (!root.value) return 0
      if (root.value.length === 2) return root.value[0] * parent.width
      return root.value * parent.width
    }
    visible: !!root.value
  }
}
