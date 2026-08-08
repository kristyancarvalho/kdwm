import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.X11
import Quickshell.Io
import "components"

ShellRoot {
    id: root
    property var fallback: ({background:"#050807",surface:"#111816",surfaceElevated:"#1b2521",foreground:"#d7e5df",mutedForeground:"#77817d",accent:"#6da88e",accentDim:"#315447",border:"#294238",critical:"#ad5860",warning:"#9d875d",success:"#6da88e"})
    property var palette: fallback
    property var stats: ({cpu:{usage:0,cores:[],frequency:0,load:[0,0,0]},memory:{percent:0,used:0,total:0,cached:0},network:{interface:"",ip:"",download:0,upload:0},storage:[],temperatures:[],processes:[],gpu:{available:false},battery:{available:false},audio:{available:false},bluetooth:{available:false},hostname:"Carregando",kernel:"",os:"Arch Linux",wm:"DWM",packages:0,uptime:0})
    property var cpuHistory: []
    property var memoryHistory: []
    property var downloadHistory: []
    property var uploadHistory: []
    property var gpuHistory: []
    property date now: new Date()
    property var ptBr: Qt.locale("pt_BR")
    property int historyLimit: 60

    function append(history, value) {
        var next = history.slice(Math.max(0, history.length - historyLimit + 1))
        next.push(Number(value) || 0)
        return next
    }
    function bytes(value) {
        var units = ["B", "KiB", "MiB", "GiB", "TiB"], amount = Number(value) || 0, index = 0
        while (amount >= 1024 && index < units.length - 1) { amount /= 1024; index++ }
        return (index === 0 ? amount.toFixed(0) : amount.toFixed(amount >= 10 ? 1 : 2)) + " " + units[index]
    }
    function duration(seconds) {
        var days = Math.floor(seconds / 86400), hours = Math.floor(seconds % 86400 / 3600), minutes = Math.floor(seconds % 3600 / 60)
        return (days ? days + "d " : "") + hours + "h " + minutes + "min"
    }
    function batteryStatus(status) {
        var labels = {"Charging":"Carregando","Discharging":"Em uso","Full":"Completa","Not charging":"Sem carregar","Unknown":"Indisponível"}
        return labels[status] || status
    }
    function ingest(data) {
        stats = data
        cpuHistory = append(cpuHistory, data.cpu.usage)
        memoryHistory = append(memoryHistory, data.memory.percent)
        downloadHistory = append(downloadHistory, data.network.download)
        uploadHistory = append(uploadHistory, data.network.upload)
        if (data.gpu.available) gpuHistory = append(gpuHistory, data.gpu.usage)
    }

    FileView {
        id: themeFile
        path: "/home/kristyan/.cache/kdwm/theme/theme.json"
        blockLoading: true; preload: true; watchChanges: true; printErrors: false
        onLoaded: { try { root.palette = JSON.parse(text()) } catch(error) {} }
        onFileChanged: reload()
        onTextChanged: { try { root.palette = JSON.parse(text()) } catch(error) {} }
    }
    Process {
        id: metrics
        command: ["/home/kristyan/src/dwm/scripts/system-stats-daemon"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => { try { root.ingest(JSON.parse(data)) } catch(error) { console.warn("metrics parse:", error) } }
        }
        onExited: restartTimer.start()
    }
    Timer { id: restartTimer; interval: 2000; onTriggered: metrics.running = true }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    XPanelWindow {
        anchors { left: true; right: true; top: true; bottom: true }
        margins { top: 38; left: 0; right: 0; bottom: 0 }
        exclusiveZone: 0; exclusionMode: ExclusionMode.Ignore
        aboveWindows: false; focusable: false; color: "transparent"

        GridLayout {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
            width: Math.min(parent.width - 48, 1220)
            height: Math.min(parent.height - 16, 730)
            columns: 3; rows: 3; columnSpacing: 8; rowSpacing: 8
            property real unitWidth: (width - columnSpacing * 2) / 3
            property real unitHeight: (height - rowSpacing * 2) / 3

            Card {
                theme: root.palette; title: "Uso da CPU // tempo real"; accentColor: root.palette.accent
                Layout.columnSpan: 2; Layout.fillWidth: true; Layout.fillHeight: true
                Layout.preferredWidth: parent.unitWidth * 2 + parent.columnSpacing; Layout.preferredHeight: parent.unitHeight
                RowLayout { anchors.fill: parent; spacing: 18
                    ColumnLayout { Layout.preferredWidth: 130; Layout.fillHeight: true; spacing: 2
                        Text { text: Math.round(root.stats.cpu.usage) + "%"; color: root.palette.foreground; font { pixelSize: 41; bold: true } }
                        Text { text: (root.stats.cpu.frequency / 1000).toFixed(2) + " GHz"; color: root.palette.accent; font.pixelSize: 13 }
                        Text { text: "carga  " + root.stats.cpu.load.join("  "); color: root.palette.mutedForeground; font.pixelSize: 10 }
                        Item { Layout.fillHeight: true }
                        Grid { columns: 4; spacing: 3
                            Repeater { model: root.stats.cpu.cores
                                Rectangle { required property real modelData; width: 27; height: 4; radius: 2
                                    color: Qt.rgba(1,1,1,0.08)
                                    Rectangle { width: parent.width * modelData / 100; height: parent.height; radius: 1; color: root.palette.accent }
                                }
                            }
                        }
                        Text { text: root.stats.cpu.cores.length + " núcleos lógicos"; color: root.palette.mutedForeground; font.pixelSize: 9 }
                    }
                    Sparkline { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 120
                        values: root.cpuHistory; lineColor: root.palette.accent; maximum: 100
                    }
                }
            }

            Card {
                theme: root.palette; title: "Hora local"; accentColor: root.palette.accent
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: parent.unitWidth; Layout.preferredHeight: parent.unitHeight
                Column { anchors.centerIn: parent; width: parent.width; spacing: 3
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(root.now, "HH:mm"); color: root.palette.foreground; font { pixelSize: 52; bold: true; letterSpacing: -2 } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.ptBr.toString(root.now, "dddd"); color: root.palette.accent; font { pixelSize: 14; capitalization: Font.AllUppercase; letterSpacing: 2 } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.ptBr.toString(root.now, "d 'de' MMMM 'de' yyyy"); color: root.palette.mutedForeground; font.pixelSize: 12 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.stats.hostname.toUpperCase() + "  //  " + root.duration(root.stats.uptime); color: root.palette.accentDim; font { pixelSize: 9; letterSpacing: 1 } }
                }
            }

            Card {
                theme: root.palette; title: "Memória"; accentColor: root.palette.accent
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: parent.unitWidth; Layout.preferredHeight: parent.unitHeight
                RowLayout { anchors.fill: parent; spacing: 10
                    Item { Layout.preferredWidth: 88; Layout.preferredHeight: 88
                        UsageRing { anchors.fill: parent; value: root.stats.memory.percent; ringColor: root.palette.accent; trackColor: root.palette.surfaceElevated }
                        Text { anchors.centerIn: parent; text: Math.round(root.stats.memory.percent) + "%"; color: root.palette.foreground; font { pixelSize: 20; bold: true } }
                    }
                    ColumnLayout { Layout.fillWidth: true; Layout.fillHeight: true
                        Text { text: root.bytes(root.stats.memory.used) + " / " + root.bytes(root.stats.memory.total); color: root.palette.foreground; font { pixelSize: 13; bold: true } }
                        Text { text: "cache  " + root.bytes(root.stats.memory.cached); color: root.palette.mutedForeground; font.pixelSize: 10 }
                        Sparkline { Layout.fillWidth: true; Layout.fillHeight: true; values: root.memoryHistory; lineColor: root.palette.accent; maximum: 100 }
                    }
                }
            }

            Card {
                theme: root.palette; title: "Rede // " + (root.stats.network.interface || "desconectada"); accentColor: root.palette.accent
                Layout.columnSpan: 2; Layout.fillWidth: true; Layout.fillHeight: true
                Layout.preferredWidth: parent.unitWidth * 2 + parent.columnSpacing; Layout.preferredHeight: parent.unitHeight
                RowLayout { anchors.fill: parent; spacing: 16
                    Column { Layout.preferredWidth: 155; spacing: 7
                        Text { text: "↓  " + root.bytes(root.stats.network.download) + "/s"; color: root.palette.accent; font { pixelSize: 17; bold: true } }
                        Text { text: "↑  " + root.bytes(root.stats.network.upload) + "/s"; color: root.palette.accentDim; font { pixelSize: 17; bold: true } }
                        Text { text: root.stats.network.ip || "desconectado"; color: root.palette.mutedForeground; font.pixelSize: 10 }
                    }
                    Sparkline { Layout.fillWidth: true; Layout.fillHeight: true; values: root.downloadHistory; secondaryValues: root.uploadHistory
                        lineColor: root.palette.accent; secondaryColor: root.palette.accentDim; maximum: 0; fillArea: true
                    }
                }
            }

            Card {
                theme: root.palette; title: "Processos // CPU"; accentColor: root.palette.accentDim
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: parent.unitWidth; Layout.preferredHeight: parent.unitHeight
                Column { anchors.fill: parent; spacing: 6
                    Repeater { model: root.stats.processes
                        Row { required property var modelData; width: parent.width; height: 24
                            Text { width: parent.width - 105; text: modelData.name; elide: Text.ElideRight; color: root.palette.foreground; font.pixelSize: 11 }
                            Text { width: 52; horizontalAlignment: Text.AlignRight; text: modelData.cpu.toFixed(1) + "%"; color: root.palette.accent; font.pixelSize: 10 }
                            Text { width: 53; horizontalAlignment: Text.AlignRight; text: root.bytes(modelData.memory); color: root.palette.mutedForeground; font.pixelSize: 9 }
                        }
                    }
                }
            }

            Card {
                theme: root.palette; title: "Armazenamento"; accentColor: root.palette.accentDim
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: parent.unitWidth; Layout.preferredHeight: parent.unitHeight
                Row { anchors.centerIn: parent; spacing: 22
                    Repeater { model: root.stats.storage
                        Column { required property var modelData; width: 125; spacing: 6
                            Item { width: 82; height: 82; anchors.horizontalCenter: parent.horizontalCenter
                                UsageRing { anchors.fill: parent; value: modelData.percent; ringColor: root.palette.accentDim; trackColor: root.palette.surfaceElevated }
                                Text { anchors.centerIn: parent; text: Math.round(modelData.percent) + "%"; color: root.palette.foreground; font { pixelSize: 17; bold: true } }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.mount; color: root.palette.foreground; font { pixelSize: 13; bold: true } }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.bytes(modelData.free) + " livres"; color: root.palette.mutedForeground; font.pixelSize: 9 }
                        }
                    }
                }
            }

            Card {
                theme: root.palette; title: root.stats.gpu.available ? "GPU // tempo real" : "Sistema"; accentColor: root.palette.accent
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: parent.unitWidth; Layout.preferredHeight: parent.unitHeight
                Column { anchors.fill: parent; spacing: 5
                    Text { text: root.stats.hostname; color: root.palette.foreground; font { pixelSize: 20; bold: true } }
                    Text { text: root.stats.os + "  ·  " + root.stats.wm; color: root.palette.accent; font.pixelSize: 11 }
                    Text { text: root.stats.kernel; color: root.palette.mutedForeground; font.pixelSize: 9; elide: Text.ElideRight; width: parent.width }
                    Text { text: root.duration(root.stats.uptime) + " ligado  ·  " + root.stats.packages + " pacotes"; color: root.palette.mutedForeground; font.pixelSize: 10 }
                    Rectangle { width: parent.width; height: 1; color: root.palette.border }
                    Row { spacing: 14
                        Text { visible: root.stats.battery.available; text: "BATERIA " + root.stats.battery.percent + "% " + root.batteryStatus(root.stats.battery.status); color: root.stats.battery.status === "Discharging" ? root.palette.warning : root.palette.success; font.pixelSize: 10 }
                        Text { visible: root.stats.audio.available; text: (root.stats.audio.muted ? "MUDO" : "VOLUME " + root.stats.audio.percent + "%"); color: root.stats.audio.muted ? root.palette.critical : root.palette.accent; font.pixelSize: 10 }
                        Text { visible: root.stats.bluetooth.available; text: root.stats.bluetooth.connected ? "BT CONECTADO" : (root.stats.bluetooth.powered ? "BT LIGADO" : "BT DESLIGADO"); color: root.stats.bluetooth.connected ? root.palette.accent : root.palette.mutedForeground; font.pixelSize: 10 }
                    }
                    Row { visible: root.stats.temperatures.length > 0; spacing: 12
                        Repeater { model: root.stats.temperatures
                            Text { required property var modelData; text: modelData.label + " " + modelData.value.toFixed(0) + "°"; color: root.palette.warning; font.pixelSize: 10 }
                        }
                    }
                    Column { visible: root.stats.gpu.available; width: parent.width; spacing: 2
                        Text { text: (root.stats.gpu.name || "GPU") + "  " + Number(root.stats.gpu.usage || 0).toFixed(0) + "%  ·  " + Number(root.stats.gpu.temperature || 0).toFixed(0) + "°C"; color: root.palette.accent; font.pixelSize: 10 }
                        Sparkline { width: parent.width; height: 35; values: root.gpuHistory; lineColor: root.palette.accent; maximum: 100 }
                    }
                }
            }
        }
    }
}
