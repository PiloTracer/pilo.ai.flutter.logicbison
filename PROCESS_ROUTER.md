# Process router

The lookup table. Find the row that matches, run the command.

For free-text requests use `@flutter-director - <request>`. For questions use `@flutter-router - <question>`. This file is for when you already know what you want and need the exact invocation.

---

## By intent

| I want to… | Run |
|------------|-----|
| Start a new Flutter project | `@flutter-bootstrap init` |
| Adopt the framework in an existing app | `@flutter-bootstrap init` → `@flutter-plan-verify brownfield` |
| Choose a state management library | `@flutter-stack probe` |
| Find out which stack this project uses | `@flutter-stack show` |
| Plan the product | `@flutter-foundation greenfield` |
| Turn the foundation into a work sequence | `@flutter-plan-master greenfield` |
| Specify one feature | `@flutter-feature-spec create - <slug>` |
| Generate the app skeleton | `@flutter-scaffold app` |
| Add a feature module | `@flutter-scaffold feature - <name>` |
| Start building a milestone | `@flutter-implementation plan - F<n>` |
| Continue building | `@flutter-implementation continue` |
| Close out a milestone | `@flutter-implementation complete` |
| Write a repository or model | `@flutter-data model` / `@flutter-data repository` |
| Add a database migration | `@flutter-data migration` |
| Call native code | `@flutter-platform channel` |
| Request a permission | `@flutter-platform permission` |
| Add deep links | `@flutter-platform deeplink` |
| Write tests | `@flutter-test plan` then `unit` / `widget` / `golden` / `integration` |
| Run tests | `@flutter-test run` |
| Check coverage | `@flutter-test coverage` |
| Audit a milestone | `@flutter-verify milestone` |
| Check before committing | `@flutter-verify uncommitted` |
| Check what was just committed | `@flutter-verify last` |
| Measure performance | `@flutter-perf profile` |
| Set performance budgets | `@flutter-perf budget` |
| Audit accessibility | `@flutter-a11y audit` |
| Audit security | `@flutter-security audit` |
| Fix findings | `@flutter-repair repair - from <source>` |
| Fix a broken build | `@flutter-doctor diagnose` |
| Fix the plan | `@flutter-plan-repair repair` |
| Prepare a release | `@flutter-release prepare` |
| Certify a release | `@flutter-release certify` |
| Build an artifact | `@flutter-release build - <target>` |
| Write documentation | `@flutter-docs create <kind>` |
| Run a review lens | `@flutter-concept-run run - <FLS-nn>` |
| See where the project is | `@flutter-session status` |
| Load context to resume | `@flutter-session context` |
| End a session cleanly | `@flutter-session close` |
| Install the framework elsewhere (thin) | `@flutter-deploy-basic - <target>` |
| Install the framework elsewhere (fat) | `@flutter-deploy-files - <target>` |
| Update the framework | `@flutter-deploy-basic update - <target>` (or `--update`) / `@flutter-deploy-files update` |

---

## By symptom

| Symptom | Start with | Why |
|---------|-----------|-----|
| "Skill says prerequisites not met" | Read its blocked report | It names the missing artifact and the skill that produces it |
| Gradle / CocoaPods / `pub get` failure | `@flutter-doctor deps` | Toolchain, not code |
| `build_runner` conflict or stale output | `@flutter-doctor codegen` | Codegen currency |
| Analyzer errors after a merge | `@flutter-repair repair - from gate` | Analyzer findings surface at the mechanical gate |
| Tests red | `@flutter-repair repair - from test` | Never delete or skip the test |
| Golden test failing | `@flutter-test golden` | Review the diff. Do **not** reflexively `--update-goldens` |
| UI janks | `@flutter-perf audit` → `profile` | Hypothesis, then measurement |
| App is too large | `@flutter-perf size` | |
| Crash reports unreadable | `@flutter-release prepare` | Missing symbol upload |
| Screen reader says "button" | `@flutter-a11y audit` | Missing semantic labels |
| Works on Android, broken on iOS | `@flutter-platform parity` | FLS-07 |
| Data lost on app update | `@flutter-data migration` | Migration not tested from the prior version |
| Plan and code disagree | `@flutter-plan-verify alignment` | Drift detection |
| Secret found in the repo | `@flutter-security secrets` | **Revoke first.** Deleting the commit does not revoke a leaked credential |
| Lost track of state | `@flutter-session status` | |

---

## Gate failures

Every gate failure reports the same shape: what is missing, why it blocks, and the skill that resolves it.

| Blocked because | Resolve with |
|-----------------|-------------|
| No `.work.flutter/` | `@flutter-bootstrap init` |
| Stack not locked | `@flutter-stack probe` → `set` |
| Foundation not certified | `@flutter-foundation continue` → `certify` |
| Master plan not Approved | `@flutter-plan-master status`, then approve |
| No active iteration block | `@flutter-implementation plan - F<n>` |
| SPEC not Approved | `@flutter-feature-spec review` → `approve` |
| Release not certified | `@flutter-release certify` |

A gate can be waived. Waivers are explicit, recorded with a reason and an owner, and visible to every later verifier. See [`standards/README.md`](standards/README.md).

---

## Ownership

When two skills could plausibly handle something, this decides.

| Territory | Owner |
|-----------|-------|
| Planning artifacts | `@flutter-plan-verify` finds · `@flutter-plan-repair` fixes |
| Code defects | `@flutter-verify` finds · `@flutter-repair` fixes |
| Environment and build | `@flutter-doctor` |
| Data layer | `@flutter-data` |
| Dart/native boundary | `@flutter-platform` |
| Tests | `@flutter-test` |
| Measured numbers | `@flutter-perf` |
| Session state | `@flutter-session` |

Verifiers never repair. Repairers never verify their own work without re-running the originating verifier. This separation is what keeps a "pass" meaningful.

---

## Other frameworks

| Work | Route to |
|------|----------|
| Visual design, tokens, component libraries | `@ui-director` (`.ai.ui`) |
| Backend, infrastructure, non-Flutter code | `@ai-director` (`.ai`) |
| Mixed | `@flutter-director` splits it and hands off the parts it does not own |

See [`COHABITATION.md`](COHABITATION.md).
