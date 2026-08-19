# Skill dependency graph — Flutter Agent OS

**Purpose:** Single source of truth for **which skill may run before which**. Skills implement these rules in their own `skill.md` § Prerequisite gate; this file is the registry operators and maintainers read first.

**Invocation punctuation:** Use ASCII hyphen **`-`** between verb and argument (e.g. `@flutter-implementation plan - F1`, `@flutter-feature-spec create - checkout`, `@flutter-router - how do I run goldens?`). Do **not** use em dash `—` in commands.

---

<a id="operator-handoff-contract"></a>

## Operator handoff contract (mandatory for every skill)

Implements the operator-provided **Response Clarity Protocol** (origin: `{FLUTTER_PROMPTS_ROOT}/improve-clarity-of-responses.md`). Every skill response that ends a turn must be **terse** and close with exactly one of two forms. No skill may invent a third.

**Form A — nothing needed:** a single line stating no user input is required (e.g. `Next: nothing - work complete`). Do not render empty sections.

**Form B — input needed:** end the response with this skeleton; omit any section that has nothing in it; nothing after `**Next step:**`:

```markdown
**Needs your approval:**
1. <Decision> — see path/to/file.md:L42
2. <Decision> — see path/to/file.md (lines 40–45)

**Needs your answer:**
1. <Question>
2. <Question>

**Next step:**
`<exact command or action to run>`
```

Rules:

1. **Brevity.** Report only what changed and what is needed next. No restating the task, no filler transitions, no unrequested rationale. Short declarative sentences.
2. **Exact references.** Approvals cite the project-root-relative path **and** line number(s): `path/to/file.md:L42` or `path/to/file.md (lines 40–45)`. Never make the operator hunt.
3. **Decisions and questions are separate lists.** One decision per numbered item, each answerable with a single yes/no or choice. Questions numbered in their own list, self-contained — answerable without re-reading prior context. Never mix the two in one list.
4. **One next step.** Exactly one command or action, isolated at the end in exact syntax. If multiple sequential actions exist, present only the immediate one; mention later ones only if the operator asks.
5. **Nothing buried, nothing empty.** Never end a response with an unstated expectation; never render an empty section; never hide an operator action inside a paragraph.
6. **Report-internal sections do not replace the close.** A template's "Follow-ups" / "Remaining" / "Recommended next" section is report content; any operator-required approval or question in it must ALSO appear in the Form B close.

**Enforcement:** `scripts/framework-verify.sh` fails any `skills/<id>/skill.md` that does not reference this contract (`#operator-handoff-contract`).

---

<a id="document-clarity-contract"></a>

## Document clarity contract (mandatory for document-generating skills)

Implements the operator-provided **Documentation Clarity Protocol** (origin: `{FLUTTER_PROMPTS_ROOT}/improve-clarity-of-documentation.md`). Applies to every document a skill generates: plans, SPECs, ADRs, guides, tutorials, reference docs, reports.

1. **Header answers three questions (≤4 lines):** what it is (one sentence) · **Status** (`Draft` | `In review` | `Approved` | `Superseded` + date) · what it needs (one line, or `nothing`).
2. **Brevity.** Summary first; every section informs a decision or an action; no boilerplate.
3. **Exact references.** Claims cite `path/to/file.md:L42`; quantitative claims tagged `measured` | `estimated` | `assumption` | `unknown` (per [`concepts/README.md`](../concepts/README.md)).
4. **Decisions and questions in separate numbered lists** — `## Decisions needed` vs `## Open questions`; never mixed, never buried in prose; each item self-contained.
5. **`## Next action` section** — exactly one action in exact syntax, or one line `Next action: none — <reason>`.
6. **Non-negotiables:** no empty or placeholder sections (omit or write `none` + reason); no document without a Status line; no unstated expectations; template scaffolding (`REPLACE:*`, instructional comments) stripped or filled before a document is presented as complete.

**Enforcement:** `scripts/framework-verify.sh` fails any document-generating skill (`flutter-foundation`, `flutter-plan-master`, `flutter-plan-repair`, `flutter-feature-spec`, `flutter-docs`) whose `skill.md` does not reference this contract (`#document-clarity-contract`).

---

## Work tree path resolution (mandatory)

**Repository root** (`.git/`, `pubspec.yaml`, `.cursorrules`) is **not** `{FLUTTER_WORK_ROOT}`. All skills resolve placeholders from **repo root** per the `.cursorrules` placeholder map (or this table).

| Placeholder | Resolved path | Common wrong path |
|-------------|---------------|-------------------|
| `{FLUTTER_WORK_ROOT}` | `.work.flutter/` | `work.flutter/`, repo root |
| `{FLUTTER_HANDOFF}` | `.work.flutter/context/HANDOFF_FLUTTER.md` | `context/HANDOFF.md` |
| `{FLUTTER_NEXT}` | `.work.flutter/plans/NEXT_FLUTTER.md` | `plans/NEXT.md`, bare `NEXT.md` |
| `{FLUTTER_PLANS_ROOT}` | `.work.flutter/plans/` | `plans/` |
| `{FLUTTER_SPEC_ROOT}` | `.work.flutter/features/` | `features/`, `lib/features/` |
| `{FLUTTER_DECISIONS_ROOT}` | `.work.flutter/decisions/` | `decisions/` |
| `{FLUTTER_STANDARDS_ROOT}` | `.work.flutter/standards/` | repo-root `standards/` |
| `{FLUTTER_DOCS_ROOT}` | `.work.flutter/docs/` | `docs/` |
| `{FLUTTER_PROMPTS_ROOT}` | `.work.flutter/prompts/` | `prompts/` |
| `{FLUTTER_MASTER_PLAN}` | `.work.flutter/plans/full/*-full-plan.md` (latest **Approved**) | `plans/full/…` |
| `{FLUTTER_TOUCH_SCOPE}` | `.work.flutter/touch-scope` | `touch-scope` |
| `{FLUTTER_PROBE_LEDGER}` | `.work.flutter/plans/foundation/PROBE_LEDGER.md` | `PROBE_LEDGER.md` |
| `{FLUTTER_STACK_LOCK}` | `.work.flutter/STACK.md` | `STACK.md` |
| `{APP_ROOT}` | Dart package root holding `pubspec.yaml` (repo root, or `apps/<app>/` in a melos workspace) | `lib/` |

**Rule for agents:** In mandatory-read tables, file-read tool calls, and blocked reports, use the **Resolved path** column. Never strip the `.work.flutter/` prefix. Shorthand (`HANDOFF_FLUTTER`, `NEXT_FLUTTER`) in prose still means the resolved path above.

**Framework artifacts are never project artifacts.** Nothing under this framework directory is written during project work. Project memory lives in `{FLUTTER_WORK_ROOT}`; application code lives under `{APP_ROOT}`.

---

## Frameworks registry resolution (cross-framework skills — mandatory)

`@flutter-director` (when redirecting outside Flutter) must resolve sibling framework roots in **this exact order** before routing. Never assume a fixed absolute path.

1. **`.cursorrules` § Frameworks registry** — the file shipped to every adopter repo. If it names a path for a framework, use it. It is the **authoritative** registry; the table below mirrors it for skills that run before a deploy has happened.
2. **Sibling auto-discovery** from this framework's parent directory: `parent="$(cd "$FLUTTER_OS_ROOT/.." && pwd)"; test -d "${parent}/.ai"`. Sister dirs follow legacy `.ai.<fw>` naming or family naming (source basename with `<fw>` inserted before its last dot-segment, e.g. `pilo.ai.ui.logicbison` for a `pilo.ai.logicbison` source) — `scripts/sister-discovery.sh` implements both and is what the deploy scripts use.
3. **Preflight:** verify `<framework_root>/skills/README.md` is readable before invoking that framework's director. Absent → output one line `framework not installed here` and stop. Never route into the void.

| Framework | Role | Director | Preflight target |
|-----------|------|----------|------------------|
| Flutter Agent OS (*this tree*) | Flutter app planning, build, verify, repair | `@flutter-director` | `skills/README.md` |
| Agent OS (`.ai`) | Backend, DB, infra, cross-cutting SDLC | `@ai-director` | `../.ai/skills/README.md` |
| Business OS (`.ai.biz`) | Business operations and process automation | `@biz-director` | `../.ai.biz/skills/README.md` |
| CTO Professor OS (`.ai.cto`) | Architecture and technical leadership coaching | `@cto-director` | `../.ai.cto/skills/README.md` |
| MLT Agent OS (`.ai.mlt`) | Machine learning tooling and training | `@mlt-director` | `../.ai.mlt/skills/README.md` |
| Social OS (`.ai.soc`) | Social presence and community operations | `@soc-director` | `../.ai.soc/skills/README.md` |
| UI Design OS (`.ai.ui`) | Design tokens, screen SPECs, visual craft | `@ui-director` | `../.ai.ui/skills/README.md` |
| Cross-framework | Spans two or more of the above | `@x-director` | `../.ai/skills/x-director/skill.md` |

When no sibling framework is installed, Flutter Agent OS is **self-sufficient**: it owns session control, feature SPECs, decisions and docs for the Flutter app. See [`COHABITATION.md`](../COHABITATION.md).

---

## Readiness states (do not conflate)

```text
flutter-bootstrap (scaffold)
        ↓
foundation-complete → plan-ready → implementation-ready → release-ready
  @flutter-foundation   @flutter-      @flutter-plan-master   @flutter-release
  status (P0–P6)        foundation     status                 certify
                        certify
```

| State | Certified by | Unlocks |
|-------|--------------|---------|
| *(scaffold only)* | `@flutter-bootstrap init` | `@flutter-stack set`, `@flutter-foundation greenfield`, `@flutter-session` (minimal) |
| **stack-locked** | `@flutter-stack set` (writes `{FLUTTER_STACK_LOCK}`) | `@flutter-foundation greenfield` P2+, `@flutter-scaffold app` |
| **foundation-complete** | `@flutter-foundation status` (P0–P6 gates all pass) | `@flutter-foundation certify`, foundation `continue` |
| **plan-ready** | `@flutter-foundation certify` | `@flutter-plan-master greenfield` / `continue` / `revise` |
| **implementation-ready** | `@flutter-plan-master status` (Approved plan) | `@flutter-implementation plan` / `start` / `continue` |
| **release-ready** | `@flutter-release certify` | `@flutter-release build` / `distribute` |

**F0 early start:** `@flutter-foundation` may authorize an **F0 app skeleton** (project scaffold, flavors, CI, analysis_options) when **plan-ready: yes** and `{FLUTTER_HANDOFF}` records a waiver. That is **not** implementation-ready. `@flutter-implementation` honours named-milestone waivers per its skill.

**Milestone / task ID convention:** milestones are `F{N}` (`F0`, `F1`, …); tasks are globally unique `F{N}-T{k}` (e.g. `F2-T7`). Shorthand `T{k}` is allowed only inside the active iteration block.

---

## Dependency matrix

**Legend:** **Required** = stop and redirect if unmet. **Recommended** = warn, proceed only if the user confirms in the same message. **-** = no gate. **Read-only** modes never mutate artifacts.

| Skill / mode | Depends on | Gate |
|--------------|------------|------|
| **flutter-bootstrap** `init` | Repo is (or will hold) a Dart/Flutter package; **B0** brownfield gate detects existing `.work.flutter/` / `.cursorrules` / stack doc | - (brownfield prompts overwrite-all / overwrite-missing / keep / abort) |
| **flutter-bootstrap** `status` | - | Read-only |
| **flutter-stack** `set` | `{FLUTTER_HANDOFF}` present (SK0 gate) | **Recommended:** `@flutter-bootstrap init` |
| **flutter-stack** `probe` | `{FLUTTER_HANDOFF}` present | - (7 stack dimensions, ≤5 questions/pass) |
| **flutter-stack** `status` / `show` | - | Read-only |
| **flutter-session** `start` / `open` | `{FLUTTER_HANDOFF}` (offer bootstrap if missing) | **Recommended:** `@flutter-bootstrap init` |
| **flutter-session** `close` | Prior `start` or dirty tree | - (may combine with `commit` / `push`; `scoped` limits the commit to bookend files) |
| **flutter-session** `commit` | Dirty in-scope tree (else report "nothing to commit") | - (scope: `.work.flutter/` in adopters, whole tree in the framework repo; includes untracked; no HANDOFF/NEXT writes) |
| **flutter-session** `push` | Remote configured; pending in-scope changes are committed first | - (same scope resolution as `commit`; no close) |
| **flutter-session** `add` | Dirty `.work.flutter/` (else report "nothing to stage") | - (stage-only checkpoint; no commit, no close) |
| **flutter-session** `context` / `status` | - | Read-only |
| **flutter-foundation** `greenfield` | `.cursorrules` + `{FLUTTER_HANDOFF}` (**GF0** gate) | **Recommended:** `@flutter-bootstrap init` |
| **flutter-foundation** `continue` | Prior foundation work started | - |
| **flutter-foundation** `probe` | `{FLUTTER_HANDOFF}` + foundation doc 01 to record into (GF0) | **Recommended:** `@flutter-foundation greenfield` if nothing to probe |
| **flutter-foundation** `certify` | **foundation-complete: yes** (**CF0** gate) | **Required** |
| **flutter-foundation** `status` | - | Read-only |
| **flutter-plan-master** `greenfield` | **plan-ready: yes** (**PG1** gate) | **Required** (see exceptions) |
| **flutter-plan-master** `continue` | **plan-ready: yes**; Draft or partial `*-full-plan.md` | **Required** |
| **flutter-plan-master** `probe` | **plan-ready: yes** (PG1); Draft/partial plan (PG2) | **Required**; run before `integrity` |
| **flutter-plan-master** `revise` | Existing `*-full-plan.md`; plan-ready still valid | **Required** |
| **flutter-plan-master** `integrity` | Target artifacts exist (foundation set, **or** master plan) | Invoked by `@flutter-foundation certify` **or** standalone |
| **flutter-plan-master** `status` / `show` | - | Read-only |
| **flutter-feature-spec** `intake` | None (free-text front door); classifies + routes; writes a SPEC only when class = `local` | - (records to `{FLUTTER_NEXT}` § Intake queue) |
| **flutter-feature-spec** `create` | FEATURE_SPEC_STANDARD readable; **CR0** hard-stops if `<slug>/` exists; warns if `plan-ready: no` | **Required** (collision) + **Recommended** (readiness) |
| **flutter-feature-spec** `review` / `amend` / `status` / `document` | FEATURE_SPEC_STANDARD | - |
| **flutter-feature-spec** `approve` | Runs `review` first; flips Status only on pass; §16 concept registry complete | **Required** |
| **flutter-plan-verify** `foundation` / `master` / `alignment` / `coverage` | Target artifacts exist for the mode | Read-only; orchestrates foundation status + plan-master integrity |
| **flutter-plan-verify** `brownfield` | Code-first repo; formal foundation may never have run | Read-only; framework slot map + substitute paths |
| **flutter-plan-verify** `status` | - | Read-only |
| **flutter-plan-repair** `repair` / `foundation` / `master` / `alignment` | Findings from `@flutter-plan-verify`, or user goal after `-` (**R0** gate) | **Recommended:** run source verify if no report in chat |
| **flutter-plan-repair** `brownfield` | **BF0** = yes; may synthesize `.work.flutter/` without prior greenfield | May write; re-verify with `@flutter-plan-verify brownfield` |
| **flutter-plan-repair** `status` | - | Read-only |
| **flutter-scaffold** `app` | **stack-locked** (`{FLUTTER_STACK_LOCK}` exists) (**SC0** gate) | **Required** |
| **flutter-scaffold** `feature` / `package` / `flavor` / `ci` | `{APP_ROOT}` resolvable with `pubspec.yaml`; stack-locked | **Required** |
| **flutter-scaffold** `status` | - | Read-only |
| **flutter-implementation** `plan` | Approved `*-full-plan.md` **or** HANDOFF `F{N}` waiver (**PI1** gate) | **Required** |
| **flutter-implementation** `start` / `continue` | Valid `{FLUTTER_NEXT}` iteration block; **implementation-ready** or waiver (**ST0** gate); auto-invokes `@flutter-verify uncommitted` at batch end | **Required** |
| **flutter-implementation** `complete` | Active iteration; `@flutter-verify milestone` verdict `pass` or `pass with gaps` | **Required** |
| **flutter-implementation** `task` | Active iteration context; `T{k}` or `F{N}-T{k}` id | - |
| **flutter-implementation** `status` | - | Read-only |
| **flutter-data** `model` / `repository` / `source` / `migration` | Stack-locked; active iteration task **or** explicit user request (**D0** gate) | **Required**; `migration` auto-invokes `@flutter-data verify` |
| **flutter-data** `verify` / `status` | - | Read-only |
| **flutter-platform** `channel` / `permission` / `deeplink` / `config` / `plugin` | `{APP_ROOT}` with the target platform folder present (**PL0** gate) | **Required** |
| **flutter-platform** `status` | - | Read-only |
| **flutter-test** `plan` / `unit` / `widget` / `golden` / `integration` | `{APP_ROOT}` with `test/` resolvable; stack-locked (test doubles follow the stack) | **Recommended** |
| **flutter-test** `run` / `coverage` / `status` | `flutter` on PATH (else report `toolchain unavailable`) | - |
| **flutter-verify** `milestone` | Active milestone in `{FLUTTER_MASTER_PLAN}` **or** `{FLUTTER_NEXT}` § Current iteration (**V0** gate) | **Required** |
| **flutter-verify** `uncommitted` / `last` / `gate` | - | - |
| **flutter-verify** `status` | - | Read-only |
| **flutter-perf** `budget` | `{FLUTTER_STANDARDS_ROOT}` PERFORMANCE standard or foundation doc 03 (**PF0**) | **Recommended** |
| **flutter-perf** `profile` / `size` / `startup` / `trace` | Physical device or emulator reachable; `flutter` on PATH | **Recommended** (report `device unavailable`, never fake numbers) |
| **flutter-perf** `audit` / `status` | - | Read-only (static analysis of widget/build patterns) |
| **flutter-a11y** `audit` / `test` / `status` | `{APP_ROOT}` with widgets to inspect | Read-only for `audit`/`status`; `test` writes a11y test files |
| **flutter-security** `audit` / `deps` / `secrets` / `status` | `{APP_ROOT}` | Read-only; `harden` may write config |
| **flutter-security** `harden` | Findings from `audit` (**SE0** gate) | **Recommended** |
| **flutter-repair** `repair` | Findings from a verifier report, fresh `@flutter-verify` / `@flutter-test run` / `@flutter-a11y audit` / `@flutter-security audit`, or a **custom** brief (**R0** gate) | **Recommended:** run the source verifier if no report is in chat |
| **flutter-repair** `status` | - | Read-only |
| **flutter-doctor** `diagnose` / `env` / `deps` / `build` / `clean` | - | - (toolchain layer; never blocked by planning gates) |
| **flutter-doctor** `status` | - | Read-only |
| **flutter-release** `certify` | All release gates green (**RL0** gate) | **Required** |
| **flutter-release** `build` / `distribute` | **release-ready: yes** | **Required** |
| **flutter-release** `prepare` / `status` | - | `prepare` writes flavor/signing/CI config; `status` read-only |
| **flutter-concept-run** `run` | Applicable trigger (SPEC §16, iteration registry, diff scope) | Per [`concepts/README.md`](../concepts/README.md) |
| **flutter-concept-run** `list` / `status` | - | Read-only |
| **flutter-docs** `create guide` / `create tutorial` / `create reference` | `{FLUTTER_DOCS_ROOT}` exists (created by `@flutter-bootstrap init`) | **Recommended:** `@flutter-bootstrap init` |
| **flutter-docs** `status` | - | Read-only |
| **flutter-deploy-basic** `basic` / `update` / `--update` / `verify` / `uninstall` / `status` | Target dir exists (**I0** gate); source framework root resolvable; `update` / `--update` needs an existing install with `Mode: basic` | - (no-overwrite by default) |
| **flutter-deploy-files** `files` / `update` / `--update` / `verify` / `uninstall` / `status` | Target dir exists (**I0** gate); source framework root resolvable; `update` / `--update` needs an existing install with `Mode: files` | - (no-overwrite by default) |
| **flutter-router** `- <question>` / `help` | - | Read-only. Never writes. |
| **flutter-director** `- <free-text>` | Framework present with valid `skills/README.md`; `{FLUTTER_HANDOFF}` readable | **Recommended:** read `{FLUTTER_HANDOFF}` + `{FLUTTER_NEXT}` for routing context. **Confirm gate** before any skill invoke (skip with `-y`; render-only with `--dry-run`). Non-Flutter requests are channelled to `@x-director` / `@ai-director` after preflight. |
| **flutter-director** `- <free-text> -y` | Same as above | Trust-mode: skips the Confirm gate |
| **flutter-director** `- <free-text> --dry-run` | Same as above | Render routing plan, write nothing, stop |
| **flutter-director** `status` / `help` | - | Read-only |
| **flutter-director** `review-routing` | `{FLUTTER_HANDOFF}` with ≥1 `## Latest action (@flutter-director)` block | Read-only; never edits the bucket table |

---

## Exceptions and waivers

| Situation | Rule |
|-----------|------|
| **flutter-plan-master greenfield** without prior certify | **Forbidden** unless `{FLUTTER_HANDOFF}` already records `Plan-ready: <date>` from a prior certify, **or** the user supplies complete `foundation_docs:` paths and confirms foundation was completed out-of-band in the same message. |
| **flutter-plan-repair brownfield** without plan-ready | **Allowed** — synthesize a Draft master plan + HANDOFF `Brownfield-aligned:` line; **implementation-ready** remains **no** until a formal Approved plan exists. |
| **flutter-plan-verify brownfield** without foundation docs | **Allowed** — score substitutes (`README`, `pubspec.yaml`, `lib/` tree, existing tests); verdict is `aligned-best-effort`, not a formal certify. |
| **flutter-implementation** before **implementation-ready** | **Stop** unless `{FLUTTER_HANDOFF}` explicitly waives a named milestone (typically `F0` app skeleton). |
| **flutter-scaffold app** before foundation | **Allowed only** with `stack-locked` **and** an `F0` waiver; the scaffold must not encode product decisions the foundation has not made. |
| **flutter-doctor** any mode | **Never gated.** Toolchain breakage must always be diagnosable, including from a bare repo. |
| **flutter-data migration** | Does not require the master plan; requires an implementation task or an explicit user request. |
| **flutter-feature-spec** during foundation P4 | Expected; SPECs need not wait for the master plan. |
| **flutter-test** without `flutter` on PATH | Authoring modes still work; execution modes report `toolchain unavailable` and route to `@flutter-doctor env`. **Never** report a test result that was not observed. |

---

## Redirect cheat sheet

| User tried | Blocked because | Run next |
|------------|-----------------|----------|
| `@flutter-plan-master greenfield` | Not plan-ready | `@flutter-foundation status` → `@flutter-foundation certify` |
| `@flutter-foundation certify` | Not foundation-complete | `@flutter-foundation continue` |
| `@flutter-foundation greenfield` | No `.cursorrules` / HANDOFF | `@flutter-bootstrap init` |
| `@flutter-foundation greenfield` P2+ | Stack not locked | `@flutter-stack set` (or `@flutter-stack probe`) |
| `@flutter-scaffold app` | Stack not locked | `@flutter-stack set` |
| `@flutter-implementation start` | No iteration block | `@flutter-implementation plan - F{N}` |
| `@flutter-implementation plan` | No Approved plan | `@flutter-plan-master status` → approve, or record a waiver |
| `@flutter-implementation start` | Not implementation-ready | `@flutter-plan-master status`, or document a HANDOFF waiver |
| `@flutter-verify milestone - F{N}` | Milestone not in plan / NEXT | `@flutter-plan-master show - F{N}` or `@flutter-implementation plan - F{N}` |
| `@flutter-feature-spec create - <slug>` | Folder already exists | `@flutter-feature-spec amend - <slug>` |
| `@flutter-bootstrap init` | Repo already bootstrapped | `@flutter-bootstrap status` (or re-run with overwrite confirmation) |
| `@flutter-verify` / batch sweep **fail** | Findings need remediation | `@flutter-repair repair - from uncommitted` (match the source mode) |
| `@flutter-test run` **fail** | Test failures | `@flutter-repair repair - from test` |
| `@flutter-a11y audit` **fail** | A11y findings | `@flutter-repair repair - from a11y` |
| `@flutter-security audit` **fail** | Security findings | `@flutter-repair repair - from security` (or `@flutter-security harden`) |
| `@flutter-perf profile` over budget | Perf regression | `@flutter-repair repair - from perf` |
| `@flutter-plan-verify` **fail** | Plan gaps or drift | `@flutter-plan-repair repair - from <same mode>` |
| Build/toolchain/pod/gradle error | Not a code defect | `@flutter-doctor diagnose` (then `@flutter-repair` only if it is code) |
| `flutter pub get` conflict | Dependency resolution | `@flutter-doctor deps` |
| Legacy repo, no `.work.flutter/plans/` | No formal planning | `@flutter-plan-verify brownfield` → `@flutter-plan-repair brownfield` |
| Plan gaps surfaced during code work | Wrong layer | `@flutter-plan-repair` / `@flutter-plan-master revise` (not `@flutter-repair`) |
| Scope / NFRs / platforms vague | Understanding gap, not artifact gap | `@flutter-foundation probe` (then `certify`) |
| Plan has vague NFRs / unmapped FRs / ownerless risks | Plan-completeness gap | `@flutter-plan-master probe` → `@flutter-plan-master integrity` |
| Backend / API / database work | Outside this framework | `@ai-director` (via `.ai`) or `@x-director - <request>` |
| Design tokens / visual craft / screen design | Outside this framework | `@ui-director` (via `.ai.ui`) or `@x-director - <request>` |
| "I don't know which skill" | Unsure | `@flutter-director - <describe what you want>` |
| "How do I…?" / "Where is…?" | Process question, not work | `@flutter-router - <question>` |

---

## Canonical command vocabulary

All skills use the same verbs where applicable, so muscle memory stays portable.

| Canonical verb | Meaning | Skills that implement it |
|----------------|---------|--------------------------|
| `status` | Read-only: report current state | every skill |
| `help` | Purpose, modes, invocation examples | flutter-director, flutter-router |
| `init` | One-time setup | flutter-bootstrap |
| `set` / `show` | Record / display a locked decision | flutter-stack; `show` also on flutter-plan-master |
| `probe` | Adaptive gap-driven interrogation loop; scores coverage, asks ≤5 targeted questions, fills registries. Engine: [`probe-protocol.md`](probe-protocol.md) | flutter-foundation, flutter-plan-master, flutter-stack, flutter-feature-spec |
| `greenfield` | First-time creation | flutter-foundation, flutter-plan-master |
| `continue` | Resume in-progress work | flutter-foundation, flutter-plan-master, flutter-implementation |
| `continue` + target | Batch tasks: `- N`, `- until blocked`, `- F{N}-T{a}..T{b}` | flutter-implementation |
| `certify` | Formal sign-off transitioning a readiness state | flutter-foundation (`plan-ready`), flutter-release (`release-ready`) |
| `integrity` | Automated completeness sweep over an artifact set | flutter-plan-master |
| `revise` | Structured edit of an approved artifact | flutter-plan-master |
| `intake` | Classify a free-text request → route; records to `{FLUTTER_NEXT}` § Intake queue | flutter-feature-spec |
| `create` | Make a new artifact | flutter-feature-spec, flutter-docs |
| `amend` | Modify an existing artifact without rewriting history | flutter-feature-spec |
| `review` | Read-only audit of one artifact | flutter-feature-spec |
| `approve` | Flip an artifact's status after a passing review | flutter-feature-spec |
| `document` | Author docs for something that already exists (brownfield) | flutter-feature-spec, flutter-docs |
| `plan` | Prepare the next unit of work | flutter-implementation, flutter-test |
| `start` | Begin a unit of work · open a session (load context, confirm readiness, capture goal) | flutter-implementation, flutter-session |
| `open` / `begin` | Aliases of session `start` | flutter-session |
| `complete` | Mark a unit as done | flutter-implementation |
| `close` | Wrap up + write handoff + draft the commit message; may combine with `commit` / `push` / `scoped` | flutter-session |
| `add` | Stage in-scope changes (incl. untracked) without committing; no close | flutter-session |
| `commit` | Git commit of the resolved scope (`.work.flutter/` in adopters, whole tree in the framework repo); no close, no HANDOFF/NEXT writes | flutter-session |
| `push` | Commit pending in-scope state (if any), then push to the remote; no close | flutter-session |
| `context` | Read-only full context load, uncommitted-aware; no writes | flutter-session |
| `verify` | Audit produced artifacts | flutter-plan-verify (`foundation`/`master`/`alignment`/`coverage`/`brownfield`), flutter-data |
| `milestone` / `uncommitted` / `last` / `gate` | Verification scopes | flutter-verify |
| `audit` | Read-only domain audit with findings table | flutter-perf, flutter-a11y, flutter-security, flutter-plan-verify |
| `repair` | Fix reported findings, then re-verify with the originating verifier | flutter-repair, flutter-plan-repair |
| `diagnose` | Toolchain/environment root-cause analysis | flutter-doctor |
| `brownfield` | Discover/create missing artifacts from an existing repo | flutter-plan-verify, flutter-plan-repair |
| `alignment` / `drift` | NEXT vs master-plan consistency | flutter-plan-verify (read-only), flutter-plan-repair (fix) |
| `run` | Execute (tests / concept prompts) | flutter-test, flutter-concept-run |
| `list` | Enumerate available items | flutter-concept-run |
| `task` | Execute a single task by id | flutter-implementation |
| `update` | Rules-aware merge of existing-but-differing files (never wholesale replace). The deploy skills also accept `--update` as an alias | flutter-deploy-basic, flutter-deploy-files |
| `- <free-text>` | Free-text routing: parse → classify → Confirm gate → execute | flutter-director |
| `- <free-text> -y` | Trust-mode: skip the Confirm gate | flutter-director |
| `- <free-text> --dry-run` | Render the routing plan, write nothing, stop | flutter-director |
| `review-routing` | Read-only aggregate of routing confidence / user corrections | flutter-director |

**Alias policy:** when a verb is renamed, the old name stays as an alias for **at least one minor version**, listed inline in the skill's parse-invocation table and in the matrix above.

---

<a id="blocked-report-shape"></a>

## Blocked report shape (every gate)

When a gate stops execution, the skill emits this exact block so operators always see the same shape:

```markdown
## @<skill> <command> - blocked (prerequisite)

**Required:** <state or upstream step>
**Detected:** <what is actually present>
**Run first:** `<exact command to fix>`
```

Skills must not invent ad-hoc error messages for prerequisite failures. A blocked report still closes per the [Operator handoff contract](#operator-handoff-contract) — usually Form B, with `**Next step:**` naming the same command as **Run first**.

---

<a id="self-verify-auto-invoke"></a>

## Self-verify auto-invoke

Some mutating skills must invoke a verifier on the artifact they just produced **before** declaring the mode complete. This is in addition to per-step mechanical gates, and it prevents "the issue only surfaced after the user asked again".

| Skill / mode | Auto-invokes | When | Skip allowed? |
|--------------|--------------|------|---------------|
| `flutter-implementation` `continue` (any `-` target) | `@flutter-verify uncommitted` over the cumulative batch diff | After the per-task loop ends, before the batch summary | Only when zero files changed |
| `flutter-implementation` `complete` | `@flutter-verify milestone` | CO2, before final gates | No |
| `flutter-scaffold` any writing mode | `@flutter-verify gate` (format + analyze + test on the new tree) | Before declaring the scaffold complete | Only when `flutter` is unavailable — record the reason |
| `flutter-data` `migration` | `@flutter-data verify` (idempotency + round-trip) on the new script | Before declaring create complete | Only when the store is unreachable — record the reason |
| `flutter-feature-spec` `approve` | `@flutter-feature-spec review` | Before flipping `Status: Approved` | No |
| `flutter-release` `certify` | `@flutter-verify milestone` + `@flutter-security audit` + `@flutter-a11y audit` | Before flipping `release-ready` | No |
| `flutter-repair` any repair | The **originating** verifier (per its R4 re-verify map) | After the last fix, before claiming `repaired` | No |

**Honesty:** auto-invoked verifiers run with the **same evidence rules** as standalone invocations. A `pass` claim without an exit code, file path, or quoted output is treated as `unverified`.

**Post-fix re-gate** (separate from auto-invoke): when an agent applies a fix in response to **any** reported issue, the affected task's gate **must** be re-run before the repair is claimed. See `flutter-implementation` § Post-fix re-gate.

---

## Maintenance

When adding or changing a skill:

1. Update this matrix and, if a new verb appears, the canonical vocabulary above.
2. Add or update § **Prerequisite gate** in that skill's `skill.md` using the **blocked report shape**.
3. Register the skill in [`skills/README.md`](README.md), [`flutter-director/reference.md`](flutter-director/reference.md) § Bucket registry, and [`flutter-router/reference.md`](flutter-router/reference.md) § Routing table.
4. Add a row to the redirect cheat sheet if operators will commonly hit the new gate.
5. Prefer **reusing an existing canonical verb** over inventing one. If a new verb is unavoidable, document why.
6. Run `bash scripts/framework-verify.sh` — registration and prose-drift are machine-checked.
