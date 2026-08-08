import QtQuick
Rectangle {
  required property var theme
  property string title: ""
  property string value: ""
  property string detail: ""
  radius: 16; color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
  border.width: 1; border.color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.72)
  Column { anchors.fill: parent; anchors.margins: 22; spacing: 7
    Text { text: parent.parent.title.toUpperCase(); color: parent.parent.theme.mutedForeground; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.4 }
    Text { text: parent.parent.value; color: parent.parent.theme.foreground; font.pixelSize: 28; font.bold: true; elide: Text.ElideRight; width: parent.width }
    Text { text: parent.parent.detail; color: parent.parent.theme.accent; font.pixelSize: 12; wrapMode: Text.Wrap; width: parent.width }
  }
}
