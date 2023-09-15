import QtQuick 2.3
import QtQuick.Controls 2.1

Text {
  property Item fillTarget: parent
  property int margins: 6
  x: margins
  y: margins
  width: fillTarget && fillTarget.width ? fillTarget.width - 2 * margins : 0
  height: fillTarget && fillTarget.height ? fillTarget.height - 2 * margins : 0
  fontSizeMode: Text.Fit
  minimumPointSize: 6
  font.pointSize: 100
  horizontalAlignment: Text.AlignHCenter
}