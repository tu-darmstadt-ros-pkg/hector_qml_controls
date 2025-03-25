import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtMultimedia 5.4
import Ros2 1.0
import Hector.Utils 1.0

Item {
  id: root
  property var editable: true
  property bool transitionsEnabled: true
  property real spacing: Units.pt(4)
  property var selectedCamera: null
  signal configurationUpdated
  property var configuration
  onConfigurationChanged: {
    if (!configuration) configuration = {}
    if (!configuration.cameras || !Array.isArray(configuration.cameras)) configuration.cameras = []
    d.updateCameraList()
  }

  clip: true

  function hideCamera() {
    selectedCamera.showNormal()
  }

  function selectCameraByName(id) {
    if (!id) {
      hideCamera()
      return
    }
    for (var i = 0; i < root.configuration.cameras.length; ++i) {
      var camera = d.cameraList.get(i)
      if (camera.id != id) continue
      if (selectedCamera != null) selectedCamera.showNormal()
      grid.positionViewAtIndex(i, GridView.Contain)
      var item = grid.getDelegateInstanceAt(i)
      if (!item) {
        Ros2.error("Could not get camera preview for " + id + "!")
        return
      }
      item.showFull()
      return
    }
    Ros2.error("Could not show camera with id '" + id + "' because it was not found!")
  }

  function _addCamera(config) {
    if (!configuration.cameras) configuration.cameras = []
    var camera = {}
    _cloneCameraProps(camera, config)
    configuration.cameras.push(camera)
    root.configurationUpdated()
    d.updateCameraList()
  }

  function _updateCamera(index, config) {
    if (index < 0 || configuration.cameras.length <= index) {
      Ros2.error("Can not update camera because index " + index + " does not exist!")
      return
    }
    Ros2.warn("Update camera at " + index + ": " + config.id)
    var camera = configuration.cameras[index]
    _cloneCameraProps(camera, config)
    configuration.cameras[index] = camera
    root.configurationUpdated()
    d.updateCameraList()
  }

  function _cloneCameraProps(target, source) {
    target.id = source.id
    target.robot = source.robot
    target.cameraId = source.cameraId
    target.name = source.name
    target.orientation = source.orientation
  }

  function _deleteCamera(index) {
    if (index < 0 || configuration.cameras.length <= index) {
      Ros2.warn("Can not delete camera because index " + index + " does not exist!")
      return
    }
    configuration.cameras.splice(index, 1)
    root.configurationUpdated()
    d.updateCameraList()
  }


  QtObject {
    id: d
    property ListModel cameraList: ListModel {}
    property var editData: null

    function checkForChanges() {
      if (root.configuration.cameras.length != d.cameraList.count) return true
      for (var i = 0; i < root.configuration.cameras.length; ++i) {
        var camera = d.cameraList.get(i)
        var entry = root.configuration.cameras[i]
        if (camera.name != entry.name || camera.id != entry.id || camera.orientation != (parseInt(entry.orientation) || 0)) return true
      }
      return false
    }

    function updateCameraList() {
      if (!checkForChanges()) return // Only update on changes to cameras
      d.cameraList.clear()
      for (var i = 0; i < root.configuration.cameras.length; ++i) {
        var entry = root.configuration.cameras[i]
        let data = {id: entry.id, name: entry.name, configuration: entry, orientation: parseInt(entry.orientation) || 0, source: null}
        d.cameraList.append(data)
      }
      d.cameraList = d.cameraList
    }
  }

  GridView {
    id: grid
    anchors.fill: parent
    cellWidth: width / 2
    cellHeight: (cellWidth - 8) * 9 / 16 + 8
    clip: true
    model: d.cameraList
    function getDelegateInstanceAt(index) {
      for(var i = 0; i < contentItem.children.length; ++i) {
        var item = contentItem.children[i];
        // We have to check for the specific objectName we gave our
        // delegates above, since we also get some items that are not
        // our delegates here.
        if (item.objectName == "cameraPreview" && item.index == index)
          return item;
      }
      return undefined;
    }
    delegate: Component {
      id: cameraPreviewComponent
      CameraView {
        objectName: "cameraPreview"
        id: cameraView
        property int index: model.index
        property var camera: model.configuration && model.configuration.camera
        x: root.spacing / 2; y: root.spacing / 2
        width: grid.cellWidth - root.spacing; height: grid.cellHeight - root.spacing
        configuration: model.configuration
        orientation: model.orientation
        showFramerate: false
        showLatency: false
        canGoBack: false
        showControls: false
        name: model.configuration.name || (camera && camera.name) || "Unknown"
        nameFont.pointSize: 10
        enabled: root.selectedCamera === null || root.selectedCamera === cameraView
        state: "default"

        function showFull() {
          root.selectedCamera = cameraView
          state = "full"
        }

        function showNormal() {
          state = "default"
          root.selectedCamera = null
        }

        onBackRequested: showNormal()
        states: [
          State {
            name: "default"
            PropertyChanges { target: cameraView; nameFont.pointSize: 10 }
          },
          State {
            name: "full"
            ParentChange { target: cameraView; parent: root }
            AnchorChanges { target: cameraView; anchors.left: root.left; anchors.right: root.right; anchors.top: root.top; anchors.bottom: root.bottom }
            PropertyChanges { target: cameraView; nameFont.pointSize: 16; canGoBack: true; showControls: true; configuration: model.configuration }
          }
        ]

        transitions: [
          Transition {
            from: "default"
            to: "full"
            reversible: true
            enabled: root.transitionsEnabled
            ParallelAnimation {
              AnchorAnimation { easing.type: Easing.InOutQuad }
              PropertyAnimation { target: cameraView; properties: "nameFont.pointSize"; easing.type: Easing.InOutQuad }
            }
          }
        ]

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          enabled: root.selectedCamera === null
          onClicked: {
            if (mouse.button === Qt.RightButton) {
              // Qt 5.10 introduces a method popup that handles this in one call
              contextMenu.x = mouse.x; contextMenu.y = mouse.y;
              contextMenu.open()
            } else
              parent.showFull()
          }
        }
        Menu {
          id: contextMenu
          closePolicy: Popup.CloseOnPressOutside
          MenuItem {
            text: "Edit"
            onClicked: {
              d.editData = {index: model.index}
              addCameraDialog.load(model.configuration)
              addCameraDialog.open()
            }
          }
          MenuItem {
            text: "Delete"
            onClicked: {
              root._deleteCamera(model.index)
            }
          }
        }
      }
    }

    footer: Component {
      id: addCameraButtonComponent

      Item {
        anchors.left: parent.left
        anchors.right: parent.right
        height: Units.pt(24)
        Button {
          anchors.fill: parent
          AutoSizeText {
            text: "Add"
          }

          onClicked: function () {
            d.editData = null
            addCameraDialog.reset()
            addCameraDialog.open()
          }
        }
      }
    }
  }

  EditCameraDialog {
    id: addCameraDialog
    onSave: function (configuration) {
      if (!d.editData) root._addCamera(configuration)
      else root._updateCamera(d.editData.index, configuration)
    }
  }
}