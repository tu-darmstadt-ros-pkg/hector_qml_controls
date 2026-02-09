pragma Singleton
import QtQuick 2.3
import Ros2 1.0
import Hector.Utils 1.0

// Manages the OCS (Operator Control Station) namespace
// The namespace is derived from the hostname of the machine running the UI
// This allows multiple operators to control robots independently

Object {
    id: root

    // The sanitized OCS namespace (hostname with - replaced by _ and ensured to start with a letter)
    // Note: The ocs_namespace must be a valid ros namespace, hence the sanitization
    readonly property string namespace: sanitizeNamespace(Ros2.hostname)

    function sanitizeNamespace(name) {
        let sanitized = name.replace(/-/g, "_")
        if (sanitized.length > 0 && !sanitized[0].match(/[a-zA-Z]/)) {
            sanitized = "ns" + sanitized
        }
        return sanitized
    }
}
