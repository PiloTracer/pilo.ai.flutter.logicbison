---
name: flutter-perf
description: >-
  Establish and enforce Flutter performance budgets, statically audit build
  methods and widget trees for known jank causes, profile on real devices, and
  measure startup, frame timing, memory and app size against NFR targets. Never
  reports a measurement it did not take. Use for the app is slow, jank, dropped
  frames, startup time, app size, or profile it.
---

# flutter-perf

Performance work fails in two ways: optimising what is not slow, and declaring victory without measuring. This skill separates what can be **read** from the code (static audit) from what must be **measured** on a device (profiling), and never conflates them.

**Pairs with:** `flutter-verify` (D13), `flutter-implementation` (task-level patterns), `flutter-release` (size and startup gates), `FLS-01 widget-tree efficiency`, `FLS-08 performance budget`.

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`PERFORMANCE_STANDARD`](../../standards/20260801-PERFORMANCE_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never report a number you did not measure.** No device → `not run (no device)` plus the static findings. An invented millisecond figure is worse than no figure.
2. **Profile mode only.** Debug builds are 10–50× slower in places; a debug measurement is not evidence. Release mode has no profiling instrumentation. Profile mode, on a real device, is the only valid source.
3. **Measure on the reference device from doc 02 §3** — the lowest-tier device the product must feel good on. A flagship measurement proves nothing about the target.
4. **Budget before optimisation.** Every claim of "slow" is checked against the NFR figure. Without a number there is no defect, only a preference.
5. **Static findings are hypotheses.** A missing `const` is a smell, not a proven cost. Say so, and prioritise by likely impact rather than count.
6. **Never optimise without a before and an after.** Both measured the same way, on the same device, reported together.

---

## Modes

| Mode | Action |
|------|--------|
| `budget` | Establish or check the performance budget from doc 03 §5 NFRs |
| `audit` | **Static**, read-only: build-method and widget-tree analysis for known jank causes |
| `profile [route]` | **Device**: frame timing under interaction; identify UI-thread vs raster-thread cost |
| `startup` | **Device**: cold and warm start to first frame and to first meaningful frame |
| `size` | Artifact size analysis against the budget; top contributors |
| `memory` | **Device**: memory profile over a representative session; leak detection |
| `trace - <flow>` | **Device**: an automated timeline trace of a named flow, for regression tracking |
| `status` | Read-only: budget, last measurements, what is stale |

---

## budget protocol

Read the NFR table in doc 03 §5. Every performance NFR needs a number, a unit, a device and a method. Missing → **operator question**, never an invented target.

| Budget | Typical target | Device | Method |
|--------|----------------|--------|--------|
| Cold start → first frame | per doc 03 | reference device | `--trace-startup` |
| Cold start → first meaningful frame | per doc 03 | reference device | trace + app instrumentation |
| Frame build + raster, p99, during scroll | ≤16 ms at 60 Hz; ≤8 ms at 120 Hz | reference device | `profile` |
| Jank frames during the primary flow | a stated percentage | reference device | `trace` |
| Peak memory in a representative session | per doc 03 | reference device | `memory` |
| Release download size per platform | per doc 03 | n/a | `size` |
| Time to interactive after navigation | per doc 03 | reference device | `profile` |

Report each budget as `met` / `breached` / `not measured`. **`not measured` is not `met`.**

---

## audit protocol (static, read-only)

Read the code and report known jank causes. Ordered by typical impact.

| # | Finding | Why it costs | Detection |
|---|---------|--------------|-----------|
| P1 | Expensive work inside `build()` | `build` runs every frame during animation | Parsing, sorting, I/O, regex compilation, `DateTime.now()` formatting, or object graph construction inside `build` |
| P2 | Unbounded list without virtualisation | Builds every child up front | `Column`/`ListView(children: […])` over a variable-length collection instead of a builder |
| P3 | Rebuild scope too wide | A whole subtree rebuilds for one value | A state listener high in the tree wrapping a large subtree; no selector/`select` narrowing |
| P4 | Missing `const` on static subtrees | Forces rebuild and re-layout | Const-able widgets not marked const |
| P5 | Missing `RepaintBoundary` around an independently animating subtree | Repaints a large layer | Animation adjacent to expensive static content |
| P6 | Heavy synchronous work on the UI isolate | Blocks frames outright | JSON decode of a large payload, image decode, crypto, file parsing not moved to a worker isolate |
| P7 | Unbounded or unsized images | Decodes at full resolution into memory | No `cacheWidth`/`cacheHeight` or resize on large sources |
| P8 | Opacity, clipping and shadows in scrolling content | Expensive raster | `Opacity` where a color alpha would do; `ClipRRect` per list item; large blurred shadows |
| P9 | Layout thrash | Repeated measurement | Deeply nested `IntrinsicWidth`/`IntrinsicHeight`, or nested unbounded scroll views |
| P10 | Undisposed resources | Leak, then GC pressure | Controllers, streams, subscriptions, timers, focus nodes created without a matching dispose |
| P11 | Rebuild-triggering allocation in `build` | Defeats equality-based skipping | New closures, lists or objects created inline as widget parameters each frame |
| P12 | Over-eager state notification | Notifies on unchanged values | A notifier emitting without an equality check |
| P13 | Synchronous `setState` in a scroll or animation callback | Per-frame rebuild | Listener updating state on every scroll offset |
| P14 | Large `saveLayer` triggers | Expensive raster passes | Blend modes, `Opacity` over complex subtrees, backdrop filters |

**Report as hypotheses with priority:**

```markdown
| ID | Finding | Path:line | Likely impact | Confirm by |
|----|---------|-----------|---------------|------------|
| P2 | ListView with 400 inline children | `feed_screen.dart:112` | high | `profile - /feed` |
```

Never claim a static finding *is* the cause of a reported jank. Name the measurement that would confirm it.

---

## profile / startup / size / memory / trace

**`profile`** — build in profile mode, run on the reference device, exercise the route, capture frame timings. Report p50, p90, p99 for **build** and **raster** separately: they have different causes. Build-thread cost points at widget work (P1–P4, P11–P13); raster cost points at painting (P5, P8, P14). Include the jank-frame count and the worst frame with its phase breakdown.

**`startup`** — `--trace-startup` in profile mode, cold start (force-stopped, first launch after install where the budget says so) and warm start, at least three runs each, reporting median and spread. A single run is noise. Report the phase breakdown (engine init, Dart isolate start, first frame, first meaningful frame) so the fix has a target.

**`size`** — `--analyze-size` per platform. Report total, the delta versus the last recorded build, and the top contributors by category (Dart AOT, assets, fonts, native libraries, packages). Common wins: unused locales and fonts, oversized or uncompressed images, a heavyweight dependency pulled in for one function, and debug-only assets shipped in release.

**`memory`** — profile a representative session including navigation in and out of heavy screens repeatedly. Look for a baseline that never returns after leaving a screen (retained listeners, controllers, caches, image cache growth). Report peak, steady-state, and any monotonic growth.

**`trace - <flow>`** — an automated timeline capture of a named flow, saved to `{FLUTTER_WORK_ROOT}/reports/` with the device, OS, build mode, app version and git SHA, so it can be compared across releases. This is the regression-tracking artifact.

**Every device-mode report must state:** device model, OS version, build mode, app version, git SHA, and the number of runs. Without those, the number is not comparable and therefore not useful.

---

## Report shape

```markdown
## @flutter-perf <mode>

**Device:** <model, OS> · **Mode:** profile · **Build:** <version>+<build> @ <sha> · **Runs:** <n>
*(or)* **Device:** none available — static findings only

| Budget | Target | Measured | Verdict |
|--------|--------|----------|---------|
| Cold start → first frame | ≤2000 ms | 2340 ms (median of 5, range 2180–2510) | breached |

### Findings
| ID | Finding | Path | Evidence | Priority |

### Route
| Finding | Run next |
|---------|----------|
| Cold start breached; engine init 900 ms | `@flutter-repair repair - from perf` |

**Not measured:** <budgets with no device> — these are **not** passing.
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Anti-patterns

- Reporting a timing measured in debug mode.
- Measuring on a flagship when the reference device is mid-tier.
- Reporting a single run as a result.
- Claiming a static finding caused an observed jank without profiling.
- Adding `const` everywhere and declaring the performance work done.
- Optimising before there is a budget to breach.
- Reporting an improvement with no before-measurement.
- Treating `not measured` as `met`.
- Wrapping everything in `RepaintBoundary` — each one costs a layer.
- Moving work to a worker isolate without measuring that the transfer is cheaper than the work.
- Omitting device, OS, build mode and SHA from a measurement.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected | pass/fail | |
| 2 | Budget read from doc 03 §5; no target invented | pass/fail | NFR ids |
| 3 | Device modes run in profile mode on the reference device | pass/not run | device |
| 4 | ≥3 runs for timing measurements; median and spread reported | pass/skip | |
| 5 | Build and raster reported separately | pass/skip | |
| 6 | Static findings marked as hypotheses with a confirming measurement | pass/skip | |
| 7 | Device, OS, build mode, version and SHA recorded | pass/skip | |
| 8 | Unmeasured budgets marked `not measured`, not `met` | pass/fail | |
| 9 | Before/after both measured for any optimisation claim | pass/skip | |
| 10 | Findings routed | pass/fail | |
| 11 | Trace artifacts saved to `{FLUTTER_WORK_ROOT}/reports/` | pass/skip | paths |
