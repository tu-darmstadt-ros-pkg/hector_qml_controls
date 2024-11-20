import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.10
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros2 1.0

Item {
  id: control
  enum Orientation {
    Horizontal,
    Vertical
  }
  property int orientation: WaterLevel.Horizontal
  property real minimum: -90
  property real maximum: 90
  property real value: 0
  property real bubbleSize: Units.pt(4)
  property real ticks: 30
  property font tickFont: Qt.font({pointSize: 8})
  onMinimumChanged: d.updateTicks()
  onMaximumChanged: d.updateTicks()
  onTicksChanged: d.updateTicks()
  Component.onCompleted: d.updateTicks()

  QtObject {
    id: d
    property int countTicks: Math.floor((control.maximum - control.minimum) / control.ticks)
    property int countVisibleTicks: 0
    property real firstTick: 0
    property real firstTickOffsetPercent: (firstTick - control.minimum) / (control.maximum - control.minimum)

    function updateTicks() {
      var ticks = Math.floor((control.maximum - control.minimum) / control.ticks) + 1
      var first = Math.ceil(control.minimum / control.ticks) * control.ticks
      if (first < control.minimum + 0.01) {
        ticks--
        first += control.ticks
      }
      var last = Math.floor(control.maximum / control.ticks) * control.ticks
      if (last > control.maximum - 0.01) ticks--
      countVisibleTicks = ticks
      firstTick = first
    }
  }

  Rectangle {
    anchors.fill: parent
    color: 'green'
  }

  Rectangle {
    height: control.orientation == WaterLevel.Horizontal ? parent.height : control.bubbleSize
    width: control.orientation == WaterLevel.Horizontal ? control.bubbleSize : parent.width
    radius: control.bubbleSize / 4
    property real value: Math.min(1, Math.max(0, (control.value - control.minimum) / (control.maximum - control.minimum)))
    x: control.orientation == WaterLevel.Horizontal ? value * parent.width - width / 2 : 0
    y: control.orientation == WaterLevel.Horizontal ? 0 : value * parent.height - height / 2
  }

  Repeater {
    model: d.countVisibleTicks
    delegate: control.orientation == WaterLevel.Horizontal ? horizontalMajorTickComponent : verticalMajorTickComponent
  }

  Component {
    id: horizontalMajorTickComponent
    ColumnLayout {
      x: (index / d.countTicks + d.firstTickOffsetPercent) * control.width - implicitWidth / 2
      y: 0
      height: control.height
      spacing: -Units.pt(1)
      Rectangle {
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter
        width: Units.pt(1)
        color: Qt.rgba(0,0,0,1)
      }
      Text {
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        font: control.tickFont
        text: d.firstTick + index * control.ticks
      }
      Rectangle {
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter
        width: Units.pt(1)
        color: Qt.rgba(0,0,0,1)
      }
    }
  }

  Component {
    id: verticalMajorTickComponent
    RowLayout {
      x: 0
      y: (index / d.countTicks + d.firstTickOffsetPercent) * control.height - implicitHeight / 2
      width: control.width
      spacing: Units.pt(1)
      Spacer {
        Layout.fillWidth: true
      }
      Text {
        Layout.preferredWidth: control.width / 2
        Layout.alignment: Qt.AlignRight
        horizontalAlignment: Text.AlignHCenter
        font: control.tickFont
        text: d.firstTick + index * control.ticks
      }
      Rectangle {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        height: Units.pt(1)
        color: Qt.rgba(0,0,0,1)
      }
    }
  }
}
