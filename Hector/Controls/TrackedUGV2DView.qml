import QtQuick 2.0
import QtQuick.Controls 2.1
import Ros 1.0

Item {
  id: control
  property real pitch: 0

  property string frontLeftFlipperJoint: ""
  property string frontRightFlipperJoint: ""
  property string backLeftFlipperJoint: ""
  property string backRightFlipperJoint: ""
  property real frontLeftFlipperJointOffset: 0
  property real frontLeftFlipperJointMultiplier: 1
  property real frontLeftFlipperJointValue: 0
  property real frontRightFlipperJointOffset: 0
  property real frontRightFlipperJointMultiplier: 1
  property real frontRightFlipperJointValue: 0
  property real backLeftFlipperJointOffset: 0
  property real backLeftFlipperJointMultiplier: 1
  property real backLeftFlipperJointValue: 0
  property real backRightFlipperJointOffset: 0
  property real backRightFlipperJointMultiplier: 1
  property real backRightFlipperJointValue: 0

  // Repaint on change
  onPitchChanged: robotCanvas.requestPaint()
  onFrontLeftFlipperJoint: robotCanvas.requestPaint()
  onFrontRightFlipperJoint: robotCanvas.requestPaint()
  onBackLeftFlipperJoint: robotCanvas.requestPaint()
  onBackRightFlipperJoint: robotCanvas.requestPaint()
  onFrontLeftFlipperJointOffset: robotCanvas.requestPaint()
  onFrontLeftFlipperJointMultiplier: robotCanvas.requestPaint()
  onFrontLeftFlipperJointValue: robotCanvas.requestPaint()
  onFrontRightFlipperJointOffset: robotCanvas.requestPaint()
  onFrontRightFlipperJointMultiplier: robotCanvas.requestPaint()
  onFrontRightFlipperJointValue: robotCanvas.requestPaint()
  onBackLeftFlipperJointOffset: robotCanvas.requestPaint()
  onBackLeftFlipperJointMultiplier: robotCanvas.requestPaint()
  onBackLeftFlipperJointValue: robotCanvas.requestPaint()
  onBackRightFlipperJointOffset: robotCanvas.requestPaint()
  onBackRightFlipperJointMultiplier: robotCanvas.requestPaint()
  onBackRightFlipperJointValue: robotCanvas.requestPaint()

  //! If true will use rviz properties instead of the properties above
  property bool useRvizProperties: false
  //! If true will subscribe to the /joint_state topic to obtain the joint state values for each flipper joint
  property alias subscribeJointStates: jointStateSubscriber.running

  Subscriber {
    id: jointStateSubscriber
    topic: "/joint_states"
    onNewMessage: {
      if (!message.name) return
      var names = message.name.toArray()
      var index = names.indexOf(control.frontLeftFlipperJoint)
      if (index !== -1) {
        control.frontLeftFlipperJointValue = control.frontLeftFlipperJointOffset + message.position.at(index) * control.frontLeftFlipperJointMultiplier
      }
      var index = names.indexOf(control.frontRightFlipperJoint)
      if (index !== -1) {
        control.frontRightFlipperJointValue = control.frontRightFlipperJointOffset + message.position.at(index) * control.frontRightFlipperJointMultiplier
      }
      var index = names.indexOf(control.backLeftFlipperJoint)
      if (index !== -1) {
        control.backLeftFlipperJointValue = control.backLeftFlipperJointOffset + message.position.at(index) * control.backLeftFlipperJointMultiplier
      }
      var index = names.indexOf(control.backRightFlipperJoint)
      if (index !== -1) {
        control.backRightFlipperJointValue = control.backRightFlipperJointOffset + message.position.at(index) * control.backRightFlipperJointMultiplier
      }
    }
  }

  QtObject {
    id: d
    // In scale 1, width is at most (flat flippers) 196 + 2 * 8 (padding) = 212
    property real scale: Math.min(control.width / 196, control.height / 196)

    // Rviz stuff
    property var rvizPropertyContainer: control.useRvizProperties && rviz && rviz.registerPropertyContainer("Robot Orientation View", "Settings for the robot orientation view")

    function registerStringProperty(name, callback) {
      if (!control.useRvizProperties || !rviz) return null
      var prop = rviz.registerStringProperty(rvizPropertyContainer, name, "")
      prop.valueChanged.connect(callback)
      callback(prop.value)
      return prop
    }
    property var frontLeftFlipperJointProperty: registerStringProperty("Front Left Flipper Joint", function (value) { control.frontLeftFlipperJoint = value })
    property var frontRightFlipperJointProperty: registerStringProperty("Front Right Flipper Joint", function (value) { control.frontRightFlipperJoint = value })
    property var backLeftFlipperJointProperty: registerStringProperty("Back Left Flipper Joint", function (value) { control.backLeftFlipperJoint = value })
    property var backRightFlipperJointProperty: registerStringProperty("Back Right Flipper Joint", function (value) { control.backRightFlipperJoint = value })
    // Offsets
    property var rvizOffsetPropertyContainer: control.useRvizProperties && rvizPropertyContainer && rviz.registerPropertyContainer(rvizPropertyContainer, "Offsets")
    function registerOffsetProperty(name, defaultValue, callback) {
      if (!control.useRvizProperties || !rviz) return null
      var prop = rviz.registerFloatProperty(rvizOffsetPropertyContainer, name, defaultValue)
      prop.valueChanged.connect(callback)
      callback(prop.value)
      return prop
    }
    property var frontLeftFlipperJointOffsetProperty: registerOffsetProperty("Front Left Offset", 0, function (value) { control.frontLeftFlipperJointOffset = value })
    property var frontLeftFlipperJointMultiplierProperty: registerOffsetProperty("Front Left Multiplier", 1, function (value) { control.frontLeftFlipperJointMultiplier = value })
    property var frontRightFlipperJointOffsetProperty: registerOffsetProperty("Front Right Offset", 0, function (value) { control.frontRightFlipperJointOffset = value })
    property var frontRightFlipperJointMultiplierProperty: registerOffsetProperty("Front Right Multiplier", 1, function (value) { control.frontRightFlipperJointMultiplier = value })
    property var backLeftFlipperJointOffsetProperty: registerOffsetProperty("Back Left Offset", 0, function (value) { control.backLeftFlipperJointOffset = value })
    property var backLeftFlipperJointMultiplierProperty: registerOffsetProperty("Back Left Multiplier", 1, function (value) { control.backLeftFlipperJointMultiplier = value })
    property var backRightFlipperJointOffsetProperty: registerOffsetProperty("Back Right Offset", 0, function (value) { control.backRightFlipperJointOffset = value })
    property var backRightFlipperJointMultiplierProperty: registerOffsetProperty("Back Right Multiplier", 1, function (value) { control.backRightFlipperJointMultiplier = value })

    onScaleChanged: robotCanvas.requestPaint()

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

  Canvas {
    id: robotCanvas
    anchors.fill: parent
    contextType: "2d"
    onPaint: {
      if (!context) return // Wait for context to be valid
      context.save()
      context.reset()
      var scale = d.scale
      // Center and scale to fill
      context.translate(control.width / 2, control.height / 2)
      context.rotate(control.pitch)
      context.scale(scale, scale)
      context.translate(-61, -48)

      // Draw left flippers
      context.save()
      context.fillStyle = Qt.rgba(0.8, 0.8, 0.8, 1)
      context.strokeStyle = Qt.rgba(0, 0, 0, 1)
      context.lineWidth = 4
      if (control.backLeftFlipperJoint) {
        context.save()
        context.translate(16, 45)
        context.rotate(control.backLeftFlipperJointValue)
        context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
        context.fill()
        context.stroke()
        context.restore()
      }
      
      if (control.frontLeftFlipperJoint) {
        context.save()
        context.translate(112, 45)
        context.rotate(-control.frontLeftFlipperJointValue)
        context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
        context.fill()
        context.stroke()
        context.restore()
      }
      context.restore()
      
      // Draw robot
      context.fillStyle = Qt.rgba(0.69, 0.69, 0.69, 1)
      context.path = "m 25.567835,24.392139 h 80.864325 c 4.19258,0 7.56784,2.89307 7.56784,6.48671 v 23.02657 c 0,3.59364 -3.37526,6.48672 -7.56784,6.48672 H 25.567835 c -4.192581,0 -7.567837,-2.89308 -7.567837,-6.48672 v -23.02657 c 0,-3.59364 3.375256,-6.48671 7.567837,-6.48671 z"
      context.fill()
      // Draw tracks
      context.path = "M 15.865234 30 C 7.0939123 30 0 37.093912 0 45.865234 L 0 48.134766 C 0 56.906088 7.0939123 64 15.865234 64 L 116.13477 64 C 124.90609 64 132 56.906088 132 48.134766 L 132 45.865234 C 132 37.093912 124.90609 30 116.13477 30 L 15.865234 30 z M 15.865234 32.119141 L 116.13477 32.119141 C 123.76876 32.119141 129.88086 38.231245 129.88086 45.865234 L 129.88086 48.134766 C 129.88086 55.768755 123.76876 61.880859 116.13477 61.880859 L 15.865234 61.880859 C 8.2312446 61.880859 2.1191406 55.768755 2.1191406 48.134766 L 2.1191406 45.865234 C 2.1191406 38.231245 8.2312446 32.119141 15.865234 32.119141 z"
      context.fillStyle = Qt.rgba(0.69, 0.69, 0.69, 1)
      context.fill()
      context.fillStyle = Qt.rgba(0, 0, 0, 1)
      context.strokeStyle = Qt.rgba(0, 0, 0, 1)
      context.lineWidth = 2
      context.fill()
      context.stroke()


      // Draw right flippers
      context.save()
      context.fillStyle = Qt.rgba(0.8, 0.8, 0.8, 1)
      context.strokeStyle = Qt.rgba(0, 0, 0, 1)
      context.lineWidth = 4
      if (control.backRightFlipperJoint) {
        context.save()
        context.translate(16, 45)
        context.rotate(control.backRightFlipperJointValue)
        context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
        context.fill()
        context.stroke()
        context.restore()
      }
      
      if (control.frontRightFlipperJoint) {
        context.save()
        context.translate(112, 45)
        context.rotate(-control.frontRightFlipperJointValue)
        context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
        context.fill()
        context.stroke()
        context.restore()
      }
      context.restore()
    }
  }
}
