# flutter-router — reference

Authoritative routing table for [`skill.md`](skill.md). When a skill or standard is added, add its bucket here.

---

## Routing table

| Bucket | Example questions | Run next | Canonical sources |
|--------|-------------------|----------|-------------------|
| `orientation` | "where do I start?" · "what is this framework?" · "what should I do now?" | `@flutter-director status` | `START_HERE.md` · `README.md` |
| `install` | "how do I add this to my repo?" · "thin vs fat install?" | thin → `@flutter-deploy-basic - <path>`; fat → `@flutter-deploy-files - <path>` | `skills/flutter-deploy-basic/skill.md` · `skills/flutter-deploy-files/skill.md` |
| `bootstrap` | "how do I set up `.work.flutter/`?" · "what does init create?" | `@flutter-bootstrap init` | `skills/flutter-bootstrap/skill.md` · `templates/bootstrap.sh` |
| `stack-choice` | "Riverpod or Bloc?" · "which router?" · "how do I pick packages?" · "can I change the stack later?" | `@flutter-stack probe` then `set` | `stacks/README.md` · `standards/20260801-STATE_MANAGEMENT_STANDARD.md` |
| `packages` | "is package X allowed?" · "what's the license policy?" · "recommended JSON library?" | `@flutter-router - <specific package>` | `resources/packages-2026.md` · `standards/20260801-PACKAGE_LICENSE_STANDARD.md` |
| `architecture` | "where does business logic go?" · "can the UI import the data layer?" · "MVVM or Clean?" | `@flutter-concept-run run - FLS-03` | `standards/20260801-ARCHITECTURE_STANDARD.md` · `concepts/layer-boundary-audit/prompt.md` |
| `structure` | "where do feature folders live?" · "layer-first or feature-first?" · "where do tests go?" | — (read the map) | `standards/20260801-DIRECTORY_MAP.md` |
| `conventions` | "naming?" · "when is `const` required?" · "how do I log?" · "line length?" | — (read the conventions) | `standards/20260801-FLUTTER_CONVENTIONS.md` |
| `foundation` | "what are foundation docs?" · "what is P0–P6?" · "how do I get plan-ready?" | `@flutter-foundation status` | `skills/flutter-foundation/skill.md` · `docs/guides/workflows/greenfield.md` |
| `probe` | "how does the agent question me?" · "what is coverage?" · "why is it grilling me?" | `@flutter-foundation probe` | `skills/probe-protocol.md` |
| `master-plan` | "what goes in the master plan?" · "how are milestones numbered?" · "what is traceability?" | `@flutter-plan-master status` | `standards/20260801-MASTER_PLAN_STANDARD.md` |
| `spec` | "how do I write a feature SPEC?" · "what sections are mandatory?" · "how do I amend an approved SPEC?" | `@flutter-feature-spec create - <slug>` | `standards/20260801-FEATURE_SPEC_STANDARD.md` |
| `iteration` | "how do I start an iteration?" · "what is the iteration block?" · "how do I batch tasks?" | `@flutter-implementation plan - F{N}` | `skills/flutter-implementation/skill.md` · `docs/guides/workflows/iteration-loop.md` |
| `scaffold` | "how do I create a feature module?" · "how do I add a package?" · "how do I add a flavor?" | `@flutter-scaffold feature - <slug>` | `skills/flutter-scaffold/skill.md` · `standards/20260801-DIRECTORY_MAP.md` |
| `state` | "where do I put a ViewModel?" · "how do I expose async state?" · "how do I avoid rebuild storms?" | `@flutter-concept-run run - FLS-02` | `standards/20260801-STATE_MANAGEMENT_STANDARD.md` · `stacks/<locked>.md` |
| `navigation` | "how do I add a route?" · "deep links?" · "route guards?" · "nested navigation?" | `@flutter-platform deeplink` for links; otherwise read the standard | `standards/20260801-NAVIGATION_STANDARD.md` |
| `data` | "how do I model JSON?" · "repository pattern?" · "local database?" · "how do I migrate stored data?" | `@flutter-data <mode>` | `standards/20260801-DATA_LAYER_STANDARD.md` |
| `errors` | "how do I return errors?" · "Result or exceptions?" · "how do I show an error to the user?" | `@flutter-concept-run run - FLS-04` | `standards/20260801-ARCHITECTURE_STANDARD.md` § Error handling |
| `theming` | "how do I theme the app?" · "where do colors live?" · "Material 3?" · "dark mode?" | — (read the standard) | `standards/20260801-THEMING_STANDARD.md` |
| `ui-craft` | "why does my app look cheap/basic?" · "how do I make it look premium?" · "spacing scale?" · "hierarchy?" · "one accent?" | `@flutter-concept-run run - FLS-13` | `standards/20260802-UI_CRAFT_STANDARD.md` · `resources/ui-craft.md` · `concepts/ui-craft/prompt.md` |
| `l10n` | "how do I add translations?" · "ARB files?" · "RTL?" · "plurals?" | — (read the standard) | `standards/20260801-L10N_STANDARD.md` |
| `platform` | "how do I call native code?" · "runtime permissions?" · "app links?" · "how do I write a plugin?" | `@flutter-platform <mode>` | `skills/flutter-platform/skill.md` · `concepts/platform-parity/prompt.md` |
| `testing` | "what should I test?" · "widget vs integration?" · "how do goldens work?" · "coverage target?" | `@flutter-test plan` | `standards/20260801-TESTING_STANDARD.md` |
| `test-run` | "how do I run tests?" · "how do I update goldens?" · "how do I get coverage?" | `@flutter-test run` | `standards/20260801-QUALITY_GATES.md` |
| `verify` | "is this safe to commit?" · "what does milestone verify check?" · "what are the gates?" | `@flutter-verify uncommitted` | `skills/flutter-verify/skill.md` · `standards/20260801-QUALITY_GATES.md` |
| `perf` | "why is it janky?" · "what's the frame budget?" · "how do I profile?" · "how do I shrink the app?" | `@flutter-perf audit` | `standards/20260801-PERFORMANCE_STANDARD.md` · `concepts/performance-budget/prompt.md` |
| `a11y` | "how do I support screen readers?" · "contrast rules?" · "how do I test a11y?" | `@flutter-a11y audit` | `standards/20260801-ACCESSIBILITY_STANDARD.md` |
| `security` | "where do I store tokens?" · "certificate pinning?" · "is `--dart-define` secret?" · "obfuscation?" | `@flutter-security audit` | `standards/20260801-SECURITY_PRIVACY_STANDARD.md` |
| `observability` | "how do I log?" · "crash reporting?" · "analytics?" · "what must never be logged?" | — (read the standard) | `standards/20260801-OBSERVABILITY_STANDARD.md` |
| `repair` | "the audit found things, now what?" · "tests are red" · "how do I fix findings properly?" | `@flutter-repair repair - from <source>` | `skills/flutter-repair/skill.md` |
| `doctor` | "gradle error" · "pod install fails" · "pub version solving failed" · "build_runner conflict" · "it won't build" | `@flutter-doctor diagnose` | `skills/flutter-doctor/skill.md` · `resources/flutter-cli.md` |
| `release` | "how do I build a release?" · "signing?" · "flavors?" · "store checklist?" · "CI/CD?" | `@flutter-release status` | `standards/20260801-RELEASE_STANDARD.md` |
| `session` | "how do I start/close a session?" · "who commits?" · "how do I commit or push session state?" · "where was I?" | `@flutter-session context` | `skills/flutter-session/skill.md` |
| `concepts` | "what is FLS-06?" · "when do concept prompts run?" · "which concepts apply to my diff?" | `@flutter-concept-run list` | `concepts/README.md` |
| `docs` | "where do guides live?" · "how do I document a feature?" | `@flutter-docs create guide - <slug>` | `skills/flutter-docs/skill.md` |
| `gates` | "why am I blocked?" · "what unlocks implementation-ready?" · "what does the blocked report mean?" | `@flutter-director status` | `skills/SKILL_DEPENDENCIES.md` |
| `brownfield` | "we already have an app, how do we adopt this?" · "no plan exists" | `@flutter-plan-verify brownfield` | `docs/guides/workflows/brownfield-onboarding.md` |
| `cohabitation` | "how does this relate to `.ai`?" · "who owns the screen SPEC?" · "two HANDOFF files?" | — (read it once) | `COHABITATION.md` |
| `contributing` | "how do I add a skill?" · "what's the context budget?" · "how do I cut a release?" | — | `CONTRIBUTING.md` |
| `work-request` | anything phrased as "do X for me" | `@flutter-director - <their words>` | `skills/flutter-director/skill.md` |
| `not-covered` | genuinely outside the framework | `@flutter-director - <request>` (it can propose a new skill) | `skills/flutter-director/skill.md` § New skill protocol |

---

## Reading order (when the operator wants to learn the system)

1. [`START_HERE.md`](../../START_HERE.md) — decision tree, 5 minutes
2. [`README.md`](../../README.md) — what exists and why
3. [`APPROACH.md`](../../APPROACH.md) — archetypes and default skill chains
4. [`skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) — gates, states, vocabulary
5. [`standards/20260801-ARCHITECTURE_STANDARD.md`](../../standards/20260801-ARCHITECTURE_STANDARD.md) + [`20260801-DIRECTORY_MAP.md`](../../standards/20260801-DIRECTORY_MAP.md) — the shape of the code
6. [`standards/20260801-QUALITY_GATES.md`](../../standards/20260801-QUALITY_GATES.md) — what "done" means mechanically
7. [`concepts/README.md`](../../concepts/README.md) — when each FLS prompt fires
8. [`COHABITATION.md`](../../COHABITATION.md) — only if `.ai` or `.ai.ui` is also installed

---

## Frequent one-liners

| Question | Answer |
|----------|--------|
| "Which HANDOFF do I read?" | `.work.flutter/context/HANDOFF_FLUTTER.md`. The `.ai` one (`.work/context/HANDOFF.md`) is a different framework's memory. |
| "Milestone naming?" | `F{N}` for milestones, `F{N}-T{k}` for tasks. `M{N}` belongs to Agent OS, `S{N}` to UI Design OS. |
| "Commit message format?" | `FLT-123: imperative subject ≤72 chars`, or `type: description` when there is no ref. No AI attribution lines. |
| "Can I skip the iteration block?" | No. `@flutter-implementation` refuses to write code without a valid `## Current iteration` in `NEXT_FLUTTER.md`. |
| "Who runs `flutter pub get`?" | `@flutter-doctor deps` diagnoses it; `@flutter-scaffold` and `@flutter-data` run it as part of their own gates. |
| "Where do generated files go?" | Next to their source as `*.g.dart` / `*.freezed.dart`, excluded from analysis and coverage. See DIRECTORY_MAP. |
| "Is coverage enforced?" | Yes, at the threshold recorded in `.work.flutter/standards/` (default 80% line coverage on `lib/src/`, excluding generated files). |
| "What if `flutter` isn't installed?" | Authoring modes still work. Execution modes report `toolchain unavailable` and route to `@flutter-doctor env`. Never a fabricated pass. |
