# Standards — Flutter Agent OS

Binding rules for Flutter code, plans and process. Skills cite these; they do not restate them.

**Two lifecycles.** Framework standards live here and are versioned with the framework. Some are **templates**: `@flutter-foundation` P3 copies them into `{FLUTTER_STANDARDS_ROOT}` (`.work.flutter/standards/`), fills every `REPLACE:` token from the foundation docs and `STACK.md`, and from that moment the **project copy is binding**. The framework copy is never edited per project.

**Zero unreplaced tokens** in a project copy is a P3 gate and a `@flutter-plan-verify foundation` check.

---

## Registry

| Standard | Templated | Binding on | Primary consumers |
|----------|-----------|-----------|-------------------|
| [`FLUTTER_CONVENTIONS`](20260801-FLUTTER_CONVENTIONS.md) | yes | All Dart code | implementation, verify, repair |
| [`DIRECTORY_MAP`](20260801-DIRECTORY_MAP.md) | yes | File placement | scaffold, implementation, verify |
| [`ARCHITECTURE_STANDARD`](20260801-ARCHITECTURE_STANDARD.md) | yes | Layering, errors, DI | foundation, implementation, verify |
| [`STATE_MANAGEMENT_STANDARD`](20260801-STATE_MANAGEMENT_STANDARD.md) | yes | ViewModels and state | implementation, verify |
| [`NAVIGATION_STANDARD`](20260801-NAVIGATION_STANDARD.md) | yes | Routes, guards, links | implementation, platform |
| [`DATA_LAYER_STANDARD`](20260801-DATA_LAYER_STANDARD.md) | yes | Models, repos, storage | data, verify |
| [`THEMING_STANDARD`](20260801-THEMING_STANDARD.md) | yes | Theme and tokens | implementation, a11y |
| [`UI_CRAFT_STANDARD`](20260802-UI_CRAFT_STANDARD.md) | yes | Visible quality of shipped UI | implementation, verify, scaffold, feature-spec |
| [`L10N_STANDARD`](20260801-L10N_STANDARD.md) | yes | Strings, formats, RTL | implementation, a11y |
| [`TESTING_STANDARD`](20260801-TESTING_STANDARD.md) | yes | Test strategy | test, verify |
| [`QUALITY_GATES`](20260801-QUALITY_GATES.md) | yes | What "done" means | verify, implementation, release |
| [`PERFORMANCE_STANDARD`](20260801-PERFORMANCE_STANDARD.md) | yes | Budgets and profiling | perf, verify, release |
| [`ACCESSIBILITY_STANDARD`](20260801-ACCESSIBILITY_STANDARD.md) | no | WCAG-AA baseline | a11y, verify |
| [`SECURITY_PRIVACY_STANDARD`](20260801-SECURITY_PRIVACY_STANDARD.md) | yes | Secrets, storage, transport | security, data, release |
| [`OBSERVABILITY_STANDARD`](20260801-OBSERVABILITY_STANDARD.md) | yes | Logs, crashes, analytics | implementation, security |
| [`RELEASE_STANDARD`](20260801-RELEASE_STANDARD.md) | yes | Flavors, signing, CI/CD | release, deploy |
| [`PACKAGE_LICENSE_STANDARD`](20260801-PACKAGE_LICENSE_STANDARD.md) | no | Dependency admission | stack, security |
| [`FEATURE_SPEC_STANDARD`](20260801-FEATURE_SPEC_STANDARD.md) | yes | SPEC shape | feature-spec, plan-verify |
| [`MASTER_PLAN_STANDARD`](20260801-MASTER_PLAN_STANDARD.md) | no | Plan shape | plan-master, plan-verify |
| [`DOCUMENTATION_STANDARD`](20260801-DOCUMENTATION_STANDARD.md) | no | Docs accuracy | docs |
| [`GIT_WORKFLOW_STANDARD`](20260801-GIT_WORKFLOW_STANDARD.md) | yes | Branches, commits, PRs | session, verify, release |
| [`DESKTOP_STANDARD`](20261123-DESKTOP_STANDARD.md) | no | Windows/macOS/Linux: windows, input, menus, layout, files, packaging | scaffold desktop, platform, release, verify |
| [`CICD_CONVENTIONS`](20261123-CICD_CONVENTIONS.md) | no | Adopter CI ≡ local gate; thin/fat script paths; no secrets in YAML | scaffold ci, release, verify |
| [`PROTECTED_SURFACES.json`](PROTECTED_SURFACES.json) | yes | Files needing approval | every writing skill |

---

## Precedence

When two sources disagree, higher wins:

1. **Human instruction in the current message** — overrides everything, for that message only, and is recorded in HANDOFF.
2. **`.cursorrules`** — the repo's operating contract.
3. **Project standards** in `{FLUTTER_STANDARDS_ROOT}`.
4. **Approved SPEC** for its own feature.
5. **Framework standards** (this directory).
6. **Ecosystem convention** (Effective Dart, Material guidelines).

A conflict between levels 2–5 is a **finding**, not a judgement call: report it and route to `@flutter-plan-repair`. Silently picking one is how two sources of truth become permanent.

---

## Waivers

A standard can be waived, never ignored. A waiver requires: the rule, the scope (files or feature), the reason, the risk accepted, the expiry or removal condition, and the approver. Record it in `{FLUTTER_WORK_ROOT}/decisions/` as an ADR and reference it from the code with a single comment naming the ADR. `@flutter-verify` treats an unwaived violation as a finding and a waived one as recorded debt.

---

## Editing

Framework standards change through `CONTRIBUTING.md` (new date-stamped file; the old one stays for historical plans). Project copies change through `@flutter-plan-repair`, which re-runs `@flutter-plan-verify foundation` afterwards.
