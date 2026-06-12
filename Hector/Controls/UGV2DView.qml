import QtQuick 2.0
import QtQuick.Controls 2.1
import Hector.Controls 1.0
import Ros2 1.0

// Schematic 2D side-on view of an unmanned ground vehicle showing its pitch and,
// for tracked robots, the orientation of its flippers. The flipper angles are read
// from tf: each flipper link frame's orientation relative to the robot base frame.
Item {
  id: control
  //! Robot body pitch (rad), e.g. derived from an IMU. Rotates the whole drawing.
  property real pitch: 0

  //! Robot type (RobotType.Value). Tracked draws tracks + flippers, anything else a wheeled body.
  property int type: RobotType.Unknown
  //! Already-prefixed flipper link frames. 4 frames = [FL,FR,BR,BL] clockwise from above;
  //! 2 frames = [front,back] (front/back pairs linked). Empty for non-tracked robots.
  property var flipperFrames: []
  //! Already-prefixed base frame the flipper orientation is measured against.
  property string baseFrame: ""

  readonly property bool tracked: type === RobotType.Tracked

  // Normalize the 2-vs-4 flipper frame list into fixed corner slots once.
  QtObject {
    id: ff
    readonly property string fl: control.flipperFrames.length >= 4 ? control.flipperFrames[0]
                              : control.flipperFrames.length === 2 ? control.flipperFrames[0] : ""
    readonly property string fr: control.flipperFrames.length >= 4 ? control.flipperFrames[1]
                              : control.flipperFrames.length === 2 ? control.flipperFrames[0] : ""
    readonly property string br: control.flipperFrames.length >= 4 ? control.flipperFrames[2]
                              : control.flipperFrames.length === 2 ? control.flipperFrames[1] : ""
    readonly property string bl: control.flipperFrames.length >= 4 ? control.flipperFrames[3]
                              : control.flipperFrames.length === 2 ? control.flipperFrames[1] : ""
  }

  TfTransform { id: tfFL; enabled: control.tracked && ff.fl !== ""; sourceFrame: ff.fl; targetFrame: control.baseFrame }
  TfTransform { id: tfFR; enabled: control.tracked && ff.fr !== ""; sourceFrame: ff.fr; targetFrame: control.baseFrame }
  TfTransform { id: tfBR; enabled: control.tracked && ff.br !== ""; sourceFrame: ff.br; targetFrame: control.baseFrame }
  TfTransform { id: tfBL; enabled: control.tracked && ff.bl !== ""; sourceFrame: ff.bl; targetFrame: control.baseFrame }

  // Repaint on body pitch change. tf updates are coalesced by the timer below since a TfTransform
  // only emits rotationChanged on the valid path (missing valid->invalid transitions).
  onPitchChanged: robotCanvas.requestPaint()
  onTypeChanged: robotCanvas.requestPaint()
  onFlipperFramesChanged: robotCanvas.requestPaint()

  Timer {
    interval: 32; running: true; repeat: true
    onTriggered: robotCanvas.requestPaint()
  }

  QtObject {
    id: d
    // In scale 1, width is at most (flat flippers) 196 + 2 * 8 (padding) = 212
    property real scale: Math.min(control.width / 196, control.height / 196)
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

    // Full-range rotation angle (rad) about the Y (pitch) axis via swing-twist decomposition.
    // The asin-based extractPitch is the aerospace-Euler pitch, which saturates at ±90° and folds
    // back beyond it (flipper appears to reverse direction). A flipper is a revolute joint about Y,
    // so 2*atan2(y, w) recovers its angle monotonically through a full turn.
    function twistAroundY(q) {
      return 2 * Math.atan2(q.y, q.w)
    }

    // Flipper angle (rad) from a tf transform, or 0 if no valid transform is available.
    function flipperAngle(tf) { return tf.valid ? 4.71 - twistAroundY(tf.rotation) : 0 }
  }

  Canvas {
    id: robotCanvas
    anchors.fill: parent
    contextType: "2d"
    onPaint: {
      if (!context) return // Wait for context to be valid
      context.save()
      context.reset()
      var scale = d.scale * (control.tracked ? 1 : 1.3) // Scale up wheeled as it's more compact
      // Center and scale to fill
      context.translate(control.width / 2, control.height / 2)
      context.rotate(control.pitch)

      // Direction indicators at the chassis center, drawn before context.scale so they keep a fixed
      // on-screen size (the same for every robot/view) instead of being scaled to fit, and drawn first
      // so the chassis occludes their tails. Red = forward (+x), blue = up (-y); the tails are cut
      // along the NE-SW diagonal through the origin so they meet on an angled seam, not as squares.
      context.save()
      context.scale(0.5, 0.5)
      context.fillStyle = Qt.rgba(0.85, 0, 0, 1)
      context.path = "M 4,-4 L 83.2,-4 L 83.2,-10 L 101.2,0 L 83.2,10 L 83.2,4 L -4,4 Z"
      context.fill()
      context.fillStyle = Qt.rgba(0, 0.3, 0.9, 1)
      context.path = "M -4,4 L -4,-39.6 L -10,-39.6 L 0,-57.6 L 10,-39.6 L 4,-39.6 L 4,-4 Z"
      context.fill()
      context.restore()

      context.scale(scale, scale)
      context.translate(-61, -48)

      // Draw left flippers (tracked only)
      if (control.tracked) {
        context.save()
        context.fillStyle = Qt.rgba(0.8, 0.8, 0.8, 1)
        context.strokeStyle = Qt.rgba(0, 0, 0, 1)
        context.lineWidth = 4
        if (tfBL.valid) {
          context.save()
          context.translate(16, 45)
          context.rotate(d.flipperAngle(tfBL))
          context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
          context.fill()
          context.stroke()
          context.restore()
        }

        if (tfFL.valid) {
          context.save()
          context.translate(112, 45)
          context.rotate(-d.flipperAngle(tfFL))
          context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
          context.fill()
          context.stroke()
          context.restore()
        }
        context.restore()
      }

      // Draw robot body
      context.fillStyle = Qt.rgba(0.69, 0.69, 0.69, 1)
      context.path = "m 25.567835,24.392139 h 80.864325 c 4.19258,0 7.56784,2.89307 7.56784,6.48671 v 23.02657 c 0,3.59364 -3.37526,6.48672 -7.56784,6.48672 H 25.567835 c -4.192581,0 -7.567837,-2.89308 -7.567837,-6.48672 v -23.02657 c 0,-3.59364 3.375256,-6.48671 7.567837,-6.48671 z"
      context.fill()

      if (control.tracked) {
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
        if (tfBR.valid) {
          context.save()
          context.translate(16, 45)
          context.rotate(d.flipperAngle(tfBR))
          context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
          context.fill()
          context.stroke()
          context.restore()
        }

        if (tfFR.valid) {
          context.save()
          context.translate(112, 45)
          context.rotate(-d.flipperAngle(tfFR))
          context.path = "m 1.184368,-44.456489 c 8.877153,0 10.657733,6.814691 11.784127,15.122534 L 17.208109,1.9357999 C 18.334504,10.243646 10.061521,17.058335 1.184368,17.058335 c -8.8771533,0 -17.150137,-6.814689 -16.023742,-15.1225351 l 4.239615,-31.2697549 c 1.1263935,-8.307843 2.9069737,-15.122534 11.784127,-15.122534 z"
          context.fill()
          context.stroke()
          context.restore()
        }
        context.restore()
      } else {
        // Wheeled robot: draw wheels at the front and back instead of tracks/flippers.
        context.fillStyle = Qt.rgba(0.15, 0.15, 0.15, 1)
        context.strokeStyle = Qt.rgba(0, 0, 0, 1)
        context.lineWidth = 2
        const wheelRadius = 16
        const wheelXs = [20, 108] // back, front (matches the flipper mount positions)
        for (let i = 0; i < wheelXs.length; ++i) {
          context.beginPath()
          context.ellipse(wheelXs[i] - wheelRadius, 64 - wheelRadius, 2 * wheelRadius, 2 * wheelRadius)
          context.fill()
          context.stroke()
        }
      }

      context.restore()
    }
  }
}
