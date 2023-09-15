import QtQuick 2.5
import QtQuick.Controls 2.1

MouseArea {
  id: root

  enum Border {
    Left = 1,
    Right = 2,
    Top = 4,
    Bottom = 8
  }

  enum Mode {
    // Will resize the item in all directions keeping the mouse on the border
    Item,
    // Will only resize but not change the location of the item if necessary
    SizeOnly
  }


  property QtObject target
  property real minimumWidth: 20
  property real minimumHeight: 20
  // -1 sets it to auto which means it can grow to the size of its parent
  property real maximumWidth: -1
  property real maximumHeight: -1
  property int resizeBorder: ResizeHandle.Border.Left
  property int resizeMode: ResizeHandle.Item
  property bool enabled: true
  property bool active: false

  hoverEnabled: true
  cursorShape: {
    if (!d.hasBorderFlag(ResizeHandle.Border.Top) && !d.hasBorderFlag(ResizeHandle.Border.Bottom)) {
      return Qt.SizeHorCursor
    }
    if (!d.hasBorderFlag(ResizeHandle.Border.Left) && !d.hasBorderFlag(ResizeHandle.Border.Right)) {
      return Qt.SizeVerCursor
    }
    return (resizeBorder == 6 || resizeBorder == 9) ? Qt.SizeBDiagCursor : Qt.SizeFDiagCursor
  }

  QtObject {
    id: d
    property point startMouse
    property rect startRect
    property real maximumHeight: root.maximumHeight == -1 ? target.parent && target.parent.height : root.maximumHeight
    property real maximumWidth: root.maximumWidth == -1 ? target.parent && target.parent.width : root.maximumWidth 

    function hasBorderFlag(flag) {
      return (root.resizeBorder&flag) == flag
    }
  }

  onPressed: {
    if (!root.enabled) return
    active = true
    d.startRect.x = target.x
    d.startRect.y = target.y
    d.startRect.width = target.width
    d.startRect.height = target.height
    d.startMouse = mapToItem(target.parent, mouse.x, mouse.y)
  }
  onReleased: active = false
  onCanceled: active = false
  onPositionChanged: {
    if (!active) return
    var pos = mapToItem(target.parent, mouse.x, mouse.y)
    if (d.hasBorderFlag(ResizeHandle.Border.Left) || d.hasBorderFlag(ResizeHandle.Border.Right)) {
      // Resize horizontal
      let diffX = d.hasBorderFlag(ResizeHandle.Border.Left) ? d.startMouse.x - pos.x : pos.x - d.startMouse.x
      let width = d.startRect.width + diffX
      if (width < root.minimumWidth) {
        width = root.minimumWidth
        diffX = width - d.startRect.width
      }
      else if (d.maximumWidth > 0 && width > d.maximumWidth) {
        width = d.maximumWidth
        diffX = width - d.startRect.width
      }
      if (root.resizeMode == ResizeHandle.Item && d.hasBorderFlag(ResizeHandle.Border.Left)) target.x = d.startRect.x - diffX
      target.width = width
    }
    if (!d.hasBorderFlag(ResizeHandle.Border.Top) && !d.hasBorderFlag(ResizeHandle.Border.Bottom)) return

    // Resize vertical
    let diffY = d.hasBorderFlag(ResizeHandle.Border.Top) ? d.startMouse.y - pos.y : pos.y - d.startMouse.y
    let height = d.startRect.height + diffY
    if (height < root.minimumHeight) {
      height = root.minimumHeight
      diffY = height - d.startRect.height
    }
    else if (d.maximumHeight > 0 && height > d.maximumHeight) {
      height = d.maximumHeight
      diffY = height - d.startRect.height
    }
    if (root.resizeMode == ResizeHandle.Item && d.hasBorderFlag(ResizeHandle.Border.Top)) target.y = d.startRect.y - diffY
    target.height = height
  }
}
