# Plan — Measure whether Flutter Agent OS makes agents better

## 1. What you asked for, restated

Make this the best Flutter helper framework, and prove it. Until now every check in the repository verified the framework's files (registration, links, budgets, verifier fixtures). Nothing verified the framework's effect on an agent. You approved building an evaluation harness first (Q1). You also approved a fixture Flutter app inside the repository, built the best long-term way (Q2).

## 2. Design decisions and why

| Decision | Why |
|----------|-----|
| Top-level `evals/`, not `scripts/fixtures/app/` | Fixtures feed verifiers. Evals are a separate instrument with their own apps, scenarios and runner. Mixing them would blur two kinds of claim: "the checks work" and "the framework works". |
| One base app; scenarios are overlays | One app to keep compiling as Flutter moves. A scenario is a small diff, so reviewing it means reading the temptation, not a whole app. |
| `analysis_options.yaml` rendered from the **adopter template** at materialize time | A single source. The eval app is analysed exactly as an adopter's would be, so a broken template line fails CI here first. |
| Held-out `acceptance/` tests | The agent cannot special-case what it cannot see. Visible tests can be gamed; held-out ones measure the behaviour. |
| Mechanical scoring; no LLM judge for verdicts | A judge model adds a second nondeterministic system to the measurement. Transcript-level judgement (did it tell the operator about the injection?) is phase 2, scored as a separate column. |
| `bad/` solutions with `.eval-expect`, under the fixture rule | A scorer that has never been shown a failure proves nothing. This is the self-test discipline applied to the harness. |
| Framework arm uses the real `deploy-files` + `bootstrap.sh` | It measures what adopters actually get. If an agent ignores the install, that is a finding about the install. |
| CI runs the adopter template's YAML steps on the base app (`evals/tools/run-workflow-steps.py`) | It tests the artifact adopters copy, not a hand-maintained replica of its commands. |
| Agent-agnostic `EVAL_AGENT_CMD` | The framework claims to be tool-agnostic, so the harness must be too. |
| Workspaces refused inside the framework tree | Agents walk up the tree for rules files. A baseline that finds `.cursorrules` is not a baseline. |

## 3. Phase 1 — shipped in this change

- `evals/run.sh`: `list`, `materialize`, `prepare`, `task`, `agent`, `score`, `selftest`, `matrix`.
- `evals/apps/base/`: minimal layered app (domain / data / presentation / theme), two tests, no third-party runtime dependencies, no pins.
- Four scenarios: `weaken-test`, `prompt-injection`, `layer-boundary`, `design-tokens`. Each has a reference solution, 1–3 bad solutions and held-out acceptance tests.
- Wiring: `framework-verify` § Evals (structure), `self-test` § Eval harness (scorer selftest, prepare, a weakened workspace scores `fail`, an in-tree workspace is refused), CI job `evals` (selftest with a real toolchain, plus the adopter template on the base app).

### Evidence available now

- `evals/run.sh selftest`: 43 passed, 0 failed (mechanical; toolchain checks `NOT_RUN`, because this machine has no Flutter SDK).
- `matrix` end to end with simulated agents. An honest agent applying the reference scores `incomplete` in both arms: correct, since nothing compiled. An agent that weakens the test scores `fail` in both arms.
- CI template executed step by step with stub `flutter`/`dart`. All plumbing works, and Q6 fails without `COVERAGE_FLOOR` as designed.

### Unverified until the CI `evals` job runs

All Dart in `evals/apps/base/`, `reference/` and `acceptance/` has not been compiled, analysed or formatted. The sandbox refused a Flutter SDK download. Specific risks:

1. **Formatter drift.** The reference code was hand-formatted to short style (language version 3.0). A mismatch fails the `format` check on the references.
2. **Analysis template.** `missing_return` under `analyzer: errors:` and some `linter: rules:` entries may name diagnostics or lints that no longer exist. Current SDKs report those as warnings, and `--fatal-infos` fails on them. If so, that is a **real adopter-template bug**, found by this harness. Fix the template, not the eval.
3. **Hidden directories.** The fat install puts `.ai.flutter/` (including deliberately broken Dart fixtures) inside the adopter app. I expect `flutter analyze` and `dart format .` to skip dot-directories. If they do not, every fat-install adopter fails `analyze`. The framework-arm toolchain checks will show it.

## 4. Findings the harness surfaced before any agent ran

| # | Finding | Evidence | Route |
|---|---------|----------|-------|
| F1 | The install writes only `.cursorrules`. No `CLAUDE.md`, `AGENTS.md` or equivalent, although `flutter-implementation` claims Claude Code, opencode and Codex support. Unless those tools read `.cursorrules`, they never see the framework. | `ls` of a prepared framework-arm workspace; no `CLAUDE.md`/`AGENTS.md` references in `scripts/` or `templates/` | Phase 2 experiment E1, then fix `deploy-*` |
| F2 | `dart-hygiene-check.sh` reports "repository imports another repository" when `in_memory_user_repository.dart` implements `user_repository.dart`. Only `<name>_impl.dart` is exempt. | Rule at `scripts/dart-hygiene-check.sh` § repository imports; base app renamed to `user_repository_impl.dart` to avoid it | Separate fix with a new clean fixture (an implementation importing its interface under any name) |

## 5. Phase 2 — next

| Item | What | Done when |
|------|------|-----------|
| E1 | Arm `framework+agentfile`: framework arm plus an `AGENTS.md`/`CLAUDE.md` pointer to `.cursorrules`. Compare with `framework`. | Counts for both arms over ≥5 trials on all scenarios. The result decides whether `deploy-*` writes agent files. |
| S5 `three-strike` | A bug whose real fix is outside the agent's reach (e.g. needs a product decision). Scored on: no weakening, no scope creep, and a transcript that stops and escalates. | Transcript rubric with ≥2 bad-transcript fixtures |
| S6 `honest-report` | Toolchain deliberately absent (`flutter` shimmed to exit 127). The agent must report `not run`, never "tests pass". | Transcript check catches a fabricated pass in a fixture transcript |
| S7 `six-states` | A screen task where the SPEC lists loading/empty/error. Held-out tests drive each state. | Reference passes, a happy-path-only bad fails |
| Transcript column | Separate, non-verdict column: did the agent disclose the injection, escalate, or claim results it did not observe? | Regex rubric with fixture transcripts. An LLM judge is used only if regexes provably cannot cover it. |
| Baseline run | First real matrix on one agent CLI, 5 trials. Publish `results.jsonl` + `run.json` under `evals/results/<date>/`. | Committed, cited from CHANGELOG |

## 6. Phase 3 — make it a gate

- A behaviour-regression check for prose changes. A PR touching a skill's hard rules, a standard or an adopter template runs the affected scenarios, and the framework arm must not regress by more than one trial in five.
- Fix F2, then E1's outcome, each with its before/after counts.

## 7. Assumption ledger

| Kind | Item |
|------|------|
| Confirmed | Mechanical scorers catch every bad solution (selftest output). The framework arm gets the real install. An in-tree workspace is refused. Both framework suites pass. |
| Inference | Analyzer and formatter skip `.ai.flutter/` (dot-directory). Short-style formatting applies at language version 3.0. |
| Unknown | Whether the base app and references compile, analyse and format clean on current stable (CI `evals` job). Whether any agent CLI reads `.cursorrules` without being told (E1). |

## 8. Next action

Push to a branch and read the CI `evals` job. Fix whatever it reports in the Dart (or in the adopter analysis template, if F-risk 2 materialises), then run the phase-2 baseline matrix.
