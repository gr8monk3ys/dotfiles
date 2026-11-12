// Pure helpers for the system stats widget. No QML imports, so the tests in
// tests/model.test.mjs can load this file directly under node.

// Upper bounds on what we accept from the sampler, so a malformed read can
// never push an absurd value or a huge string into the UI.
var MAX_SECTION_CHARS = 16384
var MAX_PROCESSES = 8
var MAX_PROCESS_NAME = 32

// Split the sampler output ("@stat\n...\n@mem\n...") into named sections.
function splitSections(raw) {
  var out = {}
  var text = String(raw || "")
  var parts = text.split(/^@([a-z]+)\s*$/m)
  // parts = [preamble, name1, body1, name2, body2, ...]
  for (var i = 1; i + 1 < parts.length; i += 2) {
    var name = parts[i]
    var body = parts[i + 1]
    if (body.length > MAX_SECTION_CHARS) body = body.slice(0, MAX_SECTION_CHARS)
    out[name] = body.replace(/^\n/, "").replace(/\s+$/, "")
  }
  return out
}

// "cpu  user nice system idle iowait irq softirq steal ..." -> {total, idle}
function parseCpuLine(line) {
  var fields = String(line || "").trim().split(/\s+/)
  if (fields.length < 5 || fields[0] !== "cpu") return null
  var total = 0
  var idle = 0
  // Guest columns (9, 10) are already folded into user/nice; skip them.
  var count = Math.min(fields.length, 9)
  for (var i = 1; i < count; i++) {
    var n = Number(fields[i])
    if (!isFinite(n) || n < 0) return null
    total += n
    if (i === 4 || i === 5) idle += n // idle + iowait
  }
  return { total: total, idle: idle }
}

// Busy percentage between two samples, 0..100, or -1 when unknown.
function cpuPercent(prev, next) {
  if (!prev || !next) return -1
  var dt = next.total - prev.total
  var di = next.idle - prev.idle
  if (!(dt > 0) || di < 0) return -1
  return clampPercent(100 * (dt - di) / dt)
}

// /proc/meminfo -> {total, used, available, swapTotal, swapUsed} in bytes.
function parseMeminfo(text) {
  var kb = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length && i < 128; i++) {
    var m = /^([A-Za-z_()0-9]+):\s+(\d+)/.exec(lines[i])
    if (m) kb[m[1]] = Number(m[2])
  }
  if (!(kb.MemTotal > 0)) return null
  var available = kb.MemAvailable !== undefined ? kb.MemAvailable
    : (kb.MemFree || 0) + (kb.Buffers || 0) + (kb.Cached || 0)
  var swapTotal = kb.SwapTotal || 0
  var swapFree = kb.SwapFree || 0
  return {
    total: kb.MemTotal * 1024,
    available: available * 1024,
    used: Math.max(0, kb.MemTotal - available) * 1024,
    swapTotal: swapTotal * 1024,
    swapUsed: Math.max(0, swapTotal - swapFree) * 1024
  }
}

// /proc/loadavg -> [1m, 5m, 15m] or null.
function parseLoadavg(text) {
  var f = String(text || "").trim().split(/\s+/)
  if (f.length < 3) return null
  var out = []
  for (var i = 0; i < 3; i++) {
    var n = Number(f[i])
    if (!isFinite(n) || n < 0) return null
    out.push(n)
  }
  return out
}

// /proc/uptime -> seconds or -1.
function parseUptime(text) {
  var n = Number(String(text || "").trim().split(/\s+/)[0])
  return isFinite(n) && n >= 0 ? n : -1
}

// hwmon temp*_input (millidegrees) -> degrees C, or -1 when unknown.
function parseTemp(text) {
  var s = String(text || "").trim().split(/\s+/)[0]
  if (!/^-?\d+$/.test(s)) return -1
  var c = Number(s) / 1000
  // Anything outside this range is a broken sensor, not a real reading.
  if (c < -40 || c > 150) return -1
  return c
}

// `ps -eo pid=,pcpu=,pmem=,comm=` -> [{pid, cpu, mem, name}], bounded.
function parseProcesses(text) {
  var out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length && out.length < MAX_PROCESSES; i++) {
    var m = /^\s*(\d{1,10})\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\s+(.+?)\s*$/.exec(lines[i])
    if (!m) continue
    out.push({
      pid: Number(m[1]),
      cpu: Number(m[2]),
      mem: Number(m[3]),
      name: sanitizeName(m[4])
    })
  }
  return out
}

// Process names come from userland and are untrusted. Strip control
// characters and bound the length; the UI also renders them as PlainText.
function sanitizeName(value) {
  var s = String(value || "").replace(/[\u0000-\u001f\u007f]/g, "")
  if (s.length > MAX_PROCESS_NAME) s = s.slice(0, MAX_PROCESS_NAME - 1) + "…"
  return s || "?"
}

function clampPercent(value) {
  var n = Number(value)
  if (!isFinite(n)) return 0
  return Math.max(0, Math.min(100, n))
}

function percentOf(part, whole) {
  if (!(whole > 0)) return 0
  return clampPercent(100 * part / whole)
}

// Bytes -> {value, unit} using binary units, one decimal under 10.
function bytesParts(bytes) {
  var units = ["B", "KiB", "MiB", "GiB", "TiB"]
  var n = Math.max(0, Number(bytes) || 0)
  var u = 0
  while (n >= 1024 && u < units.length - 1) { n /= 1024; u++ }
  return { value: n, decimals: n < 10 && u > 0 ? 1 : 0, unit: units[u] }
}

// Seconds -> {days, hours, minutes}.
function uptimeParts(seconds) {
  var s = Math.max(0, Math.floor(Number(seconds) || 0))
  return {
    days: Math.floor(s / 86400),
    hours: Math.floor((s % 86400) / 3600),
    minutes: Math.floor((s % 3600) / 60)
  }
}

// Severity bucket for colouring a reading: "normal", "warn" or "critical".
function level(percent, warnAt, criticalAt) {
  if (percent >= criticalAt) return "critical"
  if (percent >= warnAt) return "warn"
  return "normal"
}

function clampInterval(value) {
  var n = Number(value)
  if (!isFinite(n)) return 2
  return Math.max(1, Math.min(60, Math.round(n)))
}
