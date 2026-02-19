import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtMultimedia 5.4
import Ros2 1.0
import Ros2.CameraServer 1.0
import Hector.Icons 1.0
import Hector.Utils 1.0
import "internal"

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

  property alias name: cameraView.name
  property alias nameFont: cameraView.nameFont
  property alias orientation: cameraView.orientation

  property var configuration
  property alias showFramerate: cameraView.showFramerate
  property alias showLatency: cameraView.showLatency
  property alias controlsState: cameraView.controlsState

  signal backRequested()

  function hide() {
    control.backRequested()
  }

  clip: true

  CameraStream {
    id: stream
    robot: control.configuration ? control.configuration.robot : ""
    cameraId: control.configuration ? control.configuration.cameraId : ""
    streamIndex: control.configuration && control.configuration.streamIndex !== undefined ? control.configuration.streamIndex : -1
    enabled: control.enabled
    preferredSize: Qt.size(cameraView.width, cameraView.height)
  }

  CameraViewImpl {
    id: cameraView
    anchors.fill: parent
    name: control.configuration ? control.configuration.name || "" : ""
    stream: stream

    enabled: control.enabled
    transitionsEnabled: control.transitionsEnabled
    canGoBack: control.canGoBack
    showControls: control.showControls
    allowPause: control.allowPause
    allowPopout: control.allowPopout
    allowFullscreen: control.allowFullscreen
    fullscreen: control.fullscreen
    autoHideControls: control.autoHideControls

    onBackRequested: control.backRequested()

    onPopout: {
      popoutStream.robot = stream.robot
      popoutStream.cameraId = stream.cameraId
      popoutStream.streamIndex = stream.streamIndex
      popoutStream.enabled = true
      popoutWindow.show()
    }
  }

  Window {
    id: popoutWindow
    title: control.name
    width: 640
    height: 480
    onClosing: popoutStream.enabled = false

    CameraStream {
      id: popoutStream
      enabled: false
      preferredSize: Qt.size(popoutCameraView.width, popoutCameraView.height)
    }

    CameraViewImpl {
      id: popoutCameraView
      anchors.fill: parent
      stream: popoutStream
      canGoBack: false
      allowPopout: false
    }
  }
}