# Agent skills — Flutter Agent OS

Portable, tool-agnostic workflows. Each skill is a folder with `skill.md` (+ optional `reference.md`). **Repo doc map:** [`README.md`](../README.md).

**Identifiers:** folder name = stable skill id = YAML `name:` in `skill.md` = `@` handle (e.g. `@flutter-implementation`).

**Invocation punctuation:** ASCII hyphen `-` between verb and argument (`@flutter-implementation plan - F1`). Not em dash `—`. See [`SKILL_DEPENDENCIES.md`](SKILL_DEPENDENCIES.md).

**Work tree paths:** `{FLUTTER_WORK_ROOT}` = `.work.flutter/` at repo root — never `context/` or `plans/` without the prefix. See [`SKILL_DEPENDENCIES.md` § Work tree path resolution](SKILL_DEPENDENCIES.md#work-tree-path-resolution-mandatory).

---

## Naming protocol

Use for **new** skills and for any **rename** (update `.cursorrules`, this README, `SKILL_DEPENDENCIES.md`, both router tables, HANDOFF and NEXT in one pass).

| Rule | Requirement |
|------|-------------|
| **Prefix** | Every skill starts with `flutter-`. No exceptions — this is how the framework avoids colliding with Agent OS (`.ai`) and UI Design OS (`.ai.ui`). |
| **Shape** | `flutter-{role}` or `flutter-{domain}-{role}` in **kebab-case** (lowercase ASCII, hyphens). Prefer two segments; use three only to remove ambiguity. |
| **role** | What the skill does: `foundation`, `implementation`, `verify`, `repair`, `director`, `doctor`, … |
| **Stable id** | Folder name = `name:` in frontmatter = `@` handle = row key in this table and in `.cursorrules` § Skills. |
| **Avoid** | File extensions in the id, vague names (`helper`, `utils`), vendor prefixes (`cursor-`), and duplicating an `.ai` or `.ai.ui` skill id. |
| **Files** | `skill.md` (required) · `reference.md` (optional, for tables and worked examples that would bloat the protocol) |

**Context budget:** `skill.md` soft limit **24 KB** (warn), hard limit **42 KB** (fail). Overflow goes to `reference.md`. Machine-checked by `scripts/framework-verify.sh`.

---

## Registered skills

### Orchestration

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-director | `flutter-director/` | **Top-level orchestrator:** free-text request → optimal skill chain; Confirm gate; new-skill gap detection; cross-framework redirect |
| flutter-router | `flutter-router/` | **Read-only signpost:** process questions → the exact skill, standard or guide. Never writes |

### Setup and planning

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-bootstrap | `flutter-bootstrap/` | Scaffold `.work.flutter/`, `.cursorrules`, `DOCS_FLUTTER_STACK.md`, `analysis_options.yaml` from templates |
| flutter-stack | `flutter-stack/` | Choose and **lock** the technology stack (state, navigation, DI, data, serialization, testing); writes `STACK.md` |
| flutter-foundation | `flutter-foundation/` | **Foundation planner:** P0–P6 gates, foundation docs 01–05, ADRs, registries; `probe`; certifies **plan-ready** |
| flutter-plan-master | `flutter-plan-master/` | Master implementation plan: milestones `F{N}`, tasks, traceability, `probe`, `integrity`; certifies **implementation-ready** |
| flutter-feature-spec | `flutter-feature-spec/` | Author, intake, review, amend, approve and document feature SPECs per FEATURE_SPEC_STANDARD |
| flutter-plan-verify | `flutter-plan-verify/` | Read-only plan audits: `foundation`, `master`, `alignment`, `coverage`, `brownfield` |
| flutter-plan-repair | `flutter-plan-repair/` | Fix plan gaps; brownfield synthesis from an existing codebase; mandatory re-verify |

### Implementation

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-scaffold | `flutter-scaffold/` | Generate skeletons: app, feature module, package, flavor, CI workflow — per the locked stack and DIRECTORY_MAP |
| flutter-implementation | `flutter-implementation/` | **Iteration execution:** validate the `NEXT_FLUTTER.md` iteration block, per-task gates, batch sweep, completion |
| flutter-data | `flutter-data/` | Data layer: models and serialization, repositories, remote/local sources, local-store migrations |
| flutter-platform | `flutter-platform/` | Platform integration: method/event channels, permissions, deep links, native config, plugin authoring |
| flutter-release | `flutter-release/` | Flavors, signing, obfuscation, build artifacts, CI/CD, store metadata; certifies **release-ready** |

### Verification

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-test | `flutter-test/` | Test strategy and authoring: unit, widget, golden, integration; execution and coverage enforcement |
| flutter-verify | `flutter-verify/` | **Code verification:** `milestone`, `uncommitted`, `last`, `gate` — the 15-dimension audit and the mechanical gate |
| flutter-perf | `flutter-perf/` | Performance budgets, static build-method audit, profiling, app size, startup trace |
| flutter-a11y | `flutter-a11y/` | Accessibility audit and a11y test authoring against the WCAG-AA baseline |
| flutter-security | `flutter-security/` | Security and privacy audit: secrets, storage, transport, permissions, dependencies; `harden` |

### Repair

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-repair | `flutter-repair/` | Remediate findings from any verifier; mandatory re-verify with the originating verifier |
| flutter-doctor | `flutter-doctor/` | **Toolchain layer:** diagnose environment, dependency, build, Gradle/CocoaPods and codegen failures. Never gated |

### Support

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-session | `flutter-session/` | Session `start`/`close`, HANDOFF and NEXT maintenance, read-only `context`/`status`; git `add` / `commit` / `push` (with `scoped` option) — `.work.flutter/` scope in adopter repos, whole tree in the framework repo; commit message always shown |
| flutter-concept-run | `flutter-concept-run/` | Run FLS-01…FLS-13 concept prompts; attach output to the iteration, SPEC or PR |
| flutter-docs | `flutter-docs/` | Create guides, tutorials and reference docs under `.work.flutter/docs/` |

### Deploy

| Skill id | Folder | Role |
|----------|--------|------|
| flutter-deploy-basic | `flutter-deploy-basic/` | Install the framework into another repository, **thin** (`basic`): pointer + `.cursorrules` registration; `update` / `--update`, `verify`, `uninstall`, `status` |
| flutter-deploy-files | `flutter-deploy-files/` | Install the framework into another repository, **fat** (`files`): self-contained copy; `update` / `--update`, `verify`, `uninstall`, `status` |
| flutter-deploy-repo | `flutter-deploy-repo/` | Install the framework into another repository, **pinned** (`repo`): clone/archive/submodule; `update` / `--update`, `verify`, `uninstall`, `status` |

**Typical flow (greenfield):** `@flutter-bootstrap init` → `@flutter-stack set` → `@flutter-foundation greenfield` → `certify` → `@flutter-plan-master greenfield` → `@flutter-plan-master status` (implementation-ready) → `@flutter-scaffold app` → `@flutter-implementation plan - F1` → `start` / `continue` / `complete` → `@flutter-release certify`.

**Canonical verb vocabulary:** see [SKILL_DEPENDENCIES.md § Canonical command vocabulary](SKILL_DEPENDENCIES.md#canonical-command-vocabulary). Every skill uses `status` for read-only state, `init` for one-time setup, `probe` for interrogation, `repair` for remediation — no skill invents bespoke verbs.

**Skill prerequisites (gates):** [SKILL_DEPENDENCIES.md](SKILL_DEPENDENCIES.md) — which modes **stop** when an upstream step was skipped.

**Orientation:** `@flutter-router - <question>` when lost; `@flutter-session status` for a repo snapshot; `@flutter-director - <what you want>` when you do not know the skill.

**Do not** ask `@flutter-foundation` whether you are implementation-ready — that is `@flutter-plan-master status`.

Registered in the adopter `.cursorrules` snippet § Skills (`templates/cursorrules.flutter.snippet.template`).

---

## Shared engine docs (not skills)

These are single-source-of-truth fragments that skills **link** rather than restate. They are files, not skill folders, so they are not counted in the registry above.

| File | Owns |
|------|------|
| [`SKILL_DEPENDENCIES.md`](SKILL_DEPENDENCIES.md) | Readiness states, gate matrix, blocked-report shape, path resolution, canonical verbs, self-verify auto-invoke, operator handoff + document clarity contracts |
| [`probe-protocol.md`](probe-protocol.md) | The adaptive `probe` loop, coverage scoring, question quality bar, and the **challenge pass** (operator grilling) |

---

## Further reading

- **Operator decision tree (read when lost):** [`START_HERE.md`](../START_HERE.md)
- **Archetypes and skill chains:** [`APPROACH.md`](../APPROACH.md)
- **Concept pack and triggers:** [`concepts/README.md`](../concepts/README.md)
- **Coexistence with `.ai` / `.ai.ui`:** [`COHABITATION.md`](../COHABITATION.md)
