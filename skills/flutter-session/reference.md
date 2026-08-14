# flutter-session — reference

Supplement to `skill.md`: invocation examples, the mode comparison matrix, commit message examples, edge cases and wrong prompts. The protocols and hard rules live in `skill.md`; this file shows them being used.

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
