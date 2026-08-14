---
name: flutter-stack
description: >-
  Choose and lock the Flutter technology stack across seven dimensions - state
  management, navigation, dependency injection, serialization, HTTP, local
  store, and test doubles - then record the decision in .work.flutter/STACK.md
  so every other skill generates idiomatic, consistent code. Includes a probe
  mode that interrogates the team's context before recommending. Use when the
  user asks which packages to use, Riverpod vs Bloc, or to lock the stack.
---

# flutter-stack

A Flutter codebase is only as consistent as its stack decision. This skill makes that decision **once**, **explicitly**, and **with reasons**, then writes it to `{FLUTTER_STACK_LOCK}` where `@flutter-scaffold`, `@flutter-implementation`, `@flutter-data` and `@flutter-test` read it before generating a single line of code.

**Pairs with:** `flutter-bootstrap` (runs before), `flutter-foundation` (P2 depends on the lock), `flutter-scaffold` (generates per the lock), [`stacks/`](../../stacks/) (per-stack idiom rules), [`resources/packages-2026.md`](../../resources/packages-2026.md) (the vetted catalog).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Every package must be free, open source and commercial-use-permitted.** Allowed: MIT, BSD-2/3, Apache-2.0, Zlib, MPL-2.0 (file-level copyleft, acceptable as a dependency). Refused by default: GPL, AGPL, LGPL (static-link risk on mobile), CC-BY-NC, "source-available", or any package with a paid tier required for production use. See [`PACKAGE_LICENSE_STANDARD`](../../standards/20260801-PACKAGE_LICENSE_STANDARD.md).
2. **Verify before recommending.** Check the package on pub.dev for current version, license, publisher, and last-publish date. **Never recommend from memory** — the ecosystem moves quarterly. If you cannot verify, say `unverified` and let the operator decide.
3. **Recommend one, name the alternative.** A recommendation without a stated trade-off is an opinion, not advice.
4. **Team experience outweighs elegance.** The best stack is the one the team can maintain at 3am. Probe for it before recommending.
5. **A locked stack is binding.** Changing it after implementation starts requires an ADR in `{FLUTTER_DECISIONS_ROOT}` and a `@flutter-plan-master revise`. Say so at lock time.
6. **No stack sprawl.** One state-management library, one router, one serialization approach, one HTTP client per app. Two of anything requires a written reason in `STACK.md` § Exceptions.

---

## Modes

| Mode | Action |
|------|--------|
| `probe` | Interrogate the 7 dimensions (K1–K7) before deciding; ≤5 questions per pass |
| `probe - until ready` | Loop probe passes until coverage ≥85% and no ★ dimension unknown |
| `set` | Write `{FLUTTER_STACK_LOCK}` with the decision, rationale and versions |
| `set - <dimension>=<choice>` | Set one dimension (e.g. `set - state=riverpod`) |
| `detect` | Brownfield: read `pubspec.yaml` + `lib/` and infer the stack already in use |
| `show` / `status` | Read-only: current lock, unresolved dimensions, license status |
| `audit` | Read-only: verify installed packages against the lock and the license policy |

---

## Prerequisite gate (SK0)

`set` and `probe` require `{FLUTTER_HANDOFF}`.

```markdown
## @flutter-stack <mode> - blocked (prerequisite)

**Required:** `.work.flutter/context/HANDOFF_FLUTTER.md`
**Detected:** no project memory scaffold
**Run first:** `@flutter-bootstrap init`
```

---

## The seven dimensions

★ = gate-blocking. The lock cannot be written while a ★ dimension is unknown.

| Dim | Decision | Default recommendation | Alternatives |
|-----|----------|------------------------|--------------|
| **K1 ★** | **State management** | See [`stacks/README.md`](../../stacks/README.md) decision table | Riverpod · Bloc · Provider+ChangeNotifier (official MVVM) · signals |
| **K2 ★** | **Navigation** | `go_router` (Flutter-team maintained, declarative, deep-link native) | `auto_route` (codegen, typed) · raw Navigator 2.0 (only for unusual shells) |
| **K3 ★** | **Dependency injection** | Follow K1: Riverpod is its own DI; Bloc/Provider pair with `get_it` (+ `injectable` when the graph is large) | `get_it` standalone · constructor injection only (small apps) |
| **K4 ★** | **Models & serialization** | `freezed` + `json_serializable` (sealed unions, immutability, copyWith) | `dart_mappable` (less boilerplate, single generator) · hand-written `fromJson` (tiny apps) · `built_value` (legacy) |
| **K5** | **HTTP / networking** | `dio` when you need interceptors, retries, cancellation, upload progress; `http` when you need none of that | `dio` + `retrofit` (typed clients) · `chopper` |
| **K6 ★** | **Local store** | Match the shape of the data: key-value → `shared_preferences`; secrets → `flutter_secure_storage`; relational/queryable → `drift`; simple documents → `sqflite` or a document store | See [`DATA_LAYER_STANDARD`](../../standards/20260801-DATA_LAYER_STANDARD.md) § Local store selection |
| **K7** | **Test doubles** | `mocktail` (no codegen, null-safe, works with `sealed`/`final` classes) | `mockito` + `build_runner` (when the team already standardises on it) |

**Derived, not chosen** (fixed by the framework, recorded in the lock for completeness): `flutter_test` for unit/widget tests, `integration_test` for end-to-end, `matchesGoldenFile` for goldens, and the lint baseline from `analysis_options.yaml`.

---

## probe protocol

Engine: [`probe-protocol.md`](../probe-protocol.md). Coverage profile below; ledger is `{FLUTTER_STACK_LOCK}` § Probe ledger.

**Coverage map**

| Dim | Topic | ★ | What "confirmed" looks like |
|-----|-------|---|------------------------------|
| K1 | State management | ★ | A named library plus the reason (team experience, app complexity, testing needs) |
| K2 | Navigation | ★ | A named router plus whether deep links, guards and nested shells are required |
| K3 | Dependency injection | ★ | A named approach consistent with K1 |
| K4 | Models & serialization | ★ | A named approach plus whether the API shape is stable |
| K5 | HTTP | | A named client plus whether interceptors/retry/cancellation are needed |
| K6 | Local store | ★ | Data shape, size, query needs, encryption needs |
| K7 | Test doubles | | A named library consistent with the team's codegen appetite |

**Questions worth asking** (pick the ≤5 that are blocking; obey the quality bar in `probe-protocol.md`):

1. What has this team shipped before — Bloc, Riverpod, Provider, GetX, or nothing in Flutter?
2. How many developers will touch this codebase at once, and are they all Flutter-fluent?
3. How much of the app is genuinely async and cached (feeds, search, sync) versus form-and-submit?
4. Is there existing Flutter code here whose stack we must match rather than choose?
5. Does the app need to work offline, and if so: read-only cache, or full read-write sync?
6. Is the backend API contract stable and documented, or will response shapes churn?
7. Does the team accept code generation (`build_runner`) in the daily loop, or is that friction they will route around?
8. Do you need deep links / universal links, and do any routes require an auth guard?
9. Any organisational constraints — an approved-dependency list, a license policy, an air-gapped pub mirror?
10. Is this a single app, or an app plus shared packages (melos workspace)?

Record each answer in `STACK.md` § Rationale with the dimension it resolved. An unanswered ★ dimension after two passes goes to `UNKNOWNS.md` with an owner — and the lock stays open.

**Challenge pass** (per `probe-protocol.md` § The challenge pass) before `set`. Specifically test:

- C1 Where is the evidence for each ★ choice? (team answer this session, or existing code)
- C2 What would a hostile reviewer attack? (usually: codegen burden, or a library chosen for novelty)
- C3 What did we default rather than decide? (K5 and K7 are the usual silent defaults)
- C4 What breaks on a real device? (offline, background suspension, cold start with a large local store)
- C5 Cost of being wrong? K1 and K6 are **expensive to reverse** — confirm those explicitly with the operator; K5 and K7 are cheap.

---

## set protocol

### S1 — Verify each package

For every chosen package, confirm on pub.dev: current stable version, SPDX license, publisher, last publish date, Dart 3 / current-SDK compatibility. Record what you actually saw. Mark anything you could not check as `unverified — operator to confirm`.

**Refuse and report** any package failing the license policy. Offer the nearest compliant alternative from [`resources/packages-2026.md`](../../resources/packages-2026.md).

### S2 — Write the lock

Write `{FLUTTER_STACK_LOCK}`:

```markdown
# Technology stack — REPLACE:FLUTTER_PROJECT_NAME

**Status:** Locked
**Locked:** YYYY-MM-DD
**Locked by:** <operator>
**Changing this** requires an ADR in `.work.flutter/decisions/` + `@flutter-plan-master revise`.

## Decisions

| Dim | Choice | Package | Version | License | Rationale |
|-----|--------|---------|---------|---------|-----------|
| K1 State | <choice> | <pkg> | ^x.y.z | MIT | <one line> |
| K2 Navigation | … | | | | |
| K3 DI | … | | | | |
| K4 Models | … | | | | |
| K5 HTTP | … | | | | |
| K6 Local store | … | | | | |
| K7 Test doubles | … | | | | |

## Idiom rules

Binding per-stack rules: `stacks/<K1 choice>.md`. Every generated file follows them.

## Supporting packages

| Purpose | Package | Version | License | Why |
|---------|---------|---------|---------|-----|

## Exceptions

<Any second library in a dimension, with the reason. Empty is the healthy state.>

## Rejected

| Considered | Rejected because |
|------------|------------------|

## Probe ledger

<per probe-protocol.md ledger shape>
```

### S3 — Propagate

| Target | Update |
|--------|--------|
| `.cursorrules` | Replace `REPLACE:FLUTTER_STATE_MANAGEMENT`, `_NAVIGATION`, `_DI`, `_SERIALIZATION`, `_HTTP`, `_LOCAL_STORE`, `_TEST_DOUBLE` |
| `DOCS_FLUTTER_STACK.md` | Fill the dependency table and the verification commands |
| `{FLUTTER_HANDOFF}` | Append `Stack locked: <date> — <K1>/<K2>/<K3>` |
| `{FLUTTER_DECISIONS_ROOT}` | Write `YYYYMMDD-NNN-technology-stack.md` ADR recording the decision and the rejected options |
| `pubspec.yaml` | **Do not edit here.** `@flutter-scaffold app` adds dependencies so that `flutter pub get` runs inside its own gate |

### S4 — Report

```markdown
## @flutter-stack set

**Lock:** `.work.flutter/STACK.md`
**Coverage:** <NN>% · **Challenge:** defensible | defensible with gaps

| Dim | Choice | Version | License | Verified |
|-----|--------|---------|---------|----------|

**Open (→ UNKNOWNS.md):** <dims or none>
**Expensive to reverse:** K1 <choice>, K6 <choice> — confirmed with operator: yes/no
**Run next:** `@flutter-foundation greenfield` (or `continue` if P0–P1 are done)
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## detect protocol (brownfield)

Read `pubspec.yaml` dependencies and grep `lib/` for the tell-tale imports, then infer each dimension:

| Evidence | Inferred |
|----------|----------|
| `flutter_riverpod` / `hooks_riverpod` / `riverpod_annotation`; `ProviderScope` in `main.dart` | K1 = Riverpod |
| `flutter_bloc`; `BlocProvider`, `Cubit`, `Bloc` subclasses | K1 = Bloc |
| `provider`; `ChangeNotifierProvider`, `ChangeNotifier` view models | K1 = Provider + MVVM |
| `signals` / `signals_flutter` | K1 = signals |
| `go_router` / `auto_route` / bare `Navigator.push` | K2 |
| `get_it` (+ `injectable`) | K3 |
| `freezed` / `json_serializable` / `dart_mappable` / hand-written `fromJson` | K4 |
| `dio` / `http` / `retrofit` / `chopper` | K5 |
| `drift` / `sqflite` / `shared_preferences` / `flutter_secure_storage` / document stores | K6 |
| `mocktail` / `mockito` | K7 |

Write the lock with `Status: Detected` and flag every **conflict** (two state libraries, two routers, mixed serialization) as a finding routed to `@flutter-plan-repair`. Detection records reality — it does not endorse it.

---

## audit protocol

Read-only. For each dependency in `pubspec.yaml`:

| Check | Fail condition |
|-------|----------------|
| License policy | SPDX not in the allowed list (§ Hard rules 1) |
| Lock conformance | A package occupies a dimension the lock assigned to something else |
| Discontinued / unmaintained | pub.dev marks it discontinued, or no publish in >24 months with open severe issues |
| Duplicate role | Two packages serving the same dimension without a `STACK.md` § Exceptions entry |
| Transitive license | A transitive dependency carries a refused license |
| Pin hygiene | A direct dependency with no version constraint (`any`) |

Findings table: `ID | Package | Version | License | Finding | Severity | Fix`. Route to `@flutter-repair repair - from stack-audit`.

---

## Anti-patterns

- Recommending a package without checking its current pub.dev license and publish date.
- Choosing Riverpod or Bloc because it is fashionable, when the team has shipped the other one three times.
- Locking K1 while K6 is still unknown — offline requirements routinely invalidate a state-management choice.
- Adding both `provider` and `flutter_riverpod` "for now".
- Editing `pubspec.yaml` from this skill instead of letting `@flutter-scaffold` do it inside a gate.
- Writing the lock with a `Rationale` column full of "industry standard".
- Silently swapping the stack later because a generated file was easier to write another way.
- Treating `detect` output as a decision — detection is evidence, `set` is the decision.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | SK0 gate passed | pass/fail | HANDOFF path |
| 2 | All ★ dimensions resolved (K1–K4, K6) | pass/fail | lock table |
| 3 | Each package verified on pub.dev (version + license + date) | pass/fail | what was seen |
| 4 | Every license within policy | pass/fail | SPDX list |
| 5 | Rationale is specific, not generic | pass/fail | |
| 6 | Challenge pass run; verdict recorded | pass/fail | verdict |
| 7 | Expensive-to-reverse choices confirmed with operator | pass/fail | K1, K6 |
| 8 | `STACK.md` written with all sections | pass/fail | path |
| 9 | `.cursorrules` + `DOCS_FLUTTER_STACK.md` tokens replaced | pass/fail | |
| 10 | ADR written to `{FLUTTER_DECISIONS_ROOT}` | pass/fail | path |
| 11 | HANDOFF updated with the lock line | pass/fail | |
| 12 | Unresolved dimensions logged to `UNKNOWNS.md` with owners | pass/skip | |
