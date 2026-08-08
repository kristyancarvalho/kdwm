import QtQuick

Canvas {
    id: ring
    property real value: 0
    property color ringColor: "#89b4fa"
    property color trackColor: "#45475a"
    onValueChanged: requestPaint()
    onRingColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var context = getContext("2d")
        var centerX = width / 2, centerY = height / 2, radius = Math.min(width, height) / 2 - 5
        context.clearRect(0, 0, width, height); context.lineWidth = 7; context.lineCap = "round"
        context.beginPath(); context.strokeStyle = trackColor
        context.arc(centerX, centerY, radius, -Math.PI / 2, Math.PI * 1.5); context.stroke()
        context.beginPath(); context.strokeStyle = ringColor
        context.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(100, value) / 100); context.stroke()
    }
}
