# Scripts

Mechanical checks and installers. Skills **run** these rather than reasoning about the same questions in prose — a script gives the same answer every time, and its output is quotable evidence.

All are POSIX-ish bash with no dependencies beyond coreutils and git. Nothing here requires Flutter to be installed; scripts that would need it report `unverified` instead of guessing.

---

## Verifiers

| Script | Checks | Run by |
|--------|--------|--------|
| [`framework-verify.sh`](framework-verify.sh) | The framework itself: registration, frontmatter, context budgets, internal links, `@skill` route resolution, FLS registration, path discipline | `CONTRIBUTING`, `@flutter-deploy-basic verify` / `@flutter-deploy-files verify` / `@flutter-deploy-repo verify` |
| [`master-plan-verify.sh`](master-plan-verify.sh) | The 21 plan sections, front matter, id conventions, placeholder residue | `@flutter-plan-verify master` |
| [`traceability-verify.sh`](traceability-verify.sh) | FR/NFR ↔ task coverage in **both** directions | `@flutter-plan-verify master` |
| [`readiness-verify.sh`](readiness-verify.sh) | Probe ledger honesty: unsupported confirmations, coverage arithmetic | `@flutter-foundation certify` |
| [`gate-verify.sh`](gate-verify.sh) | Tasks marked done carry evidence; one active pointer; FLS-06 present | `@flutter-verify last` |
| [`touch-scope-verify.sh`](touch-scope-verify.sh) | The diff against the declared task scope | pre-commit, `@flutter-verify` |
| [`blast-radius-check.sh`](blast-radius-check.sh) | Diff size, area spread, protected surfaces, never-commit paths | pre-commit, `@flutter-verify` |
| [`dart-hygiene-check.sh`](dart-hygiene-check.sh) | Patterns the analyzer misses: `print`, colour/spacing/fontSize literals, bare catch, secrets | pre-commit, task gate |
| [`self-test.sh`](self-test.sh) | The verifiers themselves, against fixtures | CI, `CONTRIBUTING` |
| [`deploy-verify.sh`](deploy-verify.sh) | A target repo's install: pointer, recorded framework location, `.cursorrules` block (markers, unresolved `REPLACE:` tokens with their owners, framework path, `@flutter-*` routes), gitignore scratch exclusions | `@flutter-deploy-basic verify` / `@flutter-deploy-files verify` / `@flutter-deploy-repo verify` |

## Self-test

[`self-test.sh`](self-test.sh) runs every verifier against known-good and known-bad fixtures in [`fixtures/`](fixtures/), asserting both that clean input passes and that each specific defect is *named* in the output.

`framework-verify.sh` checks that the framework is well-formed. `self-test.sh` checks that the checks still work. A verifier that has quietly regressed into passing everything is worse than no verifier, because it produces confidence.

```bash
bash scripts/self-test.sh
```

Adding a scan or a rule means adding a fixture line that triggers it and an assertion that names it. A check with no fixture is a check nobody will notice breaking.

## Installers

| Script | Purpose |
|--------|---------|
| [`install-git-hooks.sh`](install-git-hooks.sh) | Installs the hooks; preserves and chains existing ones as `<hook>.local` |
| [`deploy-basic.sh`](deploy-basic.sh) | Thin install — pointer + `.cursorrules` registration (skill: `@flutter-deploy-basic`) |
| [`deploy-files.sh`](deploy-files.sh) | Fat install — self-contained copy (skill: `@flutter-deploy-files`) |
| [`deploy-repo.sh`](deploy-repo.sh) | Pinned clone or submodule (skill: `@flutter-deploy-repo`) |

The three deploy scripts take the target positionally or via `--target`, and the lifecycle modes bare or `--`-prefixed in any order (`update` ≡ `--update`). `verify` hands off to `deploy-verify.sh`; `update` and `uninstall` are skill-run protocols, so the scripts route to the owning skill rather than acting.

Project scaffolding is [`templates/bootstrap.sh`](../templates/bootstrap.sh) — installing the framework and setting up a project are different steps, and both are required.

---

## Conventions

| | |
|---|---|
| Exit code | `0` pass · `1` findings or failure · `2` usage error |
| Output | One line per check: `ok` / `warn` / `FAIL`, then a summary and a verdict |
| Failures | Go to stderr with a file and, where applicable, a line |
| Destructive actions | None. Scripts report; skills and humans decide |
| Missing toolchain | Reported as unverified. **Never** treated as a pass |
| `.cursorrules` | Merged between markers, never overwritten |

---

## Running them directly

```bash
bash scripts/framework-verify.sh
bash scripts/master-plan-verify.sh .work.flutter/plans/full/20260801-full-plan.md
bash scripts/blast-radius-check.sh --staged
bash scripts/dart-hygiene-check.sh lib/features/auth/presentation/login_view.dart
```

A skill that reports a script's verdict **quotes the output**. A verdict with no output behind it is an assertion, and this framework does not accept assertions as evidence.
