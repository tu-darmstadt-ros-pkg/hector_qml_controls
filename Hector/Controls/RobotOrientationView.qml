import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Controls 1.0
import Hector.Utils 1.0
import Ros 1.0

Item {
  id: control
  // IMU topic where sensor_msgs/Imu is published
  property alias topic: imuSubscriber.topic
  property string frame 
  property alias frontLeftFlipperJoint: robotView.frontLeftFlipperJoint
  property alias frontRightFlipperJoint: robotView.frontRightFlipperJoint
  property alias backLeftFlipperJoint: robotView.backLeftFlipperJoint
  property alias backRightFlipperJoint: robotView.backRightFlipperJoint
  property alias frontLeftFlipperJointOffset: robotView.frontLeftFlipperJointOffset
  property alias frontLeftFlipperJointMultiplier: robotView.frontLeftFlipperJointMultiplier
  property alias frontRightFlipperJointOffset: robotView.frontRightFlipperJointOffset
  property alias frontRightFlipperJointMultiplier: robotView.frontRightFlipperJointMultiplier
  property alias backLeftFlipperJointOffset: robotView.backLeftFlipperJointOffset
  property alias backLeftFlipperJointMultiplier: robotView.backLeftFlipperJointMultiplier
  property alias backRightFlipperJointOffset: robotView.backRightFlipperJointOffset
  property alias backRightFlipperJointMultiplier: robotView.backRightFlipperJointMultiplier
  property real horizontalLevelMinimum: -60
  property real horizontalLevelMaximum: 60
  property real verticalLevelMinimum: -60
  property real verticalLevelMaximum: 60

  property bool useRvizProperties: false

  QtObject {
    id: d

    // Rviz stuff
    property var rvizPropertyContainer: control.useRvizProperties && rviz && rviz.registerPropertyContainer("Robot Orientation View", "Settings for the robot orientation view")
    function registerTfFrameProperty(name, defaultValue, callback) {
      if (!control.useRvizProperties || !rviz) return null
      var prop = rviz.registerTfFrameProperty(rvizPropertyContainer, name, defaultValue)
      prop.valueChanged.connect(callback)
      callback(prop.value)
      return prop
    }
    property var topicProperty: {
      if (!control.useRvizProperties || !rviz) return null
      var prop = rviz.registerRosTopicProperty(rvizPropertyContainer, "IMU Topic", "/imu/data", "sensor_msgs/Imu", "The topic where the robot's imu messages are published")
      prop.valueChanged.connect(function (value) { control.topic = value })
      control.topic = prop.value
      return prop
    }

    property var orientation: {
      if (!imuSubscriber.message)
        return {w: 1, x: 0, y: 0, z: 0}
      if (!control.frame) return imuSubscriber.message.orientation
      // TODO transform
      return imuSubscriber.message.orientation
    }

    function extractRoll(q) {
      return Math.atan2(2 * (q.w * q.x + q.y * q.z), 1 - 2 * (q.x * q.x + q.y * q.y))
    }
    
    function extractPitch(q) {
      return Math.asin(2 * (q.w * q.y - q.z * q.x))
    }

    function extractYaw(q) {
      return Math.atan2(2 * (q.w * q.z + q.x * q.y), 1 - 2 * (q.y * q.y + q.z * q.z))
    }
  }

  Subscriber {
    id: imuSubscriber
  }
  
  TrackedUGV2DView {
    id: robotView
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.right: verticalLevel.left
    anchors.bottom: horizontalLevel.top
    pitch: d.extractPitch(d.orientation)
    useRvizProperties: control.useRvizProperties
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
