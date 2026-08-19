---
name: flutter-bootstrap
description: >-
  One-time setup of Flutter Agent OS in a repository. Scaffolds .work.flutter/
  project memory, .cursorrules agent rules, DOCS_FLUTTER_STACK.md and a baseline
  analysis_options.yaml from templates; installs git hooks; detects brownfield
  state and never silently overwrites. Use when the repo has no .work.flutter/,
  or when the user says bootstrap, init, set up, or start a Flutter project.
---

# flutter-bootstrap

Create the project-memory scaffold that every other skill reads and writes. Idempotent and brownfield-safe: existing files are **never** overwritten without an explicit answer.

**Pairs with:** `flutter-stack` (next step), `flutter-foundation` (needs the scaffold), `flutter-deploy-basic` / `flutter-deploy-files` / `flutter-deploy-repo` (install the framework itself into a repo — this skill sets up the *project* side).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

- **Never overwrite without an answer.** Every existing target is either skipped or overwritten by an explicit operator choice recorded in the run report.
- **Never write inside this framework directory.** All output goes to the adopter repo: `{FLUTTER_WORK_ROOT}` and repo root.
- **Never invent project facts.** The scaffold ships templates with `REPLACE:FLUTTER_*` tokens. Filling them is `@flutter-stack` and `@flutter-foundation`'s job, not this skill's.
- **Report every token that still needs replacing.** A bootstrap that leaves silent placeholders is a failed bootstrap.

---

## Modes

| Mode | Action |
|------|--------|
| `init` | Scaffold `.work.flutter/`, `.cursorrules`, `DOCS_FLUTTER_STACK.md`, `analysis_options.yaml`; install git hooks |
| `init - <path>` | Same, targeting a different repo root |
| `status` | Read-only: what exists, what is missing, which tokens are unreplaced |
| `hooks` | Install or reinstall git hooks only |

---

## Prerequisite gate (B0 — brownfield detection)

Before writing anything, detect:

| Signal | Meaning |
|--------|---------|
| `.work.flutter/` exists | Already bootstrapped |
| `.cursorrules` exists | Agent rules already present (may belong to `.ai` / `.ai.ui`) |
| `pubspec.yaml` exists | Existing Dart/Flutter package — brownfield |
| `lib/` has source files | Existing code — foundation must be reconstructed, not invented |
| `analysis_options.yaml` exists | Existing lint config — do not clobber a team's rules |
| `.ai/` or `.ai.ui/` sibling present | Cohabitation — merge `.cursorrules`, do not replace |

**When any signal fires, ask once** with these options and record the answer:

```markdown
## @flutter-bootstrap init - existing artifacts detected

| Path | State |
|------|-------|
| <path> | exists (<n> bytes, modified <date>) |

Choose: `keep` (skip all existing) · `overwrite-missing` (default — create only what is absent)
· `overwrite-all` (replace, destructive) · `abort`
```

Default when the operator does not answer: **`overwrite-missing`**. Never `overwrite-all` by default.

**Brownfield follow-through:** when `lib/` already has source, the run report must recommend `@flutter-plan-verify brownfield` rather than `@flutter-foundation greenfield` — the product decisions already exist in the code and must be **recovered**, not authored.

---

## init protocol

### B1 — Resolve roots

| Root | Resolution |
|------|-----------|
| Framework root | directory containing `skills/README.md` (this tree) |
| Repo root | `git rev-parse --show-toplevel`, else the `- <path>` argument, else cwd |
| `{APP_ROOT}` | nearest directory with `pubspec.yaml`; if none, repo root (recorded as "app not yet created") |

Report all three. If the repo root cannot be determined, stop — do not guess.

### B2 — Scaffold project memory

Run [`templates/bootstrap.sh`](../../templates/bootstrap.sh), which creates:

```text
.work.flutter/
├── README.md
├── touch-scope                      # JSON scope declaration
├── PROTECTED_SURFACES.json
├── STACK.md                         # placeholder until @flutter-stack set
├── context/HANDOFF_FLUTTER.md
├── plans/
│   ├── NEXT_FLUTTER.md
│   ├── ASSUMPTIONS.md
│   ├── RISK_REGISTRY.md
│   ├── UNKNOWNS.md
│   ├── foundation/  (+ PROBE_LEDGER.md, README.md)
│   ├── full/  proposals/  archives/  operations/
├── features/README.md
├── decisions/README.md
├── prompts/README.md
├── reports/README.md
├── standards/                       # filled by @flutter-foundation P3
├── analysis/
└── docs/{guides,tutorials,reference}/
```

### B3 — Agent rules

| Case | Action |
|------|--------|
| No `.cursorrules` | Copy `templates/cursorrules.flutter.template` |
| `.cursorrules` exists, no Flutter block | Append the block from `templates/cursorrules.flutter.snippet.template` between `FLUTTER_AGENT_OS_BEGIN` / `FLUTTER_AGENT_OS_END` markers |
| `.cursorrules` exists **with** the markers | Replace only what is between the markers; preserve everything else |

Never rewrite a `.cursorrules` wholesale — it may carry `.ai` and `.ai.ui` rules.

### B4 — Toolchain files

| File | Action |
|------|--------|
| `analysis_options.yaml` | Create from `templates/analysis_options.yaml.template` if absent; if present, **report the diff** against the template and let the operator decide |
| `DOCS_FLUTTER_STACK.md` | Create from template if absent — the pinned toolchain and the exact verification commands |
| `.gitignore` | Append Flutter/Dart entries only if absent (never remove existing lines) |

### B5 — Git hooks

Run `scripts/install-git-hooks.sh`. Installs `pre-commit` (touch-scope + blast-radius + gate evidence), `prepare-commit-msg` (strip AI attribution, prepend task ref), `commit-msg` (reject attribution, warn on missing ref), `post-commit` (write `.work.flutter/commit-ref-pending/<sha>`).

Skip silently when `.git/` is absent; say so in the report.

### B6 — Token audit

Scan every created file for `REPLACE:FLUTTER_*` tokens and list them with their owning skill:

| Token | Filled by |
|-------|-----------|
| `REPLACE:FLUTTER_PROJECT_NAME` | the deploy script (target directory name) — re-run install/update |
| `REPLACE:FLUTTER_APP_ROOT` | `@flutter-bootstrap` (auto when `pubspec.yaml` is found) |
| `REPLACE:FLUTTER_STATE_MANAGEMENT`, `_NAVIGATION`, `_DI`, `_SERIALIZATION`, `_LOCAL_STORE`, `_HTTP`, `_TEST_DOUBLE` | `@flutter-stack set` |
| `REPLACE:FLUTTER_SDK_VERSION`, `REPLACE:DART_SDK_VERSION` | `@flutter-bootstrap` from `flutter --version`, else operator |
| `REPLACE:FLUTTER_PLATFORMS` | `@flutter-foundation` P1 |
| `REPLACE:FLUTTER_MIN_IOS`, `REPLACE:FLUTTER_MIN_ANDROID_SDK` | `@flutter-foundation` P1 |
| `REPLACE:FLUTTER_COVERAGE_MIN` | `@flutter-foundation` P3 (default 80) |
| `REPLACE:FLUTTER_TASK_REF_PREFIX` | operator (default `FLT`) |
| `REPLACE:AI_PATH`, `REPLACE:AI_UI_PATH`, `REPLACE:AI_BIZ_PATH`, `REPLACE:AI_SOC_PATH`, `REPLACE:AI_CTO_PATH`, `REPLACE:AI_MLT_PATH` | the deploy script (sister framework discovery) — re-run install/update; an unfilled cell is expected when the sister is not installed |

### B7 — Run report

```markdown
## @flutter-bootstrap init

**Framework root:** <path>
**Repo root:** <path>
**App root:** <path | not yet created>
**Brownfield:** yes (<signals>) | no
**Mode:** overwrite-missing | keep | overwrite-all

| Artifact | Result |
|----------|--------|
| `.work.flutter/` | created (<n> files) / existed |
| `.cursorrules` | created / block appended / block updated / kept |
| `analysis_options.yaml` | created / kept (diff reported) |
| `DOCS_FLUTTER_STACK.md` | created / kept |
| git hooks | installed (<n>) / skipped (no .git) |

**Unreplaced tokens:** <n> — see table above
**Toolchain:** flutter <version> · dart <version> | not on PATH

**Run next:**
1. Replace `REPLACE:FLUTTER_PROJECT_NAME` and `REPLACE:FLUTTER_TASK_REF_PREFIX` in `.cursorrules`
2. `@flutter-stack probe` (or `set` if the stack is already decided)
3. `@flutter-foundation greenfield`   ← greenfield
   `@flutter-plan-verify brownfield`  ← existing codebase
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## status protocol

Read-only. Report the same artifact table as B7 plus the readiness chain from `@flutter-director status`, and the unreplaced-token count. No writes.

---

## hooks protocol

Run `scripts/install-git-hooks.sh` only. Report which hooks were installed or refreshed and what each enforces. Existing non-framework hooks are preserved as `<hook>.local` and chained, never deleted.

---

## Anti-patterns

- Overwriting `.cursorrules`, `analysis_options.yaml` or `pubspec.yaml` without an explicit answer.
- Running `flutter create` from this skill — app scaffolding is `@flutter-scaffold app`, and it needs a locked stack first.
- Filling `REPLACE:` tokens with plausible guesses.
- Reporting "bootstrapped" while tokens remain unreplaced.
- Recommending `@flutter-foundation greenfield` on a repo that already has a `lib/` full of source.
- Writing project artifacts into the framework directory.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | B0 brownfield detection run; mode chosen | pass/fail | signals list |
| 2 | Roots resolved and reported | pass/fail | three paths |
| 3 | `.work.flutter/` scaffold present and complete | pass/fail | file count |
| 4 | `.cursorrules` created or merged (never clobbered) | pass/fail | |
| 5 | `analysis_options.yaml` + `DOCS_FLUTTER_STACK.md` handled | pass/skip | |
| 6 | Git hooks installed, or skip reason recorded | pass/skip | hook count |
| 7 | Unreplaced tokens listed with owning skill | pass/fail | token count |
| 8 | Correct next step recommended (greenfield vs brownfield) | pass/fail | |
| 9 | Nothing written inside the framework directory | pass/fail | |
