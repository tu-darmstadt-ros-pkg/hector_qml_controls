pragma Singleton
import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

// Manages the OCS (Operator Control Station) in rviz
// The namespace is derived from the hostname of the machine running the UI
// This allows multiple operators to control robots independently

Object {
    id: root

    readonly property string namespace: HectorRosUtils.sanitizeTopic(Ros2.hostname)
    readonly property string viewControllerNamespace: {
        let topic = rviz.nodeName + "/hector_view_controller";
        return rviz.namespace && rviz.namespace.length > 1 ? rviz.namespace + "/" + topic : topic;
    }
    readonly property string trackedFrame: trackedFrameSubscriber.message && trackedFrameSubscriber.message.frame || ""
    readonly property string viewMode: viewModeSubscriber.message ? (viewModeSubscriber.message.mode == 1 ? "2D" : "3D") : "3D"

    function setActiveRobot(robot) {
        d.setTargetRobotClient.sendRequestAsync({
            robot_namespace: robot.namespace
        }, function (response) {
            if (!response || !response.success)
                Ros2.warn("Gamepad set_target_robot failed: " + (response ? response.message : "no response"));
        });
    }

    function trackFrame(frame) {
        if (!d.trackFrameClient.ready) {
            Ros2.warn("View controller not connected. Topic is: " + root.viewControllerNamespace + "/set_tracked_frame");
            return;
        }
        Ros2.info("Tracking frame: " + frame);
        d.trackFrameClient.sendRequestAsync({
            frame: frame
        }, function (response) {
            if (!response || !!response.message)
                Ros2.warn("Failed to track frame: " + (response ? response.message : "no response"));
        });
    }

    function moveCamera(x, y, frame) {
        if (!d.moveEyeAndFocusClient.ready) {
            Ros2.warn("View controller not connected. Topic is: " + root.viewControllerNamespace + "/move_eye_and_focus");
            return;
        }
        d.moveEyeAndFocusClient.sendRequestAsync({
            header: {
                frame_id: frame || ""
            },
            eye: {
                x: x,
                y: y,
                z: 3
            }
        }, function (result) {
            if (result)
                return;
            Ros2.warn("Failed to move camera! Perhaps you are not using the HectorViewController ViewController.");
        });
    }

    function moveCamera2D(x, y, frame) {
        if (!d.moveEyeClient.ready) {
            Ros2.warn("View controller not connected. Topic is: " + root.viewControllerNamespace + "/move_eye");
            return;
        }
        d.moveEyeClient.sendRequestAsync({
            header: {
                frame_id: frame || ""
            },
            eye: {
                x: x,
                y: y,
                z: 4
            }
        }, function (result) {
            if (result)
                return;
            Ros2.warn("Failed to move camera! Perhaps you are not using the HectorViewController ViewController.");
        });
    }

    function setViewMode(mode) {
        if (!d.setViewModeClient.ready) {
            Ros2.warn("View controller not connected. Topic is: " + root.viewControllerNamespace + "/set_view_mode");
            return;
        }
        d.setViewModeClient.sendRequestAsync({
            mode: {
                mode: mode == "3D" ? 0 : 1
            }
        }, function (response) {
            if (!response || !!response.message)
                Ros2.warn("Failed to set view mode: " + (response ? response.message : "no response"));
        });
    }

    Subscription {
        id: viewModeSubscriber
        topic: root.viewControllerNamespace + "/view_mode"
    }
    Subscription {
        id: trackedFrameSubscriber
        topic: root.viewControllerNamespace + "/tracked_frame"
    }

    QtObject {
        id: d

        property var setTargetRobotClient: Ros2.createServiceClient("/" + root.namespace + "/joy_satellite/set_target_robot", "hector_gamepad_manager_msgs/srv/SetTargetRobot")
        property var moveEyeAndFocusClient: Ros2.createServiceClient(root.viewControllerNamespace + "/move_eye_and_focus", "hector_rviz_plugins_msgs/srv/MoveEyeAndFocus")
        property var moveEyeClient: Ros2.createServiceClient(root.viewControllerNamespace + "/move_eye", "hector_rviz_plugins_msgs/srv/MoveEye")
        property var trackFrameClient: Ros2.createServiceClient(root.viewControllerNamespace + "/set_tracked_frame", "hector_rviz_plugins_msgs/srv/TrackFrame")
        property var setViewModeClient: Ros2.createServiceClient(root.viewControllerNamespace + "/set_view_mode", "hector_rviz_plugins_msgs/srv/SetViewMode")
    }
}
