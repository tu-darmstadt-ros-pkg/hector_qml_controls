import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtMultimedia 5.4
import Ros2 1.0
import Hector.Icons 1.0
import Hector.Utils 1.0

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

  property alias showFramerate: framerateRectangle.visible
  property alias showLatency: latencyRectangle.visible
  property alias controlsState: cameraControls.state
  property alias source: videoOutput.source

  signal backRequested()
  signal popout()

  function hide()  {
    control.backRequested()
  }

  clip: true
  onAutoHideControlsChanged: {
    if (!autoHideControls) controlsState = "default"
  }
  onFullscreenChanged: {
    if (fullscreen && parent != ApplicationWindow.overlay) {
      d.parent = parent
      parent = ApplicationWindow.overlay
      fullscreen = true
    } else {
      parent = d.parent
      fullscreen = false
    }
  }

  QtObject {
    id: d

    property bool clickToggled: false
    property bool showBackButton: control.canGoBack && !control.fullscreen
    property QtObject parent
    property var fill
    property string state: {
      if (!control.showControls) return "hidden"
      if (!control.autoHideControls || clickToggled || controlsMouseArea.containsMouse) return "default"
      return "hidden"
    }
    property bool canPause: control.allowPause && videoOutput.source && videoOutput.source.pause
    property bool isPaused: false
    property var conn: Connections {
      target: videoOutput.source
      onPlaybackStateChanged: d.isPaused = control.allowPause && videoOutput.source.playbackState != MediaPlayer.PlayingState
    } 
  }

  Rectangle {
    anchors.fill: parent
    color: "black"
  }

  VideoOutput {
    id: videoOutput
    anchors.fill: parent
    onSourceChanged: source && source.init && source.init()
  }

  MouseArea {
    id: controlsMouseArea
    anchors.fill: parent
    hoverEnabled: control.autoHideControls
    onClicked: d.clickToggled = !d.clickToggled
    Item {
      id: cameraControls
      anchors.fill: parent
      state: d.state

      states: [
        State {
          name: "default"
          PropertyChanges { target: controlsLayout; anchors.topMargin: Units.pt(4) }
          PropertyChanges { target: latencyRectangle; anchors.bottomMargin: 0 }
          PropertyChanges { target: framerateRectangle; anchors.bottomMargin: 0 }
        },
        State {
          name: "hidden"
          PropertyChanges { target: controlsLayout; anchors.topMargin: -controlsLayout.height - 1 }
          PropertyChanges { target: latencyRectangle; anchors.bottomMargin: -latencyRectangle.height - 1 }
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
            PropertyAnimation { target: latencyRectangle; properties: "anchors.bottomMargin"; easing.type: Easing.InOutQuad }
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
        state: (d.state == "hidden" || !d.showBackButton) ? "nameOnly" : "full"

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

          TextMetrics {
            id: nameLabelMetrics
            font: nameLabel.font
            text: nameLabel.text
          }
        }
      }
    }

    RowLayout {
      id: controlsLayout
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Units.pt(4)

      RoundButton {
        padding: 0
        visible: d.canPause
        
        Text {
          anchors.centerIn: parent
          font.family: HectorIcons.fontFamily
          text: d.isPaused ? HectorIcons.play : HectorIcons.pause
          color: "#ffffff"
        }

        background: Rectangle {
          implicitHeight: nameLabel.implicitHeight
          implicitWidth: nameLabel.implicitHeight
          radius: width / 2
          color: "#444444"
          opacity: parent.down ? 1 : parent.hovered ? 0.8 : 0.6
        }

        onClicked: d.isPaused ? control.source.play() : control.source.pause()
      }

      RoundButton {
        padding: 0
        visible: control.allowPopout
        
        Text {
          anchors.centerIn: parent
          font.family: HectorIcons.fontFamily
          text: HectorIcons.popout
          color: "#ffffff"
        }

        background: Rectangle {
          implicitHeight: nameLabel.implicitHeight
          implicitWidth: nameLabel.implicitHeight
          radius: width / 2
          color: "#444444"
          opacity: parent.down ? 1 : parent.hovered ? 0.8 : 0.6
        }

        onClicked: control.popout()

      }

      RoundButton {
        padding: 0
        visible: control.fullscreen || control.allowFullscreen
        
        Text {
          anchors.centerIn: parent
          font.family: HectorIcons.fontFamily
          text: control.fullscreen ? HectorIcons.exitFullscreen : HectorIcons.fullscreen
          color: "#ffffff"
        }

        background: Rectangle {
          implicitHeight: nameLabel.implicitHeight
          implicitWidth: nameLabel.implicitHeight
          radius: width / 2
          color: "#444444"
          opacity: parent.down ? 1 : parent.hovered ? 0.8 : 0.6
        }

        onClicked: control.fullscreen = !control.fullscreen
      }
    }

    // Stats
    Rectangle {
      id: latencyRectangle
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.bottomMargin: -height - 1
      color: "#aa444444"
      implicitWidth: latencyText.implicitWidth + Units.pt(8)
      implicitHeight: latencyText.implicitHeight + Units.pt(4)
      MouseArea {
        id: latencyMouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
      }

      Text {
        id: latencyText
        anchors.centerIn: parent

        function displayLatency(latency) {
          if (!latency || latency == -1) return 'Unknown'
          return latency + 'ms'
        }

        text: displayLatency(videoOutput.source && videoOutput.source.latency)
        color: "white"

        ToolTip.text: "Network Latency: " + displayLatency(videoOutput.source && videoOutput.source.networkLatency) + "\n" +
                      "Processing Latency: " + displayLatency(videoOutput.source && videoOutput.source.processingLatency)
        ToolTip.visible: latencyMouseArea.containsMouse
        ToolTip.delay: 500
      }
    }

    Rectangle {
      id: framerateRectangle
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.bottomMargin: -height - 1
      color: "#aa444444"
      implicitWidth: framerateText.implicitWidth + Units.pt(8)
      implicitHeight: framerateText.implicitHeight + Units.pt(4)

      Text {
        id: framerateText
        anchors.centerIn: parent
        text: (videoOutput.source && videoOutput.source.framerate || 0).toFixed(0) + "FPS"
        color: "white"
      }
    }
  }
}