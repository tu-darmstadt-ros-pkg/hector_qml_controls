import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Controls 1.0
import Hector.Utils 1.0
import Ros2 1.0

// Shows a robot's orientation: a 2D side view tilted by the robot's pitch plus roll/pitch
// water levels. All robot-specific configuration is provided via properties so this control
// is reusable and has no dependency on the multi-robot singletons.
Item {
  id: control
  //! IMU topic (sensor_msgs/Imu) whose orientation drives the view.
  property alias imuTopic: imuSubscriber.topic
  //! Robot type (RobotType.Value) and flipper configuration, forwarded to the 2D view.
  property alias type: robotView.type
  property alias flipperFrames: robotView.flipperFrames
  property alias baseFrame: robotView.baseFrame
  //! If true, roll and pitch are negated so the levels still make sense when driving in reverse.
  property bool reverse: false
  property real horizontalLevelMinimum: -60
  property real horizontalLevelMaximum: 60
  property real verticalLevelMinimum: -60
  property real verticalLevelMaximum: 60

  QtObject {
    id: d

    property var orientation: {
      if (!imuSubscriber.message)
        return {w: 1, x: 0, y: 0, z: 0}
      return imuSubscriber.message.orientation
    }

    function extractRoll(q) {
      var roll = Math.atan2(2 * (q.w * q.x + q.y * q.z), 1 - 2 * (q.x * q.x + q.y * q.y))
      return control.reverse ? -roll : roll
    }

    function extractPitch(q) {
      var pitch = Math.asin(2 * (q.w * q.y - q.z * q.x))
      return control.reverse ? -pitch : pitch
    }

    function extractYaw(q) {
      return Math.atan2(2 * (q.w * q.z + q.x * q.y), 1 - 2 * (q.y * q.y + q.z * q.z))
    }
  }

  Subscription {
    id: imuSubscriber
  }

  UGV2DView {
    id: robotView
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.right: verticalLevel.left
    anchors.bottom: horizontalLevel.top
    pitch: d.extractPitch(d.orientation)
  }

  WaterLevel {
    id: horizontalLevel
    anchors.left: parent.left
    anchors.right: verticalLevel.left
    anchors.bottom: parent.bottom
    height: Units.pt(12)
    minimum: control.horizontalLevelMinimum
    maximum: control.horizontalLevelMaximum
    value: d.extractRoll(d.orientation) * 180 / Math.PI
  }


  WaterLevel {
    id: verticalLevel
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: Units.pt(16)
    orientation: WaterLevel.Vertical
    minimum: control.verticalLevelMinimum
    maximum: control.verticalLevelMaximum
    value: d.extractPitch(d.orientation) * 180 / Math.PI
  }
}
