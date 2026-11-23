# CI/CD conventions — Flutter Agent OS

**Status:** Binding for adopter CI · **Needs:** none  
**Consumers:** `@flutter-scaffold ci`, `@flutter-release`, `@flutter-verify gate`

---

## 1. Local gate ≡ CI

CI runs the same commands `@flutter-verify gate` runs locally (Q1–Q8 shapes in that skill; concrete pins live in `DOCS_FLUTTER_STACK.md`). Divergence between CI YAML and the local gate is a defect — fix the YAML or the stack doc, do not paper over with a different suite.

Canonical template: `templates/ci/github-actions/flutter-gates.yml`. Install via `@flutter-scaffold ci`.

## 2. Thin vs fat framework install

| Install | Hygiene / framework scripts |
|---------|------------------------------|
| **basic** (thin) | Resolve via `FLUTTER_AGENT_OS_SOURCE` / `AI_FLUTTER_SOURCE`, or copy the needed scripts into the app's `scripts/` |
| **files** (fat) | Scripts live under the installed framework tree in the app; call them by relative path |

Never invent a second gate implementation in the workflow.

## 3. Secrets

No keystores, `key.properties`, service-account JSON, or API tokens in workflow files or committed config. Use the host's secret store. `--dart-define` values that ship in the binary are not secrets.

## 4. Flutter pin

Take the SDK channel or version from `DOCS_FLUTTER_STACK.md`. Do not hard-code a version into a standard or skill document. The workflow template uses `channel: stable` as a placeholder until the stack lock fills the pin. Its action refs (`@vN`) are placeholders too: check each action's current major before adopting.

## 5. Last-gate ledger

Optional in CI: call `scripts/last-gate-record.sh --verifier ci-flutter-gates` with the job's verdict, then upload `.work.flutter/reports/last-gate.json` as a workflow artifact. The runner workspace is discarded, so a record that is not uploaded is lost. Never commit it back from CI. Session close does not read this file.

## 6. No silent gates

A CI step that is not yet configured **fails** with a message naming what to configure; it never `echo`s and passes. A green job whose coverage floor was never enforced is the CI form of reporting an unrun check as passing. A step that only reports (Q8 dependency health) says so in its name.

## 7. Framework repo CI

`.github/workflows/verify.yml` in this framework source repo verifies the **framework** (`framework-verify`, `self-test`, bootstrap round-trip). It is not an adopter app template. Do not copy it into apps.

---

## Anti-patterns

- CI commands that differ from `flutter-verify gate` / `DOCS_FLUTTER_STACK.md`.
- Skipping analyze or tests "just for this PR".
- Placeholder steps that `echo` and exit 0 for a gate they do not enforce.
- Reading the coverage percentage as complete. `flutter test --coverage` records only files that some test imports, so a file no test touches is invisible and the figure is inflated (observed: the eval base app reports 100% with `main.dart` and a repository implementation untested). Treat the floor as a lower bound, and review new untested files in the diff.
- Committing secrets or signing material in workflows.
- Using framework-repo `verify.yml` as the app CI template.

## Next action

Next action: none — apply via `@flutter-scaffold ci` in the adopter repo.
