import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia
import Ros2
import Hector.Icons
import Hector.Utils
import ".."

Item {
  id: control
  //! Whether the camera view is enabled (may subscribe to images)
  property bool enabled: true
  property bool transitionsEnabled: true
  property bool canGoBack: false
  property bool showControls: true
  property bool allowPause: true
  property bool allowPopout: true
  property bool allowFullscreen: true
  property bool fullscreen: false
  //! Hide controls unless mouse is over camera
  property bool autoHideControls: true

  property alias name: nameLabel.text
  property alias nameFont: nameLabel.font
  property alias orientation: videoOutput.orientation

  //! The CameraStream that provides the video feed and latency info
  property var stream: null

  property alias showFramerate: framerateRectangle.visible
  property alias showLatency: latencyRectangle.visible
  property alias controlsState: cameraControls.state

  signal backRequested()
  signal popout()

  function hide() {
    control.backRequested()
  }

  clip: true
  onAutoHideControlsChanged: {
    if (!autoHideControls) controlsState = "default"
  }
  onFullscreenChanged: {
    // T.Overlay.overlay is null while the view has no window, reparenting to null would make the
    // view vanish irrecoverably
    const overlay = T.Overlay.overlay
    if (fullscreen && overlay && parent != overlay) {
      d.previousParent = parent
      parent = overlay
      fullscreen = true
    } else if (!fullscreen && d.previousParent) {
      parent = d.previousParent
    }
  }

  QtObject {
    id: d

    property bool clickToggled: false
    property bool showBackButton: control.canGoBack && !control.fullscreen
    property QtObject previousParent
    property string controlsVisibility: {
      if (!control.showControls) return "hidden"
      if (!control.autoHideControls || clickToggled || controlsMouseArea.containsMouse) return "default"
      return "hidden"
    }
    property bool isPaused: false
    property int latency: control.stream ? control.stream.latency : -1
  }

  Rectangle {
    anchors.fill: parent
    color: "black"
  }

  VideoOutput {
    id: videoOutput
    anchors.fill: parent
  }

  Binding {
    target: control.stream
    property: "videoSink"
    value: videoOutput.videoSink
  }

  // Latency overlay — semi-transparent pill, always in bottom-right to stay visible without blocking the view
  Rectangle {
    id: latencyRectangle
    visible: true
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Units.pt(6)
    radius: height / 2
    color: d.latency < 0 ? "#88666666"
         : d.latency < 100 ? "#8800aa00"
         : d.latency < 300 ? "#88ddaa00"
         : "#88dd3300"
    implicitWidth: latencyText.implicitWidth + Units.pt(12)
    implicitHeight: latencyText.implicitHeight + Units.pt(6)
    opacity: controlsMouseArea.containsMouse || d.clickToggled ? 0.95 : 0.6
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 300 } }

    Text {
      id: latencyText
      anchors.centerIn: parent
      text: d.latency >= 0 ? d.latency + " ms" : "—"
      color: "white"
      font.pointSize: 9
    }
  }

  MouseArea {
    id: controlsMouseArea
    anchors.fill: parent
    hoverEnabled: control.autoHideControls
    onClicked: d.clickToggled = !d.clickToggled

    Item {
      id: cameraControls
      anchors.fill: parent
      state: d.controlsVisibility

      states: [
        State {
          name: "default"
          PropertyChanges { target: controlsLayout; anchors.topMargin: Units.pt(4) }
          PropertyChanges { target: framerateRectangle; anchors.bottomMargin: 0 }
        },
        State {
          name: "hidden"
          PropertyChanges { target: controlsLayout; anchors.topMargin: -controlsLayout.height - 1 }
          PropertyChanges { target: framerateRectangle; anchors.bottomMargin: -framerateRectangle.height - 1 }
        }
      ]

      transitions: [
        Transition {
          from: "default"
          to: "hidden"
          reversible: true
          enabled: control.transitionsEnabled
          ParallelAnimation {
            PropertyAnimation { target: controlsLayout; properties: "anchors.topMargin"; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: framerateRectangle; properties: "anchors.bottomMargin"; easing.type: Easing.InOutQuad }
          }
        }
      ]

      Rectangle {
        id: labelBackground
        x: -backButton.width - backLayout.spacing
        y: Units.pt(4)
        implicitHeight: backLayout.height
        implicitWidth: backLayout.width
        color: nameLabel.text ? "#aa444444" : "transparent"
        state: (d.controlsVisibility == "hidden" || !d.showBackButton) ? "nameOnly" : "full"

        states: [
          State {
            name: "full"
            PropertyChanges { target: labelBackground; x: 0 }
          },
          State {
            name: "nameOnly"
            PropertyChanges { target: labelBackground; x: -backButton.width - backLayout.spacing }
          }
        ]

        transitions: [
          Transition {
            from: "full"
            to: "nameOnly"
            reversible: true
            enabled: control.transitionsEnabled
            ParallelAnimation {
              PropertyAnimation { target: labelBackground; properties: "x"; easing.type: Easing.InOutQuad }
            }
          }
        ]

        RowLayout {
          id: backLayout
          spacing: Units.pt(4)

          // Back button
          RoundButton {
            id: backButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: height
            Layout.preferredHeight: nameLabel.implicitHeight * 0.8
            Layout.leftMargin: Units.pt(4)
            text: "\u2794"
            font { pointSize: control.nameFont.pointSize * 0.8 }
            rotation: 180
            onClicked: control.backRequested()
          }

          Text {
            id: nameLabel
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Units.pt(4)
            Layout.maximumWidth: control.width * 2 / 3
            Layout.preferredWidth: implicitWidth + Units.pt(font.pointSize) / 4
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1
            elide: Text.ElideRight
            color: "white"
            font { pointSize: 16 }
          }
        }
      }
    }

    RowLayout {
      id: controlsLayout
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Units.pt(4)

      OverlayIconButton {
        implicitWidth: nameLabel.implicitHeight
        visible: control.allowPause && !!control.stream
        text: d.isPaused ? HectorIcons.play : HectorIcons.pause

        onClicked: {
          if (!control.stream) return
          d.isPaused ? control.stream.play() : control.stream.pause()
          d.isPaused = !d.isPaused
        }
      }

      OverlayIconButton {
        implicitWidth: nameLabel.implicitHeight
        visible: control.allowPopout
        text: HectorIcons.popout
        onClicked: control.popout()
      }

      OverlayIconButton {
        implicitWidth: nameLabel.implicitHeight
        visible: control.fullscreen || control.allowFullscreen
        text: control.fullscreen ? HectorIcons.exitFullscreen : HectorIcons.fullscreen
        onClicked: control.fullscreen = !control.fullscreen
      }
    }

    // Framerate indicator
    Rectangle {
      id: framerateRectangle
      visible: false
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.bottomMargin: -height - 1
      color: "#aa444444"
      implicitWidth: framerateText.implicitWidth + Units.pt(8)
      implicitHeight: framerateText.implicitHeight + Units.pt(4)

      Text {
        id: framerateText
        anchors.centerIn: parent
        text: (control.stream && control.stream.framerate || 0).toFixed(0) + " FPS"
        color: "white"
      }
    }
  }
}