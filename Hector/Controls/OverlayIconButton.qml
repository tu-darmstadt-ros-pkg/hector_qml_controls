import QtQuick 2.3
import QtQuick.Controls 2.3
import Hector.Icons 1.0
import Hector.Utils 1.0

//! Semi-transparent round button showing a single icon font glyph, meant to be overlaid on views
//! such as camera images.
//! Set text to a HectorIcons glyph and palette.buttonText to change the glyph color.
RoundButton {
  id: control
  implicitWidth: Units.pt(24)
  implicitHeight: implicitWidth
  padding: 0
  hoverEnabled: true
  font.family: HectorIcons.fontFamily
  palette.buttonText: "white"

  contentItem: Text {
    font: control.font
    color: control.palette.buttonText
    text: control.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  background: Rectangle {
    radius: width / 2
    color: "#444444"
    opacity: control.down ? 1 : control.hovered ? 0.8 : 0.6
  }
}
