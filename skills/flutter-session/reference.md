# flutter-session — reference

Supplement to `skill.md`: invocation examples, mode comparison matrix, report templates, anti-patterns, completion checklist, commit message examples, edge cases and wrong prompts. Protocols and hard rules live in `skill.md`.

---

## Invocation examples

Canonical forms — the word `session` is never required after the `@flutter-session` route:

| Action | Prompt |
|--------|--------|
| Open | `@flutter-session` **start** |
| Open + goal | `@flutter-session` **start** `- implement SPEC-004 offline sync` |
| Load check | `@flutter-session` **status** |
| Full context load (no writes, uncommitted-aware) | `@flutter-session` **context** |
| Close | `@flutter-session` **close** |
| Close + commit (all safe in-scope changes incl. new files) | `@flutter-session` **close commit** |
| Close + commit (HANDOFF/NEXT only, project scope) | `@flutter-session` **close commit scoped** |
| Close + commit + push | `@flutter-session` **close commit push** |
| Stage only (no commit, no close) | `@flutter-session` **add** |
| Commit only (no close) | `@flutter-session` **commit** |
| Commit + push (no close) | `@flutter-session` **commit push** |
| HANDOFF entry only | `@flutter-session` **handoff** |
| Set the next pointer | `@flutter-session` **next** `- @flutter-implementation plan - F3` |
| List blockers | `@flutter-session` **blockers** |

Aliases: `open`, `begin` → `start`; `end`, `wrap up` → `close`.

Agents without `@` routing (CLI prompts):

```
Follow skills/flutter-session/skill.md — start.
Follow skills/flutter-session/skill.md — close commit push.
```

---

## Mode comparison

| | start | status | context | close | close commit | close commit push | commit | commit push | add |
|---|-------|--------|---------|-------|--------------|-------------------|--------|-------------|-----|
| Reads HANDOFF/NEXT | yes | yes | yes | yes | yes | yes | no | no | no |
| Updates HANDOFF | no | no | no | yes | yes | yes | no | no | no |
| Updates NEXT | no | no | no | yes | yes | yes | no | no | no |
| `git add` (resolved scope) | no | no | no | no | yes | yes | yes | yes | yes |
| `git commit` | no | no | no | no | yes | yes | yes | yes | no |
| `git push` | no | no | no | no | no | yes | no | yes | no |
| Commit message in output | no | no | no | always | always | always | always | always | no |
| Session stays open | yes | yes | yes | no | no | no | yes | yes | yes |

A default `close` never runs git. The operator runs git by hand from the drafted message if they want. HANDOFF/NEXT rows are `skip` in the framework source repo, which carries no project memory of its own.

---

## blockers protocol

Scan HANDOFF open items, `NEXT_FLUTTER.md` blocked tasks, SPEC front matter with `status: blocked`, and plan tasks marked blocked. Report as:

| Blocker | Blocks | Needs | Since | Owner |
|---------|--------|-------|-------|-------|

`Needs` must be actionable: "operator decision on offline conflict policy", not "clarification". A blocker with no owner and no needed action is a stale note — flag it for removal or escalation.

---

## Commit message examples

Subjects obey the repo's `commit-msg` hook: `F<n>-T<k>: …`, `<PREFIX>-<n>: …`, or `type: …`, ≤72 chars, imperative. No AI attribution, no co-author trailers.

**Session memory after planning work (no task ref):**

```
docs: record stack lock and foundation P1 outcome
```

**Iteration-scoped session (ref from the active iteration block):**

```
F2-T3: add offline conflict resolution to sync repository

Decision recorded in decisions/ADR-003; SPEC-004 amended to match.
```

**Framework maintenance session (framework source repo, whole-tree scope):**

```
docs: close session — plan F2 approved, F3 scoped
```

**Non-cohesive changes — suggest a split with two blocks instead of one muddled message:**

```
docs: record session close and F2 review outcome
```

```
chore: update risk registry and unknowns for F3
```

---

## Edge cases

| Situation | Behavior |
|-----------|----------|
| Framework source repo (this framework's own repo) | Scope resolves to the whole repo tree; `.work.flutter/` is gitignored scratch there, so a working-directory scope would commit nothing. HANDOFF/NEXT steps are `skip` — the commit message and `CHANGELOG.md` carry the record |
| `.work.flutter/` missing, and no framework markers either | Report "not bootstrapped" and stop; suggest `@flutter-bootstrap init`. `status` still answers |
| Only app-code changes; `.work.flutter/` clean (project scope) | Session commit stages nothing → "nothing to commit"; app changes listed as outside scope, left for a separate operator commit |
| Secrets path in `git status` | Halt close/commit/add; name the path, never print content |
| Clean tree + `commit` | Skip the commit; message block reads `none — working tree clean` |
| Iteration block active in NEXT | Leave the block to `@flutter-implementation`; update only the pointer above it |
| HANDOFF missing but `.work.flutter/` exists | Report the gap; `close` creates the first entry rather than refusing |
| No remote configured | `push` reports "no remote configured" and stops |
| Push rejected / network failure | Report the command output; the close report still stands |
| Operator asks to close without a HANDOFF entry | Allowed only on explicit confirmation; checklist marks the entry `skip` with the reason |
| Merge-conflict markers in the tree | Checklist **fail**; list the files; do not commit |
| Several unrelated change sets | Suggest a split: multiple message blocks, operator commits each by hand or re-runs `commit scoped` per set |
| `start` with a goal while a previous session's work is uncommitted | Note the dirty tree in the start report; do not stash, do not commit — git is opt-in |
| `add` twice in a row | Idempotent; the second run reports the same staged set |

---

## Wrong prompts

| Prompt | Problem | Use instead |
|--------|---------|-------------|
| `close` expecting an auto-commit | Default is draft-only | `close commit` |
| `close commit`, tree still dirty afterwards | Agent staged HANDOFF-only or skipped shell git | Re-run; default scope is all safe in-scope paths |
| `close commit` wanting bookend files only | Default commits the whole safe resolved scope | `close commit scoped` |
| `close push` without `commit` | `push` requires commit; normalized | `close commit push` |
| `commit` expecting a HANDOFF entry | Standalone commit writes nothing | `close commit` |
| `commit push` expecting the session to close | Session stays open | `close commit push` |
| `add` expecting a commit | `add` only stages | `commit` |
| `start` without reading files | The skill requires evidence | Full start protocol |
| Deleting and recreating HANDOFF | Loses history | Append + update the pointer |

---

## Report templates

### status

```markdown
## @flutter-session status

**Readiness:** <scaffold | stack-locked | foundation-complete | plan-ready | implementation-ready | release-ready>
**Evidence:** <the file and line that establishes it>

| Layer | State | Source |
|-------|-------|--------|
| Bootstrap | done / missing | `.work.flutter/` present |
| Stack | locked / partial / unlocked | `STACK.md` front matter |
| Foundation | P0–P6 → <phase>, certified <yes/no> | doc front matter |
| Master plan | <status>, milestone <F2 of 6> | plan front matter |
| Iteration | active F2 / none | `NEXT_FLUTTER.md` |
| SPECs | <n> approved · <n> draft · <n> blocked | SPEC front matter |
| Working tree | clean / <n> modified files | `git status` |
| Blockers | <n> open | HANDOFF |

**Last session:** <date> — <one line>
**Next action:** `<exact command>`
**Blocked by:** <blocker or none>
```

### context

```markdown
## @flutter-session context

**Loaded:** HANDOFF (last 3), NEXT, STACK, plan front matter, SPEC-004
**Not loaded:** foundation docs 01–03 (not needed for F2-T3), standards beyond DART_STYLE
**Working tree:** clean · or dirty (n staged / n unstaged / n untracked — areas: .work.flutter/plans ×2, lib/ ×3)
**Secrets scan:** clean | flagged: <paths, content not printed>
**Current task:** F2-T3 — <title>
**Contract:** SPEC-004 §4 — <the acceptance criterion in one line>
**Constraints in force:** <locked stack items relevant to this task>
**Ready to:** `@flutter-implementation continue - F2-T3`
```

### start

```markdown
## @flutter-session start

**Goal:** <one line>
**Readiness:** <state> — <evidence file>
**Pick up:** <pointer from NEXT_FLUTTER.md>
**Blocked by:** <blocker or none>
**First move:** `<exact command>`
```

### HANDOFF entry (C3)

```markdown
## <YYYY-MM-DD> — <session title>

**Skills:** @flutter-implementation, @flutter-verify
**Scope:** F2-T3, F2-T4

**Done**
- <what was completed, in terms of the task IDs and observable outcome>

**Verified**
- `flutter analyze` 0 · `flutter test` 142/142 · `@flutter-verify gate` PASS

**Decisions**
- <decision> — because <reason> · recorded in <ADR / doc / SPEC amendment>

**Open / blocked**
- <blocker> — needs <who or what> — blocks <task ID>

**Next**
- `<exact command>`
```

### close (C7)

```markdown
## @flutter-session close

**Recorded:** HANDOFF entry <date> — <title> · or "framework source repo — no HANDOFF"
**Next pointer:** `<command>`
**Blockers carried:** <n> — <one line each>
**Verification at close:** <results or "none run this session">

### Commit message
**Status:** draft | used | none — working tree clean
**Message:**

    docs: record session close — <subject>

**Git:** scope <project | framework> · no commit (default) · or committed <sha> · pushed <yes/no · branch>
**Left untouched:** <out-of-scope paths that were not staged, or none>
```

### commit (M5)

```markdown
## @flutter-session commit

**Branch:** <branch> · **Tree before:** <n> changed files in scope <project | framework>

### Commit message
**Status:** used | none — working tree clean
**Message:**

    docs: record session state — <subject>

**Git:** committed <sha> · pushed <yes/no · branch>
**Left untouched:** <out-of-scope paths or none>
**Session:** still open — HANDOFF and NEXT untouched.
```

### git result block

```markdown
**Git:** scope <project | framework> · committed <n> files · <sha> · pushed <yes/no · branch>
**Left untouched:** <out-of-scope paths that existed but were not staged>
```

---

## Anti-patterns

- Inferring readiness from how complete documents look instead of from certifications.
- Reading every foundation document to answer a one-line question.
- Closing a session without a HANDOFF entry because "nothing much happened".
- Writing "worked on the login screen" instead of task IDs and observable outcomes.
- Recording a verification result that was not observed this session.
- Leaving two competing next-actions in `NEXT_FLUTTER.md`.
- Silently dropping a blocker that was not resolved.
- Committing or pushing without being asked.
- Applying the `.work.flutter/` scope in the framework source repo, where it is gitignored scratch — the commit would come out empty while the real changes stay dirty.
- Drafting the commit message but never running git after `close commit` was requested — or reporting a commit with no SHA and no post-commit `git status -sb`.
- Running `git add .` or a path-less add in an adopter project, or committing a staged set that includes out-of-scope paths.
- Staging HANDOFF + NEXT only on a default `commit` — that is what `commit scoped` is for.
- Omitting new untracked in-scope files/dirs from a `commit`.
- Continuing a close, commit or add after the secrets scan matched.
- Omitting the commit message block because no git ran.
- Writing HANDOFF or NEXT on a standalone `commit`, `push`, or `add`.
- Pushing without a remote, force-pushing, amending, or committing with `--no-verify`.
- Editing the iteration block during a close.
- Reporting "all good" when the working tree has uncommitted changes.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Read order followed; every claim sourced | pass/fail | file list |
| 2 | Readiness derived from certifications only | pass/fail | certification cited |
| 3 | Missing certifications named, with the issuing skill | pass/skip | |
| 4 | `context` / `status` / `start` performed no writes | pass/skip | git diff |
| 5 | HANDOFF entry appended, not rewritten | pass/skip | `skip` in the framework source repo |
| 6 | Every Done item names a task ID or file | pass/skip | |
| 7 | Every Verified claim quotes an observed result | pass/skip | |
| 8 | Decisions point to where they were recorded | pass/skip | |
| 9 | Exactly one active pointer in NEXT | pass/skip | `skip` in the framework source repo |
| 10 | Blockers carried forward with owner and needed action | pass/skip | |
| 11 | No commit or push without an explicit request | pass/fail | |
| 12 | Commit message block shown (draft / used / none — clean) | pass/fail | |
| 13 | Secrets scan clean, or the run halted and said why | pass/fail/skip | |
| 14 | Scope resolved correctly (project vs framework); staged set stayed inside it; untracked in-scope files/dirs included | pass/skip | `git diff --cached --name-only` |
| 15 | Requested git ran in the shell; SHA + post-commit `git status -sb` quoted | pass/fail/skip | `git log -1 --oneline` |
| 16 | Push used the current branch and a configured remote; no `--force`, no amend | pass/skip | `git push` output |
| 17 | Standalone `commit` / `push` / `add` wrote nothing to HANDOFF or NEXT | pass/skip | |
| 18 | Next action is an exact runnable command | pass/fail | |
