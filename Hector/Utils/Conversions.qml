pragma Singleton
import QtQuick

NonVisualItem {
  function toBoolean(x) {
    return !!x && (typeof x !== 'string' || x.toLowerCase() != "false")
  }
}
