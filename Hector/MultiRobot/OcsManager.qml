pragma Singleton
import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

// Manages the OCS (Operator Control Station) namespace
// The namespace is derived from the hostname of the machine running the UI
// This allows multiple operators to control robots independently

Object {
    id: root

    readonly property string namespace: HectorRosUtils.sanitizeTopic(Ros2.hostname)
}
