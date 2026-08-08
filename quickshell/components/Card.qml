import QtQuick

Rectangle {
    id: card
    required property var theme
    property string title: ""
    property color accentColor: theme.accent
    default property alias contents: content.data
    property color surfaceColor: theme.surface
    property color borderColor: theme.border

    radius: 3
    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.74)
    border.width: 1
    border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.46)

    Rectangle {
        width: 2; height: 18; radius: 0
        color: card.accentColor
        anchors { left: parent.left; top: parent.top; leftMargin: 16; topMargin: 15 }
    }
    Text {
        text: card.title.toUpperCase(); color: card.theme.mutedForeground
        font { pixelSize: 10; bold: true; letterSpacing: 1.6 }
        anchors { left: parent.left; top: parent.top; leftMargin: 27; topMargin: 16 }
    }
    Item {
        id: content
        anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 39; bottomMargin: 14 }
    }
}
