---
name: flutter-session
description: >-
  Open, checkpoint and close Flutter Agent OS work sessions and maintain
  cross-session memory. Loads project context in the correct order, produces
  an accurate state snapshot, and writes the HANDOFF entry and NEXT_FLUTTER.md
  pointer that let the next session resume without re-deriving anything. Git
  is opt-in: add stages, commit commits, push pushes, and close, commit and
  push combine in any order (close commit, close commit scoped, close commit
  push, commit push, close push). Scope resolves by repo — the whole tree in
  the framework source repo, the .work.flutter/ working directory only in
  adopter projects. The commit message is always shown — drafted on a plain
  close, used with its SHA on a real commit. Use for start session, open
  session, where was I, what is the state, wrap up, stage session state,
  commit session state, push session state, or hand off.
---

# flutter-session

Every session ends. The only question is whether the next one starts from a written state or from archaeology. This skill owns that boundary.

**Never gated.** `status` works on a bare repo — the answer is simply "not bootstrapped".

**Pairs with:** every skill (all write HANDOFF entries), `flutter-director` (routes here for "where was I"), `flutter-plan-master` and `flutter-implementation` (own the `NEXT_FLUTTER.md` iteration block; this skill maintains the pointer around it).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Invocation examples, mode matrix, blockers protocol, edge cases:** [`reference.md`](reference.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never guess state — read it.** Every claim in a snapshot names the file it came from.
2. **Report the state that exists, not the state that should exist.** A missing certification is reported as missing, not inferred from adjacent evidence.
3. **`context` and `status` are read-only.** Loading context never writes, never fixes, never certifies.
4. **A close without a HANDOFF entry is not a close.** The entry is the deliverable.
5. **NEXT_FLUTTER.md carries exactly one active pointer.** Two "next" instructions means the next session picks wrong.
6. **Git is opt-in.** A plain `close` never commits or pushes — it drafts the commit message and stops. Git runs only when the invocation includes `add`, `commit` and/or `push`.
7. **Git scope resolves by repo.** In an adopter project, `add`/`commit` stage only `{FLUTTER_WORK_ROOT}` = `.work.flutter/` paths — including new untracked files/dirs that belong to project memory — never app code. In the framework source repo (where `.work.flutter/` is gitignored scratch), they stage all safe modified, added and deleted files repo-wide. `push` sends the current branch without `--force` either way.
8. **Requested git runs in the shell.** Typing `close commit` does not commit by itself. A dirty in-scope tree after `close commit` with only a drafted message is a **fail**, not a variation.
9. **Always show the commit message** — drafted, used with its SHA, or `none — working tree clean`.
10. **Secrets halt everything.** A dirty or staged path matching the secrets scan stops the close/commit/add until the operator resolves it; content is never printed.
11. **Record blockers as blockers.** An unresolved problem that is not written down will be rediscovered at cost.

---

## Parse invocation

Normalize the message to a **verb** plus optional **modifiers**. Execution order is always **close → add → commit → push**; any other order or duplicates are normalized to that, and the normalization is stated in the report.

| User says | Verb | Git action |
|-----------|------|------------|
| `@flutter-session` **start** [`- <goal>`] | open | — |
| `@flutter-session` **status** | status | — |
| `@flutter-session` **context** | context | — |
| `@flutter-session` **close** | close | draft message only |
| `@flutter-session` **close commit** | close | commit all safe changes in the resolved scope, incl. new untracked files/dirs |
| `@flutter-session` **close commit scoped** | close | commit only the paths the close report names (project scope: HANDOFF + NEXT) |
| `@flutter-session` **close commit push** | close | commit, then push |
| `@flutter-session` **close push** | close | treat as **close commit push** (`push` requires commit) |
| `@flutter-session` **commit** | commit | stage + commit the resolved scope; **no close** |
| `@flutter-session` **commit push** | commit | stage + commit + push; **no close** |
| `@flutter-session` **add** | add | stage the resolved scope only; **no commit, no close** |
| `@flutter-session` **handoff** | handoff | — (HANDOFF entry only) |
| `@flutter-session` **next** `- <instruction>` | next | — |
| `@flutter-session` **blockers** | blockers | — (protocol in `reference.md`) |

**Aliases (same verb):** `open`, `begin` → `start`; `end`, `wrap up` → `close`.

**Goal text:** anything after `-` on `start` that is not a modifier word (`commit`, `push`, `scoped`, `add`).

**Default mode:** a bare `@flutter-session` with no verb answers with `status`.

---

## Read order (canonical)

Cheapest first, and each read narrows the next. Skipping steps produces confidently wrong snapshots.

| # | File | Answers |
|---|------|---------|
| 1 | `{FLUTTER_HANDOFF}` = `.work.flutter/context/HANDOFF_FLUTTER.md` (most recent entries) | What happened last, and what was left open |
| 2 | `{FLUTTER_NEXT}` = `.work.flutter/plans/NEXT_FLUTTER.md` | What to do now; whether an iteration block is active |
| 3 | `{FLUTTER_STACK_LOCK}` | Whether the stack is locked, and to what |
| 4 | Foundation docs `01`–`05` front matter | Foundation phase progress and certification |
| 5 | `{FLUTTER_MASTER_PLAN}` front matter + milestone table | Plan status; which milestone is current |
| 6 | Active SPECs (front matter only) | What is approved, in progress, or blocked |
| 7 | `git status`, `git log --oneline -10` | Uncommitted work; recent direction |

**Front matter only** for docs 04–06 unless the answer requires more. Reading five full documents to answer "where was I" burns the context the next task needs. In the framework source repo rows 1–6 do not exist; read row 7 plus `CHANGELOG.md` and say so instead of inventing a project state.

---

## status protocol

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

**Readiness is derived only from certifications that exist.** Foundation docs that look complete but carry no certification → `foundation-complete`, not `plan-ready`. Say which certification is missing and which skill issues it. Framework source repo: no ladder — report branch, tree state and last commit.

---

## context protocol

For a fresh agent that must resume real work, not just be told the state. Read-only: HANDOFF, NEXT and every other file stay untouched.

1. Read in the canonical order above.
2. Read `.cursorrules` for the operating rules in force.
3. Read the standards named by the current task — not all of them.
4. If an iteration is active: read its block in full plus the SPECs it names.
5. Run the uncommitted-aware snapshot: `git status -sb`, `git diff --stat`, `git diff --cached --stat`. Clean tree → state "working tree clean". Dirty tree → summarize by top-level area with staged / unstaged / untracked counts; never paste diffs. Flag — without printing content — any path matching the secrets scan (§ close protocol C1).
6. Report what was loaded and, explicitly, what was **not**:

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

Stating what was not loaded prevents the next agent from assuming a full read. Stating the dirty-tree counts prevents the next agent from assuming a clean one.

---

## start protocol

`start` (aliases `open`, `begin`) loads context and points at the next action. It writes nothing — the close entry covers the whole session, so an open marker would only duplicate it.

1. Run the context protocol.
2. Capture the session goal: text after `start -`, else the active pointer in `NEXT_FLUTTER.md`, else ask **once**. Do not ask when the goal is already clear.
3. If the goal implies implementation, check readiness: `implementation-ready: yes` in `{FLUTTER_MASTER_PLAN}` front matter or a HANDOFF waiver naming the milestone. Not ready → say so and route to `@flutter-plan-master status`; do not start coding. (Framework source repo: no such gate exists; readiness means `framework-verify.sh` and `self-test.sh` pass after the change.)
4. Report:

```markdown
## @flutter-session start

**Goal:** <one line>
**Readiness:** <state> — <evidence file>
**Pick up:** <pointer from NEXT_FLUTTER.md>
**Blocked by:** <blocker or none>
**First move:** `<exact command>`
```

---

## close protocol

**Execution order:** C1 → C2 → C3 → C4 → C5 → C6 (git, only when `commit`/`push` requested) → C7. If the C1 secrets scan fails, **stop** — no HANDOFF write, no NEXT update, no git; report the failure in C7.

### C1 — Working-tree audit (mandatory)

`git status`, `git diff --stat`, `git diff --cached --stat`. Classify:

| Finding | Action |
|---------|--------|
| Uncommitted changes | Summarize by area; feeds the C5 message |
| Untracked files | In-scope project memory is expected; anything else is flagged |
| Staged only | Note ready to commit |
| Clean tree | State explicitly |

Compare against what the session set out to do. An unexplained gap in either direction is itself worth recording.

**Secrets scan (mandatory).** If `git status` lists any path matching `credentials/`, `.env`, `.env.*` (except `.env.example`), `*.pem`, `*.p12`, `*.key`, `*.pfx`, `*.p8`, `*.jks`, `*.keystore`, `key.properties`, `*id_rsa*`, `*.token`, `*.secret` → **halt the close**. Do not write HANDOFF, do not stage, do not print file content. Tell the operator to unstage and remove the file and never commit it.

### C2 — Verification gate (this session)

What was verified this session, quoted from observed output (`flutter analyze`, `flutter test`, `@flutter-verify gate` in an adopter project; `framework-verify.sh` and `self-test.sh` in the framework source repo). Nothing run → "none run this session". A failure is reported as a failure, not an edge case.

### C3 — Write the HANDOFF entry

Append (never rewrite history) to `{FLUTTER_HANDOFF}`:

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

**Rules:** every "Done" claim names a task ID or a file. Every "Verified" claim quotes an observed result — no result, no claim. Decisions that changed a locked or certified artifact must name where they were recorded; if they were not recorded anywhere, that is a blocker.

**Framework source repo:** there is no HANDOFF — the repo carries no project memory of its own. Skip C3/C4, mark them `skip` in the checklist, and let the commit message and the `CHANGELOG.md` entry carry the record.

### C4 — Update `NEXT_FLUTTER.md`

One active pointer. If an iteration block is active, leave the block alone (it belongs to `@flutter-implementation`) and update the pointer above it. If the iteration completed, the pointer becomes the next iteration's plan command.

### C5 — Commit message (always)

Always produce the commit message block — even when the tree is clean (`none — working tree clean`) and even when no git modifier was given (label **draft**; the operator runs git by hand if they want).

Subject: ≤72 chars, imperative, in one of the shapes the repo's `commit-msg` hook accepts:

- `F<n>-T<k>: <subject>` when the session maps to iteration tasks. Auto-detect the ref, in priority order: (1) task IDs named in the new HANDOFF entry's Scope or the active iteration block in `NEXT_FLUTTER.md`; (2) a ref in the branch name; (3) a ref in the last commit subject.
- `type: <subject>` (`feat` / `fix` / `docs` / `refactor` / `chore`) when no task ref applies — session-memory maintenance is usually `docs:` or `chore:`, and framework source work follows the same `type:` convention.

Body: optional; why, not a file list. No AI attribution and no `Co-authored-by:` trailers — the hooks reject them. One message when the changes are cohesive; suggest a split with multiple message blocks when they are not.

### C6 — Git actions (only when `commit` / `push` was requested)

Run the git protocol below, **after** C3/C4 so the HANDOFF entry and NEXT pointer ride in the same commit. Post-commit verification is mandatory: `git status -sb` + `git log -1 --oneline`. A requested commit that produced no SHA is a **fail**.

### C7 — Report

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

Close with Form A or Form B per the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## git protocol (add / commit / push / close combinations)

### Scope resolution (first, always)

| Repo the skill runs in | Marker | Commit scope |
|------------------------|--------|--------------|
| Adopter project | `.work.flutter/` exists at the repo root and is **not** gitignored (`git check-ignore -q .work.flutter` fails) | `.work.flutter/` only — never app code |
| Framework source repo | `.work.flutter/` absent or gitignored, **and** `skills/README.md` + `standards/` + `scripts/framework-verify.sh` present at the root | the whole repo tree — all safe modified, added and deleted files |
| Anything else | neither marker | "not bootstrapped" — stop; nothing to stage, commit or push |

The framework repo carries no project memory of its own — `.work.flutter/` is gitignored scratch there — so a working-directory scope would commit nothing; the session commit exists to persist the framework work itself. Combinations and their normalization (close → add → commit → push): see § Parse invocation.

### Scope guard

1. Resolve the scope per the table above. "Not bootstrapped" stops the git step; the close report still stands.
2. Stage with the resolved restriction. Project scope: `git add -A -- .work.flutter/` — stages new, modified and deleted files/dirs under the working directory and respects `.gitignore`, so scratch such as `.work.flutter/analysis/tmp/` and `.work.flutter/commit-ref-pending/` stays ignored. Framework scope: `git add -A` at the repo root — `.gitignore` keeps `TMP/`, `.work.flutter/` and build output out.
3. Verify the staged set before committing: `git diff --cached --name-only` must contain only in-scope paths (project scope: only `.work.flutter/`; framework scope: nothing gitignored). Anything else staged is reported as left untouched and never committed.
4. Commit with the path restriction in project scope too: `git commit -m <subject> -- .work.flutter/`, so unrelated staged content cannot ride along. Never `--amend`, never a bare `git add .`, never `--no-verify`.
5. Report precisely: which scope resolved, what was staged, what was committed, what was left untouched, and why.

**`scoped` modifier:** stage only the paths the close report explicitly ties to this session — in project scope that is typically `{FLUTTER_HANDOFF}` + `{FLUTTER_NEXT}`. Use it when the operator wants bookend files only. A default `commit` always means the whole safe resolved scope — staging bookend files only on a default commit is a **fail**.

### commit rules

1. Subject follows § C5 (hook-accepted shapes, ≤72 chars, imperative). No AI attribution, no tool co-author trailers.
2. **Untracked in-scope files/dirs are included.** Project scope: everything under `.work.flutter/` that belongs to project memory — HANDOFF, NEXT, plans, decisions, docs, SPECs, STACK.md. Framework scope: new skills, standards, scripts, fixtures, docs — the whole change set. That is the point of the scope.
3. Nothing to commit → report "nothing to commit" as the outcome, not as an error.
4. Commit via HEREDOC when the message has a body, so the message survives quoting exactly as drafted.
5. Post-commit verification is mandatory: quote the new SHA and `git status -sb`. Leftover safe in-scope paths after a requested commit are a **fail** unless each is named with its reason (secrets, protected, intentional WIP).
6. Never commit out-of-scope paths, never amend, never force-push.

### push rules

1. Requires a configured remote (`git remote` non-empty); otherwise report "no remote configured" and stop without inventing one.
2. Pushes the current branch only: `git push`. Never `--force`.
3. If the resolved scope has uncommitted changes, commit them first per the commit rules — a session push is a state persist, and uncommitted state would otherwise be left behind.
4. Nothing to commit and nothing unpushed → report "nothing to push".
5. A push that fails (rejected, network) is reported with the command output; the session close report still records the state.

### git result block (append to any report that ran git)

```markdown
**Git:** scope <project | framework> · committed <n> files · <sha> · pushed <yes/no · branch>
**Left untouched:** <out-of-scope paths that existed but were not staged>
```

A report carrying this block still closes with Form A or Form B per the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## add protocol (stage-only checkpoint)

`add` stages without committing — a mid-session checkpoint for reviewing the staged set before a later `commit`, or for handing a prepared tree to the operator.

1. Run the C1 audit including the secrets scan (halt on a match).
2. Stage per the scope guard (project: `git add -A -- .work.flutter/`; framework: `git add -A`).
3. Report the staged set from `git diff --cached --name-only`, and state explicitly: nothing was committed and the session stays open.

Nothing to stage → report "nothing to stage", not an error.

---

## commit protocol (standalone — no close)

`commit` / `commit push` run the git steps **without** touching HANDOFF or NEXT. The session stays open. Idempotent — re-runnable mid-session.

**Execution order:** M1 → M2 → M3 → M4 → M5. If the M1 secrets scan fails, stop — no git.

- **M1 — Working-tree audit:** same as C1.
- **M2 — Verification gate:** same as C2.
- **M3 — Commit message:** same as C5. Always shown, even when the tree is clean.
- **M4 — Git actions:** scope guard + commit rules; push when `push` was requested.
- **M5 — Report:**

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
