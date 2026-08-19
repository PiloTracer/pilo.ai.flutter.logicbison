# flutter-director — reference

Extended tables for [`skill.md`](skill.md). Nothing here is normative on its own; the protocol lives in `skill.md`.

---

## Bucket registry

Full signal lists. Match on **intent**; the phrases are examples, not a keyword filter.

| Bucket | Example phrasings | Lead skill | Typical follow-on |
|--------|-------------------|------------|-------------------|
| `bootstrap` | "start a new Flutter project" · "set this repo up" · "nothing exists yet" | `@flutter-bootstrap init` | `@flutter-stack set` |
| `stack` | "Riverpod or Bloc?" · "which packages should we use" · "lock our choices" · "what's our DI" | `@flutter-stack set` | `@flutter-foundation greenfield` |
| `foundation` | "what are we building" · "write the blueprint" · "foundation docs" · "capture requirements" | `@flutter-foundation greenfield` | `probe` → `certify` |
| `foundation-probe` | "I'm not sure what we need" · "help me think this through" · "the scope is fuzzy" · "grill me" | `@flutter-foundation probe` | `certify` |
| `foundation-certify` | "ready to plan?" · "sign off the foundation" | `@flutter-foundation certify` | `@flutter-plan-master greenfield` |
| `master-plan` | "build a roadmap" · "break it into milestones" · "implementation plan" · "sequence the work" | `@flutter-plan-master greenfield` | `probe` → `integrity` → `status` |
| `master-probe` | "is the plan any good" · "what's missing from the plan" · "poke holes in this" | `@flutter-plan-master probe` | `integrity` |
| `plan-verify` | "audit the plan" · "does the code match the plan" · "check for drift" · "coverage of SPECs" | `@flutter-plan-verify <mode>` | `@flutter-plan-repair` |
| `plan-repair` | "fix the plan" · "we have code but no docs" · "reconstruct the plan" | `@flutter-plan-repair` | re-verify |
| `feature-request` | "users should be able to…" · "add dark mode" · "we need offline sync" (capability, not task) | `@flutter-feature-spec intake` | `create` or route |
| `feature-spec` | "write the SPEC" · "review this SPEC" · "approve checkout" · "document the existing login" | `@flutter-feature-spec <mode>` | `@flutter-plan-master revise` |
| `scaffold` | "create the app skeleton" · "new feature folder" · "add a shared package" · "add staging flavor" · "set up GitHub Actions" | `@flutter-scaffold <mode>` | `@flutter-implementation plan` |
| `implementation` | "build it" · "implement F2" · "keep going" · "next 5 tasks" · "finish the milestone" | `@flutter-implementation <mode>` | `@flutter-verify milestone` |
| `data` | "model this JSON" · "add a repository" · "cache the responses" · "Drift table" · "migrate local storage" | `@flutter-data <mode>` | `@flutter-test unit` |
| `platform` | "call native code" · "camera permission" · "handle app links" · "push notifications" · "write a plugin" | `@flutter-platform <mode>` | `@flutter-test integration` |
| `test` | "write widget tests" · "golden tests" · "raise coverage" · "run the suite" | `@flutter-test <mode>` | `@flutter-verify gate` |
| `verify` | "review my changes" · "verify F3" · "safe to commit?" · "audit the milestone" | `@flutter-verify <mode>` | `@flutter-repair` |
| `perf` | "scrolling stutters" · "app is slow to start" · "APK too big" · "memory grows" · "profile it" | `@flutter-perf <mode>` | `@flutter-repair repair - from perf` |
| `a11y` | "screen reader support" · "contrast" · "tap targets too small" · "semantics labels" | `@flutter-a11y audit` | `@flutter-repair repair - from a11y` |
| `ui-craft` | "the app looks cheap/basic" · "make it look premium" · "polish this screen" · "spacing/hierarchy/accent review" · "UI polish" | `@flutter-concept-run run - FLS-13` | `@flutter-repair repair - from concept` → re-verify (D15) |
| `security` | "are we leaking secrets" · "store the token safely" · "pin certificates" · "obfuscate the release" · "CVE in a dependency" | `@flutter-security <mode>` | `harden` or `@flutter-repair` |
| `repair` | "fix what the audit found" · "tests are red" · "make it pass" | `@flutter-repair repair - from <source>` | re-verify (automatic) |
| `doctor` | "gradle build failed" · "pod install error" · "version solving failed" · "build_runner conflict" · "won't run on my machine" | `@flutter-doctor diagnose` | targeted mode |
| `release` | "ship to TestFlight" · "build an app bundle" · "signing config" · "release checklist" · "store listing" | `@flutter-release <mode>` | `certify` → `build` |
| `session` | "start work" · "wrap up" · "commit this" · "push the session state" · "what was I doing" | `@flutter-session <mode>` | — |
| `concept` | "run the architecture check" · "FLS-06" · "concept prompts" | `@flutter-concept-run <mode>` | attach output |
| `docs` | "write a guide" · "tutorial for onboarding" · "document the API surface" | `@flutter-docs create <kind> - <slug>` | — |
| `deploy` | "install this framework in my other repo" | thin → `@flutter-deploy-basic - <path>`; fat → `@flutter-deploy-files - <path>` | — |
| `router` | "how do I…" · "where does X live" · "which skill for Y" | `@flutter-router - <question>` | — |
| `not-flutter` | "design the REST API" · "Postgres schema" · "Kubernetes" · "pick brand colors" · "design the dashboard layout" | preflight → `@ai-director` / `@ui-director` | — |
| `cross-framework` | "build the app and the backend for it" · "design and implement the checkout screen" | preflight → `@x-director` | — |
| `new-skill-needed` | genuinely uncovered Flutter capability | § New skill protocol | — |
| `unsure` | anything that fits two buckets equally, or has no object | Clarify gate | probe or router |

---

## Shortcut chains

| Operator says | Execute |
|---------------|---------|
| "Start a new Flutter app" | `@flutter-bootstrap init` → `@flutter-stack probe` → `@flutter-stack set` → `@flutter-foundation greenfield` |
| "I have an existing Flutter app, onboard it" | `@flutter-bootstrap init` → `@flutter-plan-verify brownfield` → `@flutter-plan-repair brownfield` → `@flutter-stack set` (record what the code already uses) |
| "Help me nail down the requirements" | `@flutter-foundation probe - until ready` → `@flutter-foundation certify` |
| "Create the implementation plan" | `@flutter-plan-master status`; if not plan-ready → `@flutter-foundation certify` first; then `greenfield` → `probe` → `integrity` |
| "Are we ready to code?" | `@flutter-plan-master status` → report implementation-ready; if no, list the blocking gaps |
| "Build feature X" | `@flutter-feature-spec intake - X` → (if `local`) `create` → `@flutter-plan-master revise` → `@flutter-implementation plan - F{N}` |
| "Keep building" | `@flutter-implementation status` → `continue` (default 1 task) or `plan - F{N}` when no iteration exists |
| "Implement the next 5 tasks" | `@flutter-implementation continue - 5` |
| "Finish this milestone" | `@flutter-implementation continue - until blocked` → `@flutter-verify milestone` → `@flutter-implementation complete` |
| "Is this safe to commit?" | `@flutter-verify uncommitted` |
| "Review the whole milestone" | `@flutter-verify milestone` |
| "Tests are failing" | `@flutter-test run` (capture output) → `@flutter-repair repair - from test` |
| "The app janks" | `@flutter-perf audit` (static) → `@flutter-perf profile` (device) → `@flutter-repair repair - from perf` |
| "Make it accessible" | `@flutter-a11y audit` → `@flutter-a11y test` → `@flutter-repair repair - from a11y` |
| "Security review before launch" | `@flutter-security audit` → `@flutter-security deps` → `@flutter-security harden` → `@flutter-verify milestone` |
| "It won't build" | `@flutter-doctor diagnose` → the targeted mode it recommends (`env` / `deps` / `build` / `clean`) |
| "Ship it" | `@flutter-release certify` → on pass `build - <flavor>` → `distribute` |
| "Add a staging environment" | `@flutter-scaffold flavor - staging` → `@flutter-release prepare` |
| "Set up CI" | `@flutter-scaffold ci` → `@flutter-verify gate` locally to confirm the same commands pass |
| "Where did we leave off?" | `@flutter-session context` |
| "Wrap up for the day" | `@flutter-session close` (add `commit` and/or `push` to also commit and/or push — e.g. `@flutter-session close commit push`) |
| "Audit everything" | `@flutter-plan-verify foundation` → `master` → `alignment` → `coverage` → `@flutter-verify milestone` → `@flutter-a11y audit` → `@flutter-security audit` → `@flutter-perf audit` |
| "Build the app and its backend" | preflight → `@x-director - <request>` |
| "Design and build the settings screen" | preflight → `@x-director - <request>` (UI Design OS owns the screen SPEC; this framework implements it) |

---

## Worked routing examples

### Example A — vague request, low confidence

> "make the app feel more professional"

```markdown
## flutter-director - need 3 answers before routing

**Request:** "make the app feel more professional"
**Why I am asking:** this maps to three different chains — visual craft (UI Design OS), perceived performance (`@flutter-perf`), or polish tasks in the plan (`@flutter-plan-master revise`). Routing wrong wastes a milestone.

1. Is the complaint mostly **how it looks** (spacing, type, color), **how it feels** (jank, slow transitions, loading states), or **what it does** (missing empty states, error handling, confirmations)?
2. Do you have a specific screen in mind, or the whole app?
3. Is UI Design OS (`.ai.ui`) installed here, or should the Flutter side own the visual decisions too?
```

### Example B — clear implementation request, high confidence

> "implement the next four tasks in the current milestone"

```markdown
## flutter-director routing plan

**Request:** "implement the next four tasks in the current milestone"
**Classified bucket:** implementation
**Routing confidence:** high
**Readiness:** stack locked (riverpod / go_router / riverpod-DI) · foundation yes · plan-ready yes · implementation-ready yes
**Gates checked:** ST0 pass (implementation-ready) · iteration block valid (F2, 4 pending tasks)

**Will execute:**
1. @flutter-implementation continue - 4 → up to 4 tasks, stopping on any gate failure
2. @flutter-verify uncommitted → auto-invoked batch-end sweep

**Will write:** `lib/src/features/cart/**`, `test/features/cart/**`, `.work.flutter/plans/NEXT_FLUTTER.md`, `.work.flutter/context/HANDOFF_FLUTTER.md`
**Will not do:** complete the milestone (that is a separate `complete` after `@flutter-verify milestone`)

Reply `y` / `yes` to proceed, `n` to abort, or edit the plan above.
```

### Example C — toolchain failure misread as a code bug

> "the build is broken, fix the code"

Classify as `doctor`, **not** `repair`. Say so in the plan:

```markdown
**Classified bucket:** doctor
**Routing confidence:** high
**Note:** the reported symptom is a build failure. `@flutter-repair` fixes code against verifier findings; it cannot resolve Gradle, CocoaPods, SDK or dependency-resolution errors. Diagnosing first avoids editing correct code.

**Will execute:**
1. @flutter-doctor diagnose → root-cause classification with the exact failing command
2. → the targeted mode it recommends
```

### Example D — cross-framework, sibling absent

> "build the login screen and the auth API"

```markdown
**Classified bucket:** cross-framework
**Preflight:** `../.ai/skills/README.md` → not found

framework not installed here

The API half needs Agent OS (`.ai`), which is not installed alongside this framework.
Flutter-side I can still do: `@flutter-feature-spec intake - login` to capture the client
contract and record the API dependency as an external blocker in UNKNOWNS.md.

Proceed with the Flutter half only? (`y` / `n`)
```

---

## Bucket → gate quick map

The gate most likely to block each bucket, so the Confirm gate can state it up front.

| Bucket | Likely blocking gate | Fix |
|--------|---------------------|-----|
| `stack` | SK0 — no HANDOFF | `@flutter-bootstrap init` |
| `foundation` | GF0 — no `.cursorrules` / HANDOFF | `@flutter-bootstrap init` |
| `foundation-certify` | CF0 — foundation incomplete | `@flutter-foundation continue` |
| `master-plan` | PG1 — not plan-ready | `@flutter-foundation certify` |
| `scaffold` | SC0 — stack not locked | `@flutter-stack set` |
| `implementation` | ST0 — not implementation-ready · no iteration block | `@flutter-plan-master status` · `plan - F{N}` |
| `data` | D0 — no active task or explicit request | name the task or state the request |
| `platform` | PL0 — platform folder absent | `@flutter-scaffold app` or add the platform |
| `verify` | V0 — milestone not in plan or NEXT | `@flutter-implementation plan - F{N}` |
| `release` | RL0 — release gates not green | run the audits the gate names |
| `repair` | R0 — no findings in scope | run the source verifier first |
| `doctor` | *(never gated)* | — |
