import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtMultimedia 5.4
import Ros2 1.0
import Hector.CameraServer 1.0
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

  function hide()  {
    control.backRequested()
  }

  clip: true

  onConfigurationChanged: {
    if (ObjectUtils.deepEquals(d.configuration, configuration)) return
    cameraView.source = d.createSource(control)
    d.configuration = configuration
  }

  Component {
    id: cameraStreamComponent
    CameraStream {}
  }

  QtObject {
    id: d
    property var configuration: null
    function createSource(parent) {
      const config = control.configuration
      if (!config) return null
      return cameraStreamComponent.createObject(parent, {'robot': config.robot, 'cameraId': config.cameraId})
    }
  }

  CameraViewImpl {
    id: cameraView
    anchors.fill: parent
    name: control.configuration && control.configuration.name || ""

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
      popoutCameraView.source = d.createSource(popoutCameraView)
      popoutWindow.show()
    }
  }

  Window {
    id: popoutWindow
    title: control.name
    width: 640
    height: 480
    CameraViewImpl {
      id: popoutCameraView
      anchors.fill: parent
      canGoBack: false
      allowPopout: false
    }
  }
}