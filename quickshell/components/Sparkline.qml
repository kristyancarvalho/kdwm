import QtQuick

Canvas {
    id: chart
    property var values: []
    property var secondaryValues: []
    property color lineColor: "#89b4fa"
    property color secondaryColor: "#94e2d5"
    property real maximum: 100
    property bool fillArea: true

    onValuesChanged: requestPaint()
    onSecondaryValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function drawSeries(context, samples, color, fill) {
        if (!samples || samples.length < 2) return
        var maxValue = maximum > 0 ? maximum : Math.max.apply(null, samples.concat(1))
        var step = width / Math.max(1, samples.length - 1)
        context.beginPath()
        for (var index = 0; index < samples.length; index++) {
            var x = index * step
            var y = height - 2 - Math.min(1, samples[index] / maxValue) * (height - 6)
            if (index === 0) context.moveTo(x, y); else context.lineTo(x, y)
        }
        context.strokeStyle = color; context.lineWidth = 2; context.stroke()
        if (fill) {
            context.lineTo(width, height); context.lineTo(0, height); context.closePath()
            context.globalAlpha = 0.12; context.fillStyle = color; context.fill(); context.globalAlpha = 1
        }
    }

    onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)
        context.globalAlpha = 0.16; context.strokeStyle = lineColor; context.lineWidth = 1
        for (var row = 1; row < 4; row++) {
            context.beginPath(); context.moveTo(0, row * height / 4); context.lineTo(width, row * height / 4); context.stroke()
        }
        context.globalAlpha = 1
        drawSeries(context, values, lineColor, fillArea)
        drawSeries(context, secondaryValues, secondaryColor, false)
    }
}
