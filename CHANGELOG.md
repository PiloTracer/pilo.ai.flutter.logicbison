# Changelog

All notable changes to Flutter Agent OS. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The deploy skills (`@flutter-deploy-basic`, `@flutter-deploy-files`, `@flutter-deploy-repo`) read this file in their `update` mode (also spelled `--update`) to classify what changed between an installed version and the current one, so entries need to be accurate about scope.

---

## [Unreleased]

## [0.6.1] — 2026-08-19

_Version number aligns with the Agent OS family 0.6.1 line (previous Flutter Agent OS release: 0.2.0)._

### Changed — frameworks registry ships to targets; sister discovery in all three deploys (2026-08-19)

- **`scripts/sister-discovery.sh`** (new): the shared sister-framework discovery lib (legacy `.ai.<fw>` + family `pilo.ai.<fw>.logicbison` naming), copied from Agent OS so the deploy scripts resolve sibling frameworks with the same rules the directors use. Registered in `scripts/README.md` and the framework-verify required tree.
- **Frameworks registry lands in `.cursorrules` and every deployed target.** The framework's own `.cursorrules` carries the 7-row registry (self-hosted); `templates/cursorrules.flutter.snippet.template` carries the consumer registry (six rows — the Flutter row is the block's own `Framework:` pin, so the cell set is `REPLACE:AI_PATH` + `REPLACE:AI_*_PATH`), which full-template installs get via the existing `REPLACE:FLUTTER_SNIPPET_BLOCK` expansion. `SKILL_DEPENDENCIES.md` § Frameworks registry resolution now tables all six sisters and names the `.cursorrules` registry as authoritative.
- **All three deploy scripts fill the registry cells at install time.** `deploy-basic.sh` discovers sisters next to the source framework (thin installs read skills from there) and fills absolute paths; `deploy-files.sh` / `deploy-repo.sh` discover next to the target and fill `../`-relative paths. A cell whose sister is not installed stays `REPLACE:` and is named with what was checked — runtime auto-discovery handles it. The hardcoded `.ai` + `.ai.ui` collision note in `deploy-basic.sh` is now the six-name `.ai*` leak warning.
- **`deploy-verify.sh` gains a Frameworks registry section.** `REPLACE:AI*_PATH` tokens are scanned (pending warn with owner; never a fail — a missing sister is legitimate); an unfilled cell whose sister IS discoverable warns "installed but unfilled — re-run install/update"; a filled cell that no longer resolves to a framework is named. Matches the reference semantics of Agent OS `cursorrules-verify.sh`.
- **Verify rows in the three deploy skills** (`basic` row 12, `files`/`repo` row 10) and the `flutter-bootstrap` B6 token table document the registry cells; `deploy-verify.sh`'s `token_owner` stays in sync with B6.

### Changed — flutter-session reaches full session-bookend parity (2026-08-13)

- **`flutter-session` gains `start`, `add` and `scoped`.** `start` (with `open` / `begin` as aliases) is now the session-opening verb — `flutter-implementation` already routed to `@flutter-session start`, which previously named no mode. `add` is a stage-only checkpoint: it stages all safe in-scope changes (including new untracked files/dirs) without committing or closing, for mid-session review of the staged set. `close commit scoped` commits only the paths the close report names (in project scope, typically HANDOFF + NEXT), for operators who want bookend files only.
- **Git scope resolves by repo.** In adopter projects nothing changes: commits stay scoped to `.work.flutter/`, never app code. In the framework source repo — where `.work.flutter/` is gitignored scratch — `add` / `commit` / `push` apply to every safe modified, added and deleted file repo-wide (`git add -A` at the root; `.gitignore` keeps `TMP/` and scratch out). The discriminator: `.work.flutter/` present and not gitignored → project scope; absent or gitignored plus framework markers (`skills/README.md`, `standards/`, `scripts/framework-verify.sh`) → framework scope; neither → "not bootstrapped". The HANDOFF/NEXT steps are `skip` in the framework repo, where the commit message and this changelog carry the record.
- **The commit message is always shown.** A plain `close` drafts it, `commit`/`push` show it as used with the SHA, and a clean tree reads `none — working tree clean`. Subjects follow the shapes the `commit-msg` hook accepts: `F<n>-T<k>: …` auto-detected from the HANDOFF scope, the active iteration block, the branch name, or the last commit — falling back to `type: …` when no task ref applies.
- **Close and standalone commit now run a working-tree audit with a secrets scan.** A dirty or staged path matching credential patterns (`*.key`, `*.pem`, `*.jks`, `key.properties`, `.env`, …) halts the close/commit/add before any write or staging; content is never printed. `context` is uncommitted-aware: it reports staged / unstaged / untracked counts by area instead of letting the next agent assume a clean tree.
- **Requested git must run in the shell, verified.** A `close commit` that ends with a dirty `.work.flutter/` tree and only a drafted message is a recorded **fail**; post-commit `git status -sb` and the new SHA are quoted as evidence. Standalone `commit` / `commit push` / `add` write nothing to HANDOFF or NEXT and leave the session open; any modifier order or duplicates normalize to close → add → commit → push, stated in the report.
- **`flutter-session/reference.md`** (new): invocation examples, the mode comparison matrix, commit message examples, edge cases and wrong prompts. `skills/README.md` and `SKILL_DEPENDENCIES.md` rows updated to match the new verbs.

### Added — target-side deploy verification; order-independent deploy arguments (2026-08-10)

- **`scripts/deploy-verify.sh`** (new): the mechanical backbone of the three deploy skills' `verify` modes. It checks a target repo's pointer file, the framework location it records, and the `.cursorrules` Flutter block: exactly one ordered `FLUTTER_AGENT_OS_BEGIN/END` pair, no surviving deploy-owned `REPLACE:` tokens (`FLUTTER_FRAMEWORK_PATH`, `FLUTTER_SNIPPET_BLOCK`, `FLUTTER_PROJECT_NAME` — a failure, because the deploy should have filled them), every other unresolved `REPLACE:(FLUTTER|DART)_*` token named as **pending** with its owning step (bootstrap, stack, foundation, operator), the `Framework:` path resolving and matching the pointer's `Source:`, every `@flutter-*` route in the block resolving, gitignore scratch exclusions, and `framework-verify.sh` passing at the recorded location. A basic install whose recorded source differs from the running framework copy is warned about by name — that is how a moved framework is detected.
- **The deploy scripts now parse arguments order-independently.** The target may be positional or `--target <repo>`, and the lifecycle modes work bare or `--`-prefixed in any position: `update` ≡ `--update`, `verify` ≡ `--verify`, `status` ≡ `--status`, `uninstall` ≡ `--uninstall`. `verify` hands off to `deploy-verify.sh`; `update` and `uninstall` remain skill-run protocols, so the scripts route to the owning skill instead of acting. `deploy-basic.sh <target> update` and `deploy-basic.sh --target <target> --update` are byte-identical in output, and `self-test.sh` asserts it.
- **Deploys fill the tokens they legitimately know.** All three install scripts now substitute `REPLACE:FLUTTER_PROJECT_NAME` (target directory name) and `REPLACE:FLUTTER_APP_ROOT` when a root `pubspec.yaml` makes it unambiguous, in addition to `REPLACE:FLUTTER_FRAMEWORK_PATH`. Remaining tokens are left for their owning skills, and `deploy-verify.sh` names them instead of leaving them silent.
- The three deploy skills document the invocation parsing and gain verify rows for unresolved tokens and framework-path consistency, with `deploy-verify.sh` quoted as evidence.

---

## [0.2.0] — 2026-08-06

### Breaking — deploy skills split by install mode; session git scoped to `.work.flutter/` (2026-08-03)

- **`flutter-deploy` is split into three mode-owned skills:** `flutter-deploy-basic` (thin pointer install), `flutter-deploy-files` (fat self-contained copy), `flutter-deploy-repo` (pinned clone/archive/submodule). Each keeps the lifecycle modes for its own install type: `verify`, `uninstall`, `status`, and `update` — which **also accepts `--update`** as an identical alias, so `@flutter-deploy-basic update - <target>` and `@flutter-deploy-basic --update - <target>` both work. The old `flutter-deploy` skill id no longer resolves (it is split into the three above); targets with a `Mode: basic` pointer migrate to `@flutter-deploy-basic update`, `Mode: files` to `@flutter-deploy-files update`, `Mode: repo` to `@flutter-deploy-repo update`. The `deploy-basic.sh` / `deploy-files.sh` / `deploy-repo.sh` scripts are unchanged in name and now print the matching new skill in their update messages.
- **`flutter-session` git is scoped to the working directory.** `commit` stages and commits only `.work.flutter/` paths — never app code or files outside the project memory tree; `push` sends the current branch (which may already carry app-code commits from other actors) without `--force`. `close`, `commit` and `push` combine in any order (execution is always close → commit → push), and `commit` includes new untracked files/dirs under `.work.flutter/` (gitignored scratch such as `.work.flutter/analysis/tmp/` stays ignored). `push` commits pending `.work.flutter/` state first when needed, never force-pushes, and reports when no remote exists.

### Added — UI craft: teach it, wire it, enforce it (2026-08-02)

The framework verified that apps were *correct*; it never checked whether they *looked* decided. The difference between "correct" and "premium" is mechanical — spacing rhythm, one dominant element per screen, one accent colour — so it is now taught, wired into the gates, and machine-checked.

- **`UI_CRAFT_STANDARD`** (new standard): spacing rhythm from the theme scale (≤3 values per screen, literals are findings), one dominant element per screen at a recorded ratio (default 2.5×), one accent + neutral ramp with the accent on the primary action only, factory palettes forbidden, clarity rules for non-technical users, state-execution quality (skeleton/spinner thresholds, plain-language errors), and the "polish pass" as part of done
- **FLS-13 `ui-craft`** (new concept): the visual-craft review lens with verdict rules — factory palette, competing accents, or a screen with no recorded dominant element are blockers; "judged from code" is reported `unverified`, never passed
- **`dart-hygiene-check.sh`** now flags `Colors.<name>` factory constants (BLOCKER), raw `EdgeInsets`/`SizedBox`/`Gap` literals and `fontSize:` literals (MAJOR) outside theme files. Exclusions now apply at **path level** — theme files are where raw values are *defined*, and a check that fires there gets switched off (this also fixes the `Color(0x…)` scan firing inside `color_scheme.dart`)
- **`@flutter-verify` D15 "Visual craft"** joins the milestone audit (now 15 dimensions), mirrored in `QUALITY_GATES` G3; `FEATURE_SPEC_STANDARD` §5 requires each screen's dominant element and single primary action, because without that decision hierarchy is unverifiable
- **`@flutter-scaffold`** generates the craft wiring: spacing `ThemeExtension`, neutral ramp + single accent, dominant-element text style
- **`resources/ui-craft.md`** (new): the evidence base — every rule distilled with its source (Material 3, Apple HIG, Laws of UX, NN/g error/skeleton thresholds, Refactoring UI previews, the Stanford credibility figure cited precisely)
- Fixtures: new known-bad `cheap-ui.dart` and known-good `theme/app_theme.dart` (guards the path exemption); `clean.dart` re-baselined to consume a spacing token instead of `EdgeInsets.all(16)`, which the new spacing scan correctly forbids

### Fixed — pre-commit hook (2026-08-02)
- **`hooks/pre-commit` hygiene step exempts `scripts/fixtures/`.** The fixtures are deliberately-broken verifier test data whose gate is `self-test.sh`; without the exemption, any commit touching them blocked on their intended BLOCKERs — the framework could not commit its own fixtures

### Fixed — consistency gaps from the UI-craft review (2026-08-02)
- **`flutter-repair` gains the `from concept` source.** `flutter-concept-run` and the director's `ui-craft` bucket both routed there, but the skill never listed it — a dead route. The R4 re-verify map now re-runs the originating concept, and the open-language map routes "it looks cheap / basic" to FLS-13
- **`flutter-verify` Q7 fails on BLOCKER hygiene hits only; MAJOR/MINOR are routed findings.** "Any hit" predated the UI-craft scans and contradicted the pre-commit hook and `.quick/gates.md` ("blockers yes, notes no") — a waivable MAJOR could not have stayed non-blocking at the milestone gate
- **`deploy-repo.sh` no longer carries `plans/` into targets.** `deploy-files.sh` never copied it; the clone-based mode did. Both bundles are now identical in what they exclude

### Fixed — framework test-run against OfficeToolCombo (2026-08-02)
- **`readiness-verify.sh` false FAIL on `L1`-style ledger ids.** Entry rows like `| L1 |` were counted as zero questions; bare integers and a single letter prefix are both accepted
- **`probe-protocol.md` ledger shape** now matches the machine-checked template (Score + Q&A table), not a divergent Status/Conf sketch
- **`analysis_options.yaml.template`** includes `package:flutter_lints/flutter.yaml` directly — a leftover `REPLACE:FLUTTER_LINT_PACKAGE` token broke every analyze on fresh bootstrap
- **`traceability-verify.sh`** (and matching section cutters) end a numbered section only on the next `## ` heading, so `### F0` milestone subheads no longer empty §11
- **Catalog:** document that `sqlite3_flutter_libs` is EOL; Drift consumers use `package:sqlite3` ≥3.x
- **`flutter-deploy` basic:** empty target directories need `git init` before the pointer is written
- **`flutter-scaffold`:** pub-get must prove codegen pins against the installed SDK (`meta` pin vs latest `build_runner`)
- **`dart-hygiene-check.sh`:** skip layer-boundary rules under `test/`; allow `*_providers.dart` / `di/` as composition roots
- **`hooks/pre-push`:** framework repo runs `framework-verify` + `self-test` instead of `flutter test` (there is no app `test/` here); adopter repos without a test tree report `unverified` instead of a false block

### Fixed — pre-release consistency audit (2026-08-06)

A full cross-document sweep before tagging this release. Two real script defects; the rest is stale documentation corrected to match the code.

- **Deploy scripts left `REPLACE:FLUTTER_SNIPPET_BLOCK` unexpanded on fresh installs.** All three deploy scripts copied `cursorrules.flutter.template` verbatim when the target had no `.cursorrules`, so the `FLUTTER_AGENT_OS_BEGIN/END` marker block never landed and the framework-path substitution had nothing to bind to — `verify` and `uninstall` could not find the registered block. The scripts now expand the snippet the same way `templates/bootstrap.sh` does
- **`deploy-repo.sh` clone installs now exclude the same paths as the fat install.** `.github/`, `.vscode/`, and the framework's own `.cursorrules` and `.gitignore` were carried by clone mode but never by `deploy-files.sh`; both modes now produce identical trees. `--submodule` installs are the documented exception: exclusions cannot be applied without dirtying the submodule, so they carry the full tracked tree
- **`QUALITY_GATES` G3 realigned to the actual D1–D15.** The table claimed to be the fifteen dimensions of `@flutter-verify milestone` but listed File placement, Docs and l10n instead of Requirement coverage (D1), Mechanical gate (D9) and Scope discipline (D10)
- **Dead routes and modes corrected.** `flutter-session start` → `open` (director chain, dependency matrix, canonical verb table); `flutter-concept-run run-all` removed (`run - <scope>` already selects-then-runs); `@flutter-release ci` → `prepare`; `@flutter-director review` → `review-routing`; the repair source grammar in `docs/guides/repair.md` and `.quick/commands.md` now matches the skill (`analyze` / `verify` / `FLS-nn` / `operator` were never valid sources); analyzer-error routing now uses `from gate`
- **README skill count** corrected to 27 after the deploy split; the resources row now lists `ui-craft.md`; the verifier enumeration names FLS registration
- **Six-state naming drift:** the happy-path state is `Success` everywhere (two docs said "content")
- **`templates/work.flutter/STACK.md`** linked to `../standards/`, which does not resolve from the deployed `.work.flutter/STACK.md`; now `standards/`
- **COHABITATION.md** no longer claims a `standards/*FLUTTER*` filename prefix — standards are namespaced by directory
- **`.cursorrules`** no longer claims the `commit-msg` hook rejects all `Co-authored-by:` trailers — it rejects AI attribution and tool co-author trailers, matching the hook and the adopter template

## [0.1.1] — 2026-08-02

Ecosystem corrections. Several widely-repeated pieces of Flutter advice are now false, and a framework that repeats them teaches an agent to write code that does not compile, CI steps that do not run, and triage that changes the wrong files. Everything here is a correction to a factual claim, not a design change.

### Fixed — claims that were wrong
- **`flutter pub audit` does not exist.** `@flutter-security` now names the real mechanisms: `dart pub get` prints advisories but exits 0 regardless, so OSV-Scanner or Trivy is the actual gate
- **`custom_lint` has ended maintenance.** Replaced by the first-party `analysis_server_plugin` system under a top-level `plugins:` key, which runs under plain `dart analyze`. A leftover `custom_lint` CI step that no longer runs anything still exits 0, which reads as a pass
- **CocoaPods is no longer the iOS default.** `@flutter-doctor` `build - ios` now establishes whether the project uses Swift Package Manager before triaging, because a `Podfile` in the tree no longer settles the question
- **`golden_toolkit` is discontinued** — replaced by `alchemist` (MIT)
- Corrected licences in the catalog: `patrol` is Apache-2.0 (not BSD-3), `melos` is Apache-2.0 (not MIT), `sqflite` is BSD-2 (not MIT)

### Added — named package exclusions
The catalog's refusal policy was principled but abstract. It now names the packages, because abandonment status is the part of package advice that does not churn:
- `hive` (abandoned, and pub.dev reports `license:unknown`), `isar` (abandoned; **no Android 16 KB page support, which blocks Play Store submission**), `realm` (EOL September 2025), `dartz` (abandoned, unfinished), `redux`/`flutter_redux` (frozen), `dart_code_metrics` (went commercial)
- Permissive-licence-but-not-free: `objectbox` Sync is a paid product behind an Apache-2.0 binding, Shorebird and freeRASP are proprietary behind permissive wrappers

### Added — component contract
- `ARCHITECTURE_STANDARD` §1a maps the three layers onto the official View/ViewModel/Repository/Service components and states four import-checkable rules. Use cases are now explicitly conditional rather than default
- FLS-03 gained the component-contract questions; repository-to-repository imports and view-to-data imports are blockers
- `dart-hygiene-check.sh` mechanically detects both, without flagging an implementation importing its own interface
- `stacks/riverpod.md` gained a version-discipline table for Riverpod 3, covering the changes that alter behaviour **silently** rather than failing to compile — `ProviderException` wrapping, `==` update filtering, notifier recreation, out-of-view pausing, automatic retry
- `shared_preferences` guidance moved to `SharedPreferencesAsync` with the idempotent legacy migration call

---

## [0.1.0] — 2026-08-01

First release. Complete framework: plan, build, verify, repair.

### Orchestration
- `flutter-director` — free-text intake, classification, skill chaining, confirm gate
- `flutter-router` — read-only signpost, three-sentence answers with citations

### Planning
- `flutter-bootstrap` — idempotent, brownfield-safe project memory scaffold
- `flutter-stack` — locks seven stack dimensions with package verification
- `flutter-foundation` — P0–P6 foundation, certifies `plan-ready`
- `flutter-plan-master` — 21-section master plan, certifies `implementation-ready`
- `flutter-feature-spec` — 16-section SPECs with intake classification
- `flutter-plan-verify` — read-only planning audit
- `flutter-plan-repair` — planning remediation, including brownfield recovery

### Implementation
- `flutter-scaffold` — app, feature, package, flavor, CI, test harness generation
- `flutter-implementation` — iteration execution with a per-task gate
- `flutter-data` — entities, DTOs, repositories, sources, caching, migrations
- `flutter-platform` — channels, permissions, deep links, native config, parity
- `flutter-release` — prepare, certify, build, size, distribute

### Verification
- `flutter-verify` — milestone (14 dimensions), uncommitted, last, gate
- `flutter-test` — the pyramid: unit, widget, golden, integration, a11y
- `flutter-perf` — budgets, static audit, device measurement
- `flutter-a11y` — WCAG 2.2 AA against a running app
- `flutter-security` — eight-area audit assuming a compromised client

### Repair and support
- `flutter-repair` — code-layer remediation with mandatory re-verification
- `flutter-doctor` — toolchain diagnosis, classified before action
- `flutter-session` — HANDOFF, NEXT, context loading, state snapshots
- `flutter-concept-run` — FLS lens execution
- `flutter-docs` — guides, tutorials, reference, runbooks; nothing published unexecuted
- `flutter-deploy` — basic, files, repo installs; update with local-change detection

### Standards
20 standards plus `PROTECTED_SURFACES.json`: conventions, architecture, directory map, state management, data layer, navigation, testing, quality gates, performance, accessibility, security and privacy, observability, theming, localisation, master plan, feature spec, git workflow, documentation, ADR, code review.

### Concepts
FLS-01 widget-tree efficiency · FLS-02 state-management integrity · FLS-03 layer boundaries · FLS-04 async and error safety · FLS-05 navigation integrity · FLS-06 AI-assisted change safety · FLS-07 platform parity · FLS-08 performance budget · FLS-09 offline data integrity · FLS-10 accessibility and inclusivity · FLS-11 security and privacy · FLS-12 test integrity.

### Stacks and resources
Idiom guides for Riverpod, Bloc/Cubit, Provider, Signals. Vetted package catalog with licences, and a Flutter CLI reference. Every recommendation is free, open source and commercially usable.

### Scripts and hooks
Eight verifiers (`framework`, `master-plan`, `traceability`, `readiness`, `gate`, `touch-scope`, `blast-radius`, `dart-hygiene`), four installers, and five git hooks with `.local` chaining that preserves existing hooks.

`self-test.sh` runs every verifier against known-good and known-bad fixtures, asserting that clean input passes and that each specific defect is named in the output — so a verifier that regresses into passing everything is caught rather than trusted.

### Grilling
Shared probe protocol with an adaptive coverage loop and a challenge pass that attacks recorded answers. `readiness-verify.sh` fails ledgers claiming confirmation they did not earn.

### Notes
- Requires no sibling framework; cohabits cleanly with `.ai` and `.ai.ui` when present
- Readiness states: `scaffold → stack-locked → foundation-complete → plan-ready → implementation-ready → release-ready`
- No package versions are pinned anywhere. Verification against pub.dev at time of use is mandatory, because a pinned version in documentation is stale the week after it is written

[0.2.0]: https://github.com/PiloTracer/pilo.ai.flutter/releases/tag/v0.2.0
