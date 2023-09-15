import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Utils 1.0

DropArea {
  id: root
  property real cellMinimumWidth: 40
  property real cellHeight: -1 // If the cellHeight is set, each item in this grid view is set to the given height
  property real cellAspectRatio: -1 // Can be used to set an aspect ratio (width/height). Lower priority than cellHeight.
  readonly property int cellsPerRow: Math.max(1, Math.floor(width / cellMinimumWidth))
  readonly property real cellWidth: width / cellsPerRow
  property alias model: repeater.model
  property alias delegate: repeater.delegate
  property var previewComponent: Component {
    Rectangle {
      color: "gray"
    }
  }
  signal itemDropped(var drop, int index)
  signal itemMoved(int from, int to)

  function itemAt(index) { return repeater.itemAt(index) }
  function relayout() { d.layout() }

  onCellWidthChanged: d.layout()
  onVisibleChanged: d.layout()

  onEntered: {
    d.showPreview(drag)
    drag.accept()
  }
  onExited: d.hidePreview()
  onPositionChanged: d.updatePreview()
  onDropped: {
    var previousIndex = d.previousIndex
    var visualIndex = d.previewVisualIndex
    var index = 0
    // Translate the visual index into the last possible model index (unless the visual index may be equal to the previous index)
    for (var visualCount = 0; index < repeater.count; ++index) {
      var child = repeater.itemAt(index)
      if (visualCount == visualIndex && index == previousIndex) break
      if (!child || !child.visible || child == d.previewItem) continue
      if (++visualCount > visualIndex) {
        break
      }
    }
    d.hidePreview()
    if (previousIndex !== -1) {
      if (index === -1) {
        d.layout()
        return
      }
      if (previousIndex != index) { 
        itemMoved(previousIndex, index)
      } else {
        drop.accept()
        // Index is the same, a re-layout to move the element back to its place should suffice
      }
    } else {
      itemDropped(drop, index)
    }
    d.layout()
  }

  ScrollView {
    anchors.fill: parent
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    clip: true
    contentWidth: root.width
    contentHeight: gridView.height
    Item {
      id: gridView
      width: parent.width
      implicitHeight: parent.height
      Repeater {
        id: repeater
        onItemAdded: d.layout()
        onItemRemoved: d.layout()
        onModelChanged: d.layout()
      }
    }
  }

  MouseArea {
    id: mouseArea
    hoverEnabled: true
  }

  QtObject {
    id: d
    property var draggedItem: null
    property real draggedItemHeight: 0
    property var previewItem: null
    property int previewVisualIndex: -1
    property int previousIndex: -1
    property var visibleItems: []
    property var rowHeights: []

    function isChild(item) {
      for (var i = 0; i < repeater.count; ++i) {
        if (repeater.itemAt(i) === item) return true
      }
      return false
    }

    function layout() {
      rowHeights.length = 0 // Clear row heights
      visibleItems.length = 0
      var row = 0
      var col = 0
      var cols = root.cellsPerRow
      var rowHeight = 0
      var width = root.cellWidth
      var height = undefined
      if (root.cellHeight > 0) height = root.cellHeight
      else if (root.cellAspectRatio > 0) height = width / root.cellAspectRatio
      var previewItemRow = 0
      var y = 0
      var i = 0
      var count = 0
      for (; count < previewVisualIndex && i < repeater.count; ++i) {
        var child = repeater.itemAt(i)
        if (child == previewItem) continue
        if (!child || !child.visible) continue
        if (child == draggedItem) continue
        ++count
        layoutChild(child, y, col, width, height)
        visibleItems.push(child)
        if (child.height > rowHeight) rowHeight = child.height
        if (++col == cols) {
          ++row
          col = 0
          y += rowHeight
          rowHeights.push(rowHeight)
          rowHeight = 0
        }
      }
      if (previewItem) {
        layoutChild(previewItem, y, col, width, height)
        previewItemRow = row
        if (++col == cols) {
          ++row
          col = 0
          rowHeights.push(rowHeight)
          y += rowHeight
          rowHeight = 0
        }
      }
      for (; i < repeater.count; ++i) {
        var child = repeater.itemAt(i)
        if (!child || !child.visible) continue
        if (child == draggedItem || child == previewItem) continue
        layoutChild(child, y, col, width, height)
        visibleItems.push(child)
        if (child.height > rowHeight) rowHeight = child.height
        if (++col == cols) {
          ++row
          col = 0
          y += rowHeight
          rowHeights.push(rowHeight)
          rowHeight = 0
        }
      }
      if (previewItem) {
        if (height && height !== 0) previewItem.height = height
        else if (previewItemRow < rowHeights.length) previewItem.height = rowHeights[previewItemRow]
        else if (rowHeights.length > 0) previewItem.height = rowHeights[rowHeights.length - 1]
        else previewItem.height = draggedItemHeight
        
        if (previewItem.height > rowHeight) rowHeight = previewItemRow.height
      }
      if (rowHeight) rowHeights.push(rowHeight)
      gridView.height = y + rowHeight
    }

    function layoutChild(child, y, col, width, height) {
        child.y = y
        child.x = col * width
        child.width = width
        if (height && height > 0) child.height = height
    }

    function showPreview(drag) {
      draggedItem = null
      if (d.isChild(drag.source)) {
        var index = -1
        var i = -1
        while (repeater.itemAt(++i)) {
          if (!ObjectUtils.isAncestor(repeater.itemAt(i), drag.source)) continue
          index = i
          break
        }
        if (index !== -1) {
          draggedItem = repeater.itemAt(index)
          // We want to keep the preview element visible for children even if they leave, so we hide it on drop
          drag.source.Drag.activeChanged.connect(function() {
            d.hidePreview(true)
            d.layout()
          })
          previousIndex = index
          previewVisualIndex = index
        }
      }
      if (previewItem) previewItem.destroy()
      previewItem = root.previewComponent.createObject(gridView, { width: root.cellWidth, height: root.cellHeight })
      draggedItemHeight = drag.source.height
      updatePreview(true)
    }

    function updatePreview(forceLayout) {
      var pos = gridView.mapFromItem(root.parent, root.drag.x, root.drag.y)
      var index = computePreviewIndex(pos.x, pos.y)
      if (index > gridView.children.length - 2) index = gridView.children.length - 2 // Ignore the repeater and itself
      var needsRelayout = !!forceLayout
      if (index !== previewVisualIndex) {
        previewVisualIndex = index
        needsRelayout = true
      }
      if (needsRelayout) layout()
    }

    function hidePreview(force) {
      force = !!force
      if (force || !draggedItem) {
        if (previewItem) previewItem.destroy()
        draggedItem = null
        previewItem = null
        previousIndex = -1
        previewVisualIndex = -1
      } else {
        previewVisualIndex = previousIndex
      }
      layout()
    }

    function computePreviewIndex(x, y) {
      //if (root.drag.source != null && root.drag.source.Drag.target != root) return previewVisualIndex
      var row = 0
      for (; row < rowHeights.length; ++row) {
        if (y < rowHeights[row]) break
        y -= rowHeights[row]
      }
      var col = Math.max(0, x / root.cellWidth)
      var withinCol = col - Math.floor(col)
      if (withinCol > 0.33 && withinCol < 0.66) {
        return previewVisualIndex
      }
      col = Math.floor(col)
      var index = row * root.cellsPerRow + col
      if ((index === previewVisualIndex - 1 && withinCol >= 0.66) || (previewVisualIndex !== -1 && index === previewVisualIndex + 1 && withinCol <= 0.33)) {
        return previewVisualIndex
      }
      return index
    }
  }
}