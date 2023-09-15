pragma Singleton
import QtQuick 2.5
import QtQuick.Window 2.0

Object {
  readonly property real pixelsPerMM: Screen.pixelDensity * Screen.devicePixelRatio
  //readonly property real pixelsPerPoint: pixelsPerMM * 25.4 / 72 /* 25.4 = mm per inch, 1 pt = 1/72 in (DTP point) */
  readonly property real pixelsPerPoint: metrics.height / 1000

  FontMetrics {
    id: metrics
    font.pointSize: 1000
  }
  
  function pt(pointSize) {
    return pointSize * pixelsPerPoint
  }

  function toPt(pixelSize) {
    return pixelSize / pixelsPerPoint
  }
  
  // density points as a scaling independent size
  function dp(size) {
    return size * pixelsPerPoint
  }

  function toDp(pixelSize) {
    return pixelSize / pixelsPerPoint
  }
}
