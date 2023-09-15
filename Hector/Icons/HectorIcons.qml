pragma Singleton
import QtQuick 2.3
import Hector.Utils 1.0

Object {
  FontLoader {
    id: fontLoader
    source: "./materialdesignicons-webfont_v6.1.95.ttf"
  }

  readonly property string fontFamily: fontLoader.name

  function iconFromCharCode (codePt) {
    if (codePt > 0xFFFF) {
      codePt -= 0x10000;
      return String.fromCharCode(0xD800 + (codePt >> 10), 0xDC00 + (codePt & 0x3FF));
    }
    return String.fromCharCode(codePt);
  }

  function iconToCharCode (icon) {
    if (!icon || !icon.length || icon.length === 0) return 0
    if (icon.length === 1) {
      return icon.charCodeAt(0)
    }
    var a = icon.charCodeAt(0)
    var b = icon.charCodeAt(1)
    return 0x10000 + ((a - 0xD800) << 10) + b - 0xDC00
  }

  // For codes check: https://pictogrammers.github.io/@mdi/font/6.1.95/
  // Or use this to browse the font: http://mathew-kurian.github.io/CharacterMap/
  readonly property string exitFullscreen: iconFromCharCode(0xF0294)
  readonly property string fullscreen: iconFromCharCode(0xF0293)
  readonly property string pause: iconFromCharCode(0xF03E4)
  readonly property string play: iconFromCharCode(0xF040A)
  readonly property string popout: iconFromCharCode(0xF10AC)
  readonly property string refresh: iconFromCharCode(0xF0450)
}
