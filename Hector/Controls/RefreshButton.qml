import QtQuick 2.3
import QtQuick.Controls 2.2
import Hector.Icons 1.0

Button {
  id: control
  property bool animate
  onAnimateChanged: {
    if (!animate) return
    reloadRotationAnimator.running = true
  }
  Text {
    id: reloadIcon
    anchors.centerIn: control
    width: Math.min(control.width - control.padding, control.height - control.padding)
    height: width
    font.family: HectorIcons.fontFamily
    font.pointSize: 1000
    text: HectorIcons.refresh
    minimumPointSize: 4
    fontSizeMode: Text.Fit
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    SequentialAnimation {
      id: reloadRotationAnimator
      loops: Animation.Infinite
      running: false

      RotationAnimation {
      target: reloadIcon
      from: 0; to: 720
      duration: 1000
      easing.type: Easing.InOutQuad
      }
      PauseAnimation { duration: 500 }
      // Check if we should rotate another time
      ScriptAction {
        script: {
          if (control.animate) return
          reloadRotationAnimator.running = false
        }
      }
    }
  }
}
