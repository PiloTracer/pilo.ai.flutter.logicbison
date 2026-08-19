---
name: flutter-deploy-repo
description: >-
  Install, update and verify the Flutter Agent OS framework itself inside a
  target repository as a version-pinned clone, archive or submodule under
  .ai.flutter/ so the exact framework revision is recorded in the target's own
  history. Accepts the mode "update" or the alias "--update" for version updates
  that preserve local project artifacts. Distinct from flutter-release, which
  ships the app; this ships the framework. Use for install the framework, add
  Flutter Agent OS to this repo, or update the framework.
---

# flutter-deploy-repo

Installs **the framework**, not the app. `@flutter-release` ships your Flutter application; `@flutter-deploy-repo` puts this Agent OS into a repository so the other skills can run there. This skill owns the **repo** install only: the framework is cloned, unpacked or added as a submodule into `<target>/.ai.flutter/`, so the exact revision is pinned in the target's own history and reviewable.

**Sibling skills:** thin installs are `@flutter-deploy-basic`; self-contained fat installs are `@flutter-deploy-files`. Pick the mode first, then the skill that owns it.

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
| `repo - <target>` | **Pinned install (default).** Clone, unpack or submodule the framework as a directory inside the target |
| `update - <target>` | Update an existing repo install to a new revision, preserving all project artifacts. `--update` is accepted as an alias — `@flutter-deploy-repo update - <target>` and `@flutter-deploy-repo --update - <target>` are identical |
| `verify - <target>` | Read-only: is the repo install complete, consistent and usable |
| `uninstall - <target>` | Remove the framework directory and any submodule registration; **never** removes project artifacts |
| `status` | Read-only: installed mode, pinned revision, drift |

### Invocation parsing

Arguments are **order-independent**. One argument is the target repository path — quoted or not, absolute or relative, in any position. The mode word works bare or `--`-prefixed, in any position: `update` ≡ `--update`, `verify` ≡ `--verify`, `status` ≡ `--status`, `uninstall` ≡ `--uninstall`. No mode word means install. These two invocations are the same action:

    @flutter-deploy-repo "/mnt/work/Projects/system-erp" update
    @flutter-deploy-repo /mnt/work/Projects/system-erp --update

An argument that is neither a path nor a known mode → stop and ask. Never guess. The scripts parse the same way, so `bash scripts/deploy-repo.sh <target> update` and `bash scripts/deploy-repo.sh --target <target> --update` are also identical.

### Choosing the repo mode

| Situation | Mode | Why |
|-----------|------|-----|
| The target wants the framework pinned in its own history | `repo` | Version-pinned, reviewable |
| Framework lives beside the repo on this machine; one developer or a shared checkout | `basic` → `@flutter-deploy-basic` | No duplication; updates are instant |
| CI, containers, or contributors who will not have the source | `files` → `@flutter-deploy-files` | Self-contained and reproducible |
| Already installed | `update` | Preserves project artifacts |

---

## repo protocol

Clone or unpack the framework into `<target>/.ai.flutter/` (or a confirmed alternative path).

**Source options:** a git URL (`--from <url>`), a local clone of this framework, or an archive. A plain clone is detached with `.git` removed so the target owns the files; `--submodule` records the framework as a submodule instead, so collaborators fetch it with `git submodule update --init`. `--ref <git-ref>` pins a specific revision.

**Copied:** `skills/`, `standards/`, `concepts/`, `templates/`, `scripts/`, `hooks/`, `stacks/`, `resources/`, `docs/`, `.quick/`, entry points, `LICENSE`.

**Never carried:** the framework's own `.git` (removed after a clone), `plans/`, repo meta (`.github/`, `.vscode/`, the framework's own `.cursorrules` and `.gitignore`), its `.work.flutter/`, scratch and temp directories, anything in the framework's `.gitignore`. A `--submodule` install is the exception: exclusions cannot be applied without dirtying the submodule, so it carries the full tracked tree. Otherwise the clone and the fat install exclude the same paths, so a target that switches modes does not silently gain or lose files.

Then write the pointer with `Mode: repo` and the pinned revision, register in `.cursorrules`, and verify.

**Before writing, check for collisions.** If the destination path already exists, the install refuses and points at `update` — it never merges into an existing tree.

---

## update protocol (mode `update` / alias `--update`)

The mode with the highest risk of destroying work, so it is the most constrained. Both spellings are accepted; `--update` is a synonym, not a different mode.

### U1 — Establish both versions

Read the installed pointer for mode and pinned revision; read the source revision (or the target revision the operator wants). Same revision → report "already current" and stop unless drift is found. A pointer whose `Mode:` is not `repo` → stop: the target was installed by `@flutter-deploy-basic` or `@flutter-deploy-files`, and updating it here would apply the wrong protocol.

### U2 — Classify every path

| Class | Examples | Update action |
|-------|----------|---------------|
| **Framework** | `skills/`, `standards/` templates, `scripts/`, `concepts/`, `stacks/` | Replace |
| **Project** | `.work.flutter/**`, project standards under the work tree, foundation docs, SPECs, plans, `HANDOFF_FLUTTER.md`, `NEXT_FLUTTER.md` | **Never touch** |
| **Merged** | `.cursorrules`, `analysis_options.yaml`, CI workflows | Merge with report |
| **Locally modified framework file** | A skill the target edited | **Stop and ask** — never silently discard local work |

### U3 — Detect local modification

Compare installed framework files (under `<target>/.ai.flutter/`) against the new revision's corresponding files. Any file that differs from both the old and the new revision was locally modified. List each one and ask before replacing; offer to preserve it as `<file>.local` alongside the update. For a submodule install, move the submodule to the new revision and report the diff.

### U4 — Apply, then verify

Move the pinned revision, replace framework files, merge merged files, update the pointer's `Version:` and `Installed:` lines, run `verify`, and report a changelog:

```markdown
## @flutter-deploy-repo update

**Version:** <old> → <new> · **Mode:** repo

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

Mechanical backbone: `bash scripts/deploy-verify.sh <target>` (equivalently `bash scripts/deploy-repo.sh <target> verify`, run from the framework source) implements the checks below, names every failure with its fix, and reports tokens owned by later steps as **pending** rather than failures. Quote its verdict; the skill adds the judgement the script cannot have (local modifications, update-only intactness).

| # | Check | Fails when |
|---|-------|-----------|
| 1 | `<target>/.ai.flutter/` exists with `skills/`, `standards/`, `scripts/`, `concepts/`, `templates/` | any missing |
| 2 | Every skill in `<target>/.ai.flutter/skills/README.md` has a `skill.md` | any missing |
| 3 | Pinned revision recorded in the pointer and present in the tree | mismatch or absent |
| 4 | Submodule registration matches (submodule installs) | `.gitmodules` points elsewhere |
| 5 | `.cursorrules` registers the framework | missing section |
| 6 | No skill id collides with another installed framework | collision |
| 7 | `scripts/framework-verify.sh` passes **inside the copy** | non-zero exit |
| 8 | Target `.gitignore` excludes framework scratch paths (pending until `@flutter-bootstrap init`) | not excluded after bootstrap |
| 9 | `.work.flutter/` intact (update only) | any modified |
| 10 | Frameworks registry cells: a `REPLACE:AI*_PATH` cell whose sister is installed is flagged for re-run; a filled cell that no longer resolves to a framework is named | installable sister left unfilled; dangling filled cell |
| 10 | No deploy-owned `REPLACE:` token survives in `.cursorrules` (`FLUTTER_FRAMEWORK_PATH`, `FLUTTER_SNIPPET_BLOCK`, `FLUTTER_PROJECT_NAME`); tokens owned by later steps are named as pending with their owner | any deploy-owned token |
| 11 | The `Framework:` path in the Flutter block resolves and matches the pointer's `Source:` | dangling or mismatch |

Report per check with the evidence, then a single verdict. Failures name the fix command.

---

## uninstall protocol

1. Confirm the pointer's `Mode:` is `repo` — never uninstall another mode's install from this skill.
2. Remove the framework directory `<target>/.ai.flutter/`; for a submodule install, also remove the submodule registration (`.gitmodules` entry and the staged gitlink).
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
- Leaving the framework's `.git` inside the target after a clone.
- Carrying `plans/` or the framework's `.work.flutter/` into the target (the clone bundle must match the fat install's exclusions).
- Running the `basic` or `files` update protocol against a `repo` pointer (or vice versa).
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
| 4 | Source (URL / local / archive) and ref resolved | pass/fail | |
| 5 | Collisions reported file by file before writing | pass/fail | list |
| 6 | `.cursorrules` merged, not overwritten | pass/fail | diff |
| 7 | No project artifact modified | pass/fail | git status |
| 8 | Locally modified framework files surfaced, not discarded | pass/skip | list |
| 9 | Pinned revision and mode recorded in the pointer | pass/fail | |
| 10 | `verify` run inside the copy via `deploy-verify.sh`; all checks reported, pending tokens named | pass/fail | verdict |
| 11 | Breaking changes called out with migrations | pass/skip | |
| 12 | License position stated | pass/fail | |
| 13 | Next step (`@flutter-bootstrap init`) given | pass/fail | |
