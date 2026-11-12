import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// System stats: CPU / memory (and optionally temperature) in the bar, with a
// detail panel on click. Right-click opens btop.
//
// Settings (inline on the shell.json layout entry):
//   interval    seconds between samples, 1..60 (default 2)
//   showMemory  show memory % in the bar (default true)
//   showTemp    show CPU temperature in the bar (default false)
Panel {
  id: root
  moduleName: "gr8monk3ys.sysstats"
  ipcTarget: "gr8monk3ys.sysstats"

  readonly property int intervalSeconds: Model.clampInterval(setting("interval", 2))
  readonly property bool showMemory: setting("showMemory", true) === true
  readonly property bool showTemp: setting("showTemp", false) === true

  property var prevCpu: null
  property real cpu: -1
  property var mem: null
  property var load: null
  property real uptime: -1
  property real temp: -1
  property int cores: 0
  property var processes: []

  readonly property real memPercent: mem ? Model.percentOf(mem.used, mem.total) : -1
  readonly property real swapPercent: mem ? Model.percentOf(mem.swapUsed, mem.swapTotal) : -1
  readonly property bool hot: cpu >= 90 || memPercent >= 90 || temp >= 90

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  function pct(value) {
    return value < 0 ? strings.t("unavailable") : Commons.I18n.formatNumber(Math.round(value)) + "%"
  }

  function degrees(value) {
    return value < 0 ? strings.t("unavailable") : Commons.I18n.formatNumber(Math.round(value)) + "°C"
  }

  function bytes(value) {
    var p = Model.bytesParts(value)
    return Commons.I18n.formatNumber(p.value, p.decimals) + " " + p.unit
  }

  function levelColor(percent, warnAt, criticalAt) {
    var l = Model.level(percent, warnAt, criticalAt)
    if (l === "critical") return Commons.Color.urgent
    if (l === "warn") return Commons.Color.accent
    return root.bar ? root.bar.foreground : Commons.Color.foreground
  }

  readonly property string barText: {
    if (button.vertical) return cpu < 0 ? "…" : Commons.I18n.formatNumber(Math.round(cpu))
    var parts = ["\u{f0ee0} " + pct(cpu)]
    if (showMemory) parts.push("\u{f035b} " + pct(memPercent))
    if (showTemp && temp >= 0) parts.push("\u{f050f} " + degrees(temp))
    return parts.join("  ")
  }

  readonly property string uptimeText: {
    if (uptime < 0) return ""
    var u = Model.uptimeParts(uptime)
    if (u.days > 0)
      return strings.tn("uptime.days", u.days)
        .arg(Commons.I18n.formatNumber(u.days)).arg(Commons.I18n.formatNumber(u.hours))
    return strings.t("uptime.hours")
      .arg(Commons.I18n.formatNumber(u.hours)).arg(Commons.I18n.formatNumber(u.minutes))
  }

  readonly property string loadText: load
    ? strings.t("load").arg(Commons.I18n.formatNumber(load[0], 2))
        .arg(Commons.I18n.formatNumber(load[1], 2)).arg(Commons.I18n.formatNumber(load[2], 2))
    : ""

  // ---- Sampling --------------------------------------------------------
  // A fixed script with no interpolated values: it only reads /proc and
  // /sys. Prefers a CPU package sensor, falling back to ACPI thermal zone.
  Process {
    id: sampler
    command: ["sh", "-c",
      "printf '@stat\\n'; head -n1 /proc/stat; " +
      "printf '@mem\\n'; cat /proc/meminfo; " +
      "printf '@load\\n'; cat /proc/loadavg; " +
      "printf '@uptime\\n'; cat /proc/uptime; " +
      "printf '@cores\\n'; nproc 2>/dev/null; " +
      "printf '@temp\\n'; t=''; " +
      "for h in /sys/class/hwmon/hwmon*; do case \"$(cat \"$h/name\" 2>/dev/null)\" in " +
      "coretemp|k10temp|zenpower|cpu_thermal) t=\"$h/temp1_input\"; break;; esac; done; " +
      "if [ -z \"$t\" ]; then for h in /sys/class/hwmon/hwmon*; do " +
      "[ \"$(cat \"$h/name\" 2>/dev/null)\" = acpitz ] && t=\"$h/temp1_input\" && break; done; fi; " +
      "[ -n \"$t\" ] && cat \"$t\" 2>/dev/null; true"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.ingest(text)
    }
  }

  // Only runs while the panel is open.
  Process {
    id: topProc
    command: ["ps", "-eo", "pid=,pcpu=,pmem=,comm=", "--sort=-pcpu"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processes = Model.parseProcesses(text)
    }
  }

  function ingest(raw) {
    var s = Model.splitSections(raw)
    var next = Model.parseCpuLine(s.stat)
    if (next) {
      var p = Model.cpuPercent(root.prevCpu, next)
      if (p >= 0) root.cpu = p
      root.prevCpu = next
    }
    var m = Model.parseMeminfo(s.mem)
    if (m) root.mem = m
    root.load = Model.parseLoadavg(s.load)
    root.uptime = Model.parseUptime(s.uptime)
    root.temp = Model.parseTemp(s.temp)
    var c = parseInt(String(s.cores || ""), 10)
    root.cores = isFinite(c) && c > 0 && c < 4096 ? c : 0
  }

  function sample() {
    if (!sampler.running) sampler.running = true
    if (root.opened && !topProc.running) topProc.running = true
  }

  Timer {
    interval: root.intervalSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.sample()
  }

  onOpenedChanged: if (opened) sample()

  // ---- Bar button ------------------------------------------------------
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    active: root.hot
    tooltipText: ""
    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) root.bar.run("omarchy-launch-or-focus-tui btop")
      else root.toggle()
    }
  }

  // ---- Panel -----------------------------------------------------------
  component Meter: Column {
    id: meter
    property string label: ""
    property string value: ""
    property real percent: 0
    property color fill: root.bar ? root.bar.foreground : Commons.Color.foreground
    width: parent ? parent.width : 0
    spacing: Style.space(5)

    Item {
      width: parent.width
      height: Math.max(meterLabel.implicitHeight, meterValue.implicitHeight)
      Text {
        id: meterLabel
        textFormat: Text.PlainText
        anchors.left: parent.left
        text: meter.label
        color: root.bar ? root.bar.foreground : Commons.Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
      }
      Text {
        id: meterValue
        textFormat: Text.PlainText
        anchors.right: parent.right
        text: meter.value
        color: Qt.darker(root.bar ? root.bar.foreground : Commons.Color.foreground, 1.3)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
    }

    Rectangle {
      id: track
      width: parent.width
      height: Style.space(6)
      radius: height / 2
      color: Qt.rgba(meter.fill.r, meter.fill.g, meter.fill.b, 0.12)
      Rectangle {
        // Fill grows from the reading side in RTL too.
        x: LayoutMirroring.enabled ? track.width - width : 0
        height: parent.height
        radius: parent.radius
        width: track.width * Model.clampPercent(meter.percent) / 100
        color: meter.fill
        Behavior on width {
          NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
        }
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // Hero: CPU % big, load + uptime beside it.
        Item {
          width: parent.width
          implicitHeight: Math.max(heroValue.implicitHeight, heroMeta.implicitHeight)

          Text {
            id: heroValue
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.pct(root.cpu)
            color: root.levelColor(root.cpu, 70, 90)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.displayLarge
            font.bold: true
          }

          Column {
            id: heroMeta
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)
            Text {
              textFormat: Text.PlainText
              anchors.right: parent.right
              text: root.cores > 0
                ? strings.t("cpu") + " · " + strings.tn("cores", root.cores).arg(Commons.I18n.formatNumber(root.cores))
                : strings.t("cpu")
              color: root.bar ? root.bar.foreground : Commons.Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }
            Text {
              textFormat: Text.PlainText
              anchors.right: parent.right
              visible: text !== ""
              text: root.loadText
              color: Qt.darker(root.bar ? root.bar.foreground : Commons.Color.foreground, 1.3)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              textFormat: Text.PlainText
              anchors.right: parent.right
              visible: text !== ""
              text: root.uptimeText
              color: Qt.darker(root.bar ? root.bar.foreground : Commons.Color.foreground, 1.3)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        Meter {
          label: strings.t("cpu")
          value: root.pct(root.cpu)
          percent: Math.max(0, root.cpu)
          fill: root.levelColor(root.cpu, 70, 90)
        }

        Meter {
          label: strings.t("memory")
          value: root.mem ? strings.t("usedOf").arg(root.bytes(root.mem.used)).arg(root.bytes(root.mem.total)) : strings.t("unavailable")
          percent: Math.max(0, root.memPercent)
          fill: root.levelColor(root.memPercent, 75, 90)
        }

        Meter {
          visible: root.mem !== null && root.mem.swapTotal > 0
          label: strings.t("swap")
          value: root.mem ? strings.t("usedOf").arg(root.bytes(root.mem.swapUsed)).arg(root.bytes(root.mem.swapTotal)) : ""
          percent: Math.max(0, root.swapPercent)
          fill: root.levelColor(root.swapPercent, 50, 80)
        }

        Meter {
          visible: root.temp >= 0
          label: strings.t("temperature")
          value: root.degrees(root.temp)
          // Map 30..100 °C onto the bar.
          percent: (root.temp - 30) / 70 * 100
          fill: root.levelColor(root.temp, 75, 90)
        }

        PanelSeparator { foreground: root.bar ? root.bar.foreground : Commons.Color.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: strings.t("topProcesses")
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Text {
            visible: root.processes.length === 0
            textFormat: Text.PlainText
            text: strings.t("noProcesses")
            color: Qt.darker(root.bar ? root.bar.foreground : Commons.Color.foreground, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.processes.slice(0, 5)
            Item {
              required property var modelData
              width: parent.width
              height: procName.implicitHeight

              Text {
                id: procName
                textFormat: Text.PlainText
                anchors.left: parent.left
                anchors.right: procStats.left
                anchors.rightMargin: Style.space(8)
                elide: Text.ElideRight
                text: modelData.name
                color: root.bar ? root.bar.foreground : Commons.Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
              }
              Text {
                id: procStats
                textFormat: Text.PlainText
                anchors.right: parent.right
                text: Commons.I18n.formatNumber(modelData.cpu, 1) + "%  ·  "
                  + Commons.I18n.formatNumber(modelData.mem, 1) + "%"
                color: Qt.darker(root.bar ? root.bar.foreground : Commons.Color.foreground, 1.3)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
        }

        Button {
          width: parent.width
          iconText: "\u{f0128}"
          text: strings.t("openBtop")
          foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          onClicked: {
            if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
            root.close()
          }
        }
      }
    }
  }
}
