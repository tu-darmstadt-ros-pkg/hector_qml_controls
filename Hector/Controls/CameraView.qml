import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtMultimedia 5.4
import Ros 1.0
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
  property real throttleRate: 0
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
    id: imageSubscriberComponent
    ImageTransportSubscriber {
      throttleRate: control.throttleRate
    }
  }

  Component {
    id: rtspComponent
    MediaPlayer {
      property string rtsp
      property string codec
      muted: true
      function init() {
        let pipeline = `gst-pipeline: rtspsrc location="${rtsp}" ! `
        if (codec == "h265") pipeline += "rtph265depay ! h265parse"
        else pipeline += "rtph264depay ! h264parse"
        pipeline += " ! decodebin ! autovideosink name=qtvideosink sync=false"
        source = pipeline
        play()
      }

      property Timer timer: Timer {
        running: parent.status == MediaPlayer.InvalidMedia; repeat: true; interval: 200
        onTriggered: parent.play()
      }
    }
  }

  QtObject {
    id: d
    property var configuration: null
    function createSource(parent) {
      const config = control.configuration
      if (!config) return null
      if (!config.type || config.type == "ROS")
        return imageSubscriberComponent.createObject(parent, {'topic': config.topic, 'defaultTransport': config.transport || "compressed"})
      return rtspComponent.createObject(parent, {'rtsp': config.url, 'codec': config.codec})
    }
  }

  CameraViewImpl {
    id: cameraView
    anchors.fill: parent

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