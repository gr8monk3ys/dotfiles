// Run with: node --test ~/.config/omarchy/plugins/gr8monk3ys.sysstats/tests/
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const source = readFileSync(new URL("../Model.js", import.meta.url), "utf8")
const M = {}
vm.runInNewContext(source, M)

test("splitSections parses sampler output", () => {
  const s = M.splitSections("@stat\ncpu 1 2 3 4\n@load\n0.5 0.4 0.3 1/2 3\n@temp\n")
  assert.equal(s.stat, "cpu 1 2 3 4")
  assert.equal(s.load, "0.5 0.4 0.3 1/2 3")
  assert.equal(s.temp, "")
})

test("cpu percent from two samples", () => {
  const a = M.parseCpuLine("cpu  100 0 100 800 0 0 0 0 0 0")
  const b = M.parseCpuLine("cpu  150 0 150 900 0 0 0 0 0 0")
  assert.equal(M.cpuPercent(a, b), 50)
  assert.equal(M.cpuPercent(null, b), -1)
  assert.equal(M.cpuPercent(b, b), -1)
  assert.equal(M.parseCpuLine("cpu0 1 2 3 4"), null)
  assert.equal(M.parseCpuLine("cpu x y z w"), null)
})

test("meminfo", () => {
  const m = M.parseMeminfo("MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 400 kB\nSwapTotal: 200 kB\nSwapFree: 50 kB\n")
  assert.equal(m.total, 1000 * 1024)
  assert.equal(m.used, 600 * 1024)
  assert.equal(m.swapUsed, 150 * 1024)
  assert.equal(M.parseMeminfo("garbage"), null)
})

test("loadavg, uptime, temp", () => {
  assert.deepEqual(Array.from(M.parseLoadavg("1.5 0.75 0.25 2/300 1234")), [1.5, 0.75, 0.25])
  assert.equal(M.parseLoadavg("nope"), null)
  assert.equal(M.parseUptime("3661.2 100.0"), 3661.2)
  assert.equal(M.parseTemp("47000"), 47)
  assert.equal(M.parseTemp(""), -1)
  assert.equal(M.parseTemp("999999"), -1)
  assert.equal(M.parseTemp("<b>1</b>"), -1)
})

test("process names are bounded and stripped of control chars", () => {
  const long = "x".repeat(200)
  const p = M.parseProcesses(`  12  3.5  1.2 firefox\n  13 0.0 0.1 bad\u0007name\n 14 1 1 ${long}\n junk line\n`)
  assert.equal(p.length, 3)
  assert.equal(p[0].name, "firefox")
  assert.equal(p[0].cpu, 3.5)
  assert.equal(p[1].name, "badname")
  assert.ok(p[2].name.length <= 32)
})

test("markup-shaped process names stay as literal text", () => {
  // The panel renders names with Text.PlainText; the model must not alter
  // or interpret markup, only bound it.
  const tracker = '<img src="https://example.invalid/t">'
  const p = M.parseProcesses(`1 0 0 ${tracker}\n`)
  assert.equal(p[0].name, tracker.slice(0, 31) + "…")
  assert.ok(!p[0].name.includes("\n"))
})

test("process list is capped", () => {
  const lines = Array.from({ length: 50 }, (_, i) => `${i + 1} 1.0 1.0 p${i}`).join("\n")
  assert.equal(M.parseProcesses(lines).length, 8)
})

test("formatting helpers", () => {
  assert.deepEqual({ ...M.bytesParts(1536 * 1024 * 1024) }, { value: 1.5, decimals: 1, unit: "GiB" })
  assert.deepEqual({ ...M.uptimeParts(90061) }, { days: 1, hours: 1, minutes: 1 })
  assert.equal(M.level(95, 70, 90), "critical")
  assert.equal(M.level(75, 70, 90), "warn")
  assert.equal(M.level(10, 70, 90), "normal")
  assert.equal(M.clampInterval("abc"), 2)
  assert.equal(M.clampInterval(0), 1)
  assert.equal(M.clampInterval(1000), 60)
  assert.equal(M.percentOf(1, 0), 0)
})
