---
name: flutter-deploy-files
description: >-
  Install, update and verify the Flutter Agent OS framework itself inside a
  target repository using the fat (files) install: a self-contained copy of the
  framework under .ai.flutter/ so it works without the source location. Accepts
  the mode "update" or the alias "--update" for version updates that preserve
  local project artifacts. Distinct from flutter-release, which ships the app;
  this ships the framework. Use for install the framework, add Flutter Agent OS
  to this repo, or update the framework.
---

# flutter-deploy-files

Installs **the framework**, not the app. `@flutter-release` ships your Flutter application; `@flutter-deploy-files` puts this Agent OS into a repository so the other skills can run there. This skill owns the **files (fat)** install only: a self-contained copy of the framework under `<target>/.ai.flutter/`, independent of where the source lives.

**Sibling skills:** thin installs are `@flutter-deploy-basic`; version-pinned clone or submodule installs are `@flutter-deploy-repo`. Pick the mode first, then the skill that owns it.

**Never gated.** Installation is the step that creates the state everything else requires.

**Pairs with:** `flutter-bootstrap` (runs after install to scaffold the project work tree — install and bootstrap are different steps and both are required).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never overwrite project artifacts.** `.work.flutter/`, project standards, foundation docs, SPECs and plans belong to the target repo. Framework files are replaceable; project files are not.
2. **Never install over an existing install without reading its version first.** That is an `update`, and it has different rules.
3. **Verify after installing.** An install that was not verified is a claim.
4. **Record the installed version and mode.** Without this, `update` cannot reason about what changed.
5. **Respect the target's conventions.** Do not reformat, relicense or restructure the target repository.
6. **Merge, never clobber, `.cursorrules`.** Targets commonly already have one, and it may register other frameworks.
7. **State the license position.** The framework is MIT; installing it into a proprietary repo must be an informed act.

---

## Modes

| Mode | Action |
|------|--------|
| `files - <target>` | **Fat install (default).** Copy the full framework into the target so it is self-contained |
| `update - <target>` | Update an existing files install, preserving all project artifacts. `--update` is accepted as an alias — `@flutter-deploy-files update - <target>` and `@flutter-deploy-files --update - <target>` are identical |
| `verify - <target>` | Read-only: is the files install complete, consistent and usable |
| `uninstall - <target>` | Remove the copied framework directory; **never** removes project artifacts |
| `status` | Read-only: installed mode, version, drift |

### Invocation parsing

Arguments are **order-independent**. One argument is the target repository path — quoted or not, absolute or relative, in any position. The mode word works bare or `--`-prefixed, in any position: `update` ≡ `--update`, `verify` ≡ `--verify`, `status` ≡ `--status`, `uninstall` ≡ `--uninstall`. No mode word means install. These two invocations are the same action:

    @flutter-deploy-files "/mnt/work/Projects/system-erp" update
    @flutter-deploy-files /mnt/work/Projects/system-erp --update

An argument that is neither a path nor a known mode → stop and ask. Never guess. The scripts parse the same way, so `bash scripts/deploy-files.sh <target> update` and `bash scripts/deploy-files.sh --target <target> --update` are also identical.

### Choosing the files mode

| Situation | Mode | Why |
|-----------|------|-----|
| CI, containers, or contributors who will not have the source | `files` | Self-contained and reproducible |
| Framework lives beside the repo on this machine; one developer or a shared checkout | `basic` → `@flutter-deploy-basic` | No duplication; updates are instant |
| The target wants the framework pinned in its own history | `repo` → `@flutter-deploy-repo` | Version-pinned, reviewable |
| Already installed | `update` | Preserves project artifacts |

---

## files protocol

Copy the framework into `<target>/.ai.flutter/` (or a confirmed alternative path).

**Copied:** `skills/`, `standards/`, `concepts/`, `templates/`, `scripts/`, `hooks/`, `stacks/`, `resources/`, `docs/`, `.quick/`, entry points, `LICENSE`.

**Never copied:** the framework's own `.git`, its `.work.flutter/`, `plans/`, repo meta (`.github/`, `.vscode/`, the framework's own `.cursorrules` and `.gitignore`), scratch and temp directories, anything in the framework's `.gitignore`.

Then write the pointer with `Mode: files`, register in `.cursorrules`, ensure scripts are executable, and verify.

**Before copying, check for collisions.** Any existing file at a destination path is reported and left alone unless the operator confirms replacement, file by file.

---

## update protocol (mode `update` / alias `--update`)

The mode with the highest risk of destroying work, so it is the most constrained. Both spellings are accepted; `--update` is a synonym, not a different mode.

### U1 — Establish both versions

Read the installed pointer for mode and version; read the source version. Same version → report "already current" and stop unless drift is found. A pointer whose `Mode:` is not `files` → stop: the target was installed by `@flutter-deploy-basic` or `@flutter-deploy-repo`, and updating it here would apply the wrong protocol.

### U2 — Classify every path

| Class | Examples | Update action |
|-------|----------|---------------|
| **Framework** | `skills/`, `standards/` templates, `scripts/`, `concepts/`, `stacks/` | Replace |
| **Project** | `.work.flutter/**`, project standards under the work tree, foundation docs, SPECs, plans, `HANDOFF_FLUTTER.md`, `NEXT_FLUTTER.md` | **Never touch** |
| **Merged** | `.cursorrules`, `analysis_options.yaml`, CI workflows | Merge with report |
| **Locally modified framework file** | A skill the target edited | **Stop and ask** — never silently discard local work |

### U3 — Detect local modification

Compare installed framework files (under `<target>/.ai.flutter/`) against the source's corresponding version. Any file that differs from both the old and the new source version was locally modified. List each one and ask before replacing; offer to preserve it as `<file>.local` alongside the update.

### U4 — Apply, then verify

Replace framework files, merge merged files, update the pointer's `Version:` and `Installed:` lines, run `verify`, and report a changelog:

```markdown
## @flutter-deploy-files update

**Version:** <old> → <new> · **Mode:** files

| Change | Count | Detail |
|--------|-------|--------|
| Skills updated | 4 | flutter-verify, flutter-test, … |
| Skills added | 1 | flutter-perf |
| Standards updated | 2 | … |
| Merged | 1 | `.cursorrules` — added 1 section |
| Preserved (local edits) | 1 | `skills/flutter-data/skill.md` → kept, `.new` written beside it |
| Project artifacts touched | **0** | |

**Breaking changes:** <renamed skills, changed verbs, moved paths — with the migration action>
**Verify:** PASS
**Run next:** `@flutter-session status`
```

Renamed skills or changed verbs are breaking and must be called out explicitly, with the rename mapping — stale `@` handles in a target's HANDOFF and NEXT will otherwise fail silently.

---

## verify protocol

Mechanical backbone: `bash scripts/deploy-verify.sh <target>` (equivalently `bash scripts/deploy-files.sh <target> verify`, run from the framework source) implements the checks below, names every failure with its fix, and reports tokens owned by later steps as **pending** rather than failures. Quote its verdict; the skill adds the judgement the script cannot have (local modifications, update-only intactness).

| # | Check | Fails when |
|---|-------|-----------|
| 1 | `<target>/.ai.flutter/` exists with `skills/`, `standards/`, `scripts/`, `concepts/`, `templates/` | any missing |
| 2 | Every skill in `<target>/.ai.flutter/skills/README.md` has a `skill.md` | any missing |
| 3 | Scripts under the copy are executable | not `+x` |
| 4 | `.cursorrules` registers the framework | missing section |
| 5 | No skill id collides with another installed framework | collision |
| 6 | Version recorded in the pointer and matches the source | mismatch |
| 7 | `scripts/framework-verify.sh` passes **inside the copy** | non-zero exit |
| 8 | Target `.gitignore` excludes framework scratch paths (pending until `@flutter-bootstrap init`) | not excluded after bootstrap |
| 9 | `.work.flutter/` intact (update only) | any modified |
| 10 | Frameworks registry cells: a `REPLACE:AI*_PATH` cell whose sister is installed is flagged for re-run; a filled cell that no longer resolves to a framework is named | installable sister left unfilled; dangling filled cell |
| 10 | No deploy-owned `REPLACE:` token survives in `.cursorrules` (`FLUTTER_FRAMEWORK_PATH`, `FLUTTER_SNIPPET_BLOCK`, `FLUTTER_PROJECT_NAME`); tokens owned by later steps are named as pending with their owner | any deploy-owned token |
| 11 | The `Framework:` path in the Flutter block resolves and matches the pointer's `Source:` | dangling or mismatch |

Report per check with the evidence, then a single verdict. Failures name the fix command.

---

## uninstall protocol

1. Confirm the pointer's `Mode:` is `files` — never uninstall another mode's install from this skill.
2. Remove the copied framework directory `<target>/.ai.flutter/` and the pointer file.
3. Remove only the Flutter Agent OS section from `.cursorrules` (between the `FLUTTER_AGENT_OS_BEGIN` / `FLUTTER_AGENT_OS_END` markers); leave every other framework's section untouched.
4. Report what was removed. **Never** delete `.work.flutter/`, project standards, SPECs, plans or any app code — an uninstall removes the framework copy, not the project's memory.

---

## Cohabitation

When `.ai` or `.ai.ui` is already installed:

- Skill ids never collide — every skill here is `flutter-` prefixed.
- Work trees never collide — `.work.flutter/` versus `.work/` and `.work.ui/`.
- `.cursorrules` gets an additive section; other frameworks' sections are preserved verbatim.
- Cross-framework routing is described in [`COHABITATION.md`](../../COHABITATION.md).

If a collision is detected anyway, **stop**. Do not rename another framework's skills to make room.

---

## Anti-patterns

- Overwriting `.cursorrules` instead of merging.
- Touching `.work.flutter/` during an update.
- Replacing a locally modified skill without asking.
- Installing over an existing install instead of updating.
- Copying the framework's `.git` into the target.
- Running the `basic` or `repo` update protocol against a `files` pointer (or vice versa).
- Reporting success without running `verify`.
- Renaming another framework's skills to resolve a collision.
- Silent breaking changes to skill names or verbs.
- Installing without stating the license.
- Stopping at install and never mentioning that `@flutter-bootstrap init` is still required.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Target root resolved and confirmed | pass/fail | path |
| 2 | Existing install detected before writing | pass/fail | |
| 3 | Mode chosen deliberately; tradeoff stated | pass/fail | |
| 4 | Collisions reported file by file before copying | pass/fail | list |
| 5 | `.cursorrules` merged, not overwritten | pass/fail | diff |
| 6 | No project artifact modified | pass/fail | git status |
| 7 | Locally modified framework files surfaced, not discarded | pass/skip | list |
| 8 | Version and mode recorded in the pointer | pass/fail | |
| 9 | `verify` run inside the copy via `deploy-verify.sh`; all checks reported, pending tokens named | pass/fail | verdict |
| 10 | Breaking changes called out with migrations | pass/skip | |
| 11 | License position stated | pass/fail | |
| 12 | Next step (`@flutter-bootstrap init`) given | pass/fail | |
