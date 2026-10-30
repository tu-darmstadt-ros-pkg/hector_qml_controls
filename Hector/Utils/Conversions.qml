pragma Singleton
import QtQuick 2.5

NonVisualItem {
  function toBoolean(x) {
    return !!x && (typeof x !== 'string' || x.toLowerCase() != "false")
  }
}
