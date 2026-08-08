import QtQuick
import Quickshell
import Quickshell.X11
import Quickshell.Io

ShellRoot {
  id: root
  property var fallback: ({background:"#1e1e2e",surface:"#313244",surfaceVariant:"#45475a",foreground:"#cdd6f4",mutedForeground:"#a6adc8",accent:"#89b4fa",accentSecondary:"#94e2d5",border:"#585b70",critical:"#f38ba8",warning:"#f9e2af",success:"#a6e3a1"})
  property var palette: fallback
  property var stats: ({cpu:0,memory:0,model:"Loading metrics",load:"",root:"",home:"",interface:"",download:0,upload:0,uptime:"",hostname:""})
  FileView { id: themeFile; path: "/home/kristyan/.cache/dwm-rice/theme.json"; blockLoading: true; printErrors: false }
  FileView { id: statsFile; path: "/home/kristyan/.cache/dwm-rice/stats.json"; blockLoading: true; printErrors: false }
  Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { try { root.palette = JSON.parse(themeFile.text()) } catch(e) {} try { root.stats = JSON.parse(statsFile.text()) } catch(e) {} } }
  XPanelWindow {
    anchors { left: true; right: true; top: true; bottom: true }
    margins { top: 38; left: 0; right: 0; bottom: 0 }
    exclusiveZone: 0; exclusionMode: ExclusionMode.Ignore; aboveWindows: false; focusable: false
    color: "transparent"
    Item { anchors.fill: parent; anchors.margins: 46
      Grid { anchors.centerIn: parent; width: Math.min(parent.width * 0.82, 1320); height: Math.min(parent.height * 0.72, 720); columns: width > 900 ? 3 : 2; spacing: 16
        Repeater { model: [
          ["CPU", root.stats.cpu + "%", root.stats.model + "\nload " + root.stats.load + (root.stats.temp ? " · " + root.stats.temp + "°C" : "")],
          ["Memory", root.stats.memory + "%", root.stats.memoryUsed + " / " + root.stats.memoryTotal + " MB"],
          ["Storage", root.stats.root, root.stats.home],
          ["Network", root.stats.interface, "↓ " + root.stats.download + " B/s   ↑ " + root.stats.upload + " B/s"],
          ["System", root.stats.hostname, root.stats.uptime + " · " + Qt.formatDateTime(new Date(), "ddd, dd MMM · hh:mm")],
          ["GPU", "Adaptive", "NVIDIA/other GPU metrics appear when a provider is available"]
        ]; delegate: Card { theme: root.palette; title: modelData[0]; value: modelData[1]; detail: modelData[2]; width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns; height: (parent.height - parent.spacing) / 2 }
        }
      }
    }
  }
}
