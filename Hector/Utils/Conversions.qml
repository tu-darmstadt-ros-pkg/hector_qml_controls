pragma Singleton
import QtQuick 2.5

Object {
  function toBoolean(x) {
    return !!x && (typeof x !== 'string' || x.toLowerCase() != "false")
  }
}
