---
name: flutter-docs
description: >-
  Create and maintain project documentation - guides, tutorials, reference docs,
  architecture overviews, runbooks and READMEs - under the project work tree.
  Verifies every code sample compiles and every command runs before publishing,
  and keeps documentation traceable to the SPECs and standards it describes.
  Use for write a guide, document this feature, onboarding docs, or API
  reference.
---

# flutter-docs

Documentation that is wrong is worse than documentation that is missing, because it is trusted. This skill's core discipline is simple: **nothing is published that was not executed.**

**Never gated,** but documentation of a feature requires that the feature exists.

**Pairs with:** `flutter-feature-spec` (SPECs are contracts, not docs), `flutter-foundation` (foundation docs are planning artifacts, not docs), `flutter-implementation` (routes here when a task requires a guide).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Style:** [`standards/20260801-DOCUMENTATION_STANDARD.md`](../../standards/20260801-DOCUMENTATION_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B · [Document clarity](../SKILL_DEPENDENCIES.md#document-clarity-contract) — Status + Needs header, separate Decisions/Open questions lists, exactly one `## Next action`, no leftover scaffolding.

**Hard rules:**

1. **Every code sample must compile.** Put it in a scratch target and analyze it. A sample that does not compile is a bug report from the future.
2. **Every command must be run.** Paste the observed output, not the expected output.
3. **Never document intended behaviour as actual behaviour.** If it is not implemented, it belongs in a SPEC.
4. **Documentation is not a SPEC and not a plan.** Requirements live in SPECs; sequencing lives in the plan. Duplicating them creates a second source of truth that will drift.
5. **Link, do not restate.** Restated standards go stale silently.
6. **State the version.** Flutter, Dart, and key package versions the document was written against, plus the date.
7. **Write for the named reader.** "A new engineer on day one" and "a maintainer debugging a release build" need different documents.

---

## Modes

| Mode | Action |
|------|--------|
| `create guide - <slug>` | Task-oriented: how to accomplish something |
| `create tutorial - <slug>` | Learning-oriented: a guided path from zero to working |
| `create reference - <slug>` | Information-oriented: exhaustive, lookup-optimised |
| `create explanation - <slug>` | Understanding-oriented: why the system is shaped this way |
| `create runbook - <slug>` | Operations: release, rollback, incident, on-call |
| `readme - <path>` | Author or refresh a package or module README |
| `review - <path>` | Audit an existing document for accuracy and drift |
| `index` | Rebuild the documentation index |
| `status` | Read-only: what exists, what is stale, what is missing |

The four `create` kinds follow the Diátaxis split. **Choosing the wrong kind is the most common documentation failure** — a tutorial that keeps stopping to explain, or a reference that tries to teach, serves neither reader.

| Reader arrives asking | Kind |
|-----------------------|------|
| "How do I do X?" (knows the system) | guide |
| "I'm new — get me to a working thing" | tutorial |
| "What are the parameters of Y?" | reference |
| "Why is it built this way?" | explanation |
| "Production is broken / it's release day" | runbook |

---

## create protocol

### C1 — Establish the reader and the outcome

Name the reader, their starting knowledge, and what they can do afterwards that they could not before. If this cannot be stated in two sentences, the document has no scope and should not be started.

### C2 — Gather ground truth

Read the code, the SPEC, the standards, and the locked stack. Never write from an assumption about how the code works — read the code. Where the code and an existing document disagree, the code is the truth and the document is a finding.

### C3 — Write

Front matter on every document:

```yaml
---
title: <title>
kind: guide | tutorial | reference | explanation | runbook
reader: <who this is for>
status: draft | current | stale
flutter: <version>   # version this was verified against
dart: <version>
updated: <YYYY-MM-DD>
verified: <YYYY-MM-DD>  # date every command and sample was last executed
sources: [SPEC-004, standards/...-ARCHITECTURE_STANDARD.md]
---
```

Structure by kind:

| Kind | Structure |
|------|-----------|
| guide | Goal → prerequisites → numbered steps → verification step → troubleshooting → related |
| tutorial | What you'll build → prerequisites → sequential steps, each producing visible progress → working result → next steps |
| reference | Overview → exhaustive entries in a stable order → examples → constraints and errors |
| explanation | Context → the problem → the decision → alternatives rejected and why → consequences → related ADRs |
| runbook | When to use → preconditions → steps with expected output at each → verification → rollback → escalation |

**Every guide and tutorial ends with a verification step** — a command the reader runs to confirm it worked. A procedure with no way to check the outcome is not finished.

### C4 — Execute everything

| Artifact | Verification |
|----------|--------------|
| Dart snippet | Compile it in a scratch target; `dart analyze` clean |
| Shell command | Run it; paste the observed output |
| File path | Confirm it exists at that path |
| Link | Resolve it; internal links must be relative |
| Version claim | Check against `pubspec.yaml` and `flutter --version` |

Anything that could not be executed is marked inline: `> Not verified: <what and why>`. Then set `verified:` in the front matter.

### C5 — Register

Add to the documentation index with kind, reader and status. An unindexed document will not be found and will rot.

---

## review protocol

Audit against reality, not against style.

| Check | Fails when |
|-------|-----------|
| Code samples compile | Any sample fails to analyze |
| Commands run | Any command errors or produces different output |
| Paths exist | Any referenced path is gone or moved |
| Links resolve | Any dead or wrong-target link |
| Version currency | Documented versions differ from the project's |
| Behavioural accuracy | The described behaviour differs from the code |
| SPEC alignment | Contradicts an approved SPEC |
| Duplication | Restates a standard instead of linking |
| Kind fit | A tutorial acting as a reference, or the reverse |

Report each finding with location and the correct value. Set `status: stale` on any document with an accuracy finding, so readers are warned before it is fixed.

---

## status protocol

| Document | Kind | Status | Verified | Age | Risk |
|----------|------|--------|----------|-----|------|

**Risk** is high when the document is stale **and** load-bearing (onboarding, release runbook, security procedure). Also report documentation that should exist and does not: every P0 feature and every operational procedure that a new maintainer would need at 2am.

---

## Anti-patterns

- Publishing a code sample that was never compiled.
- Pasting expected output instead of observed output.
- Documenting a feature that is planned but not built.
- Copying a standard into a guide instead of linking it.
- A guide with no verification step.
- Writing without naming the reader.
- No version or verification date, making staleness undetectable.
- Screenshots of text or code.
- Marking a document current after editing only its prose.
- Duplicating a SPEC's requirements in prose, creating a second source of truth.
- Leaving a document out of the index.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Reader and outcome stated | pass/fail | |
| 2 | Kind matches the reader's question | pass/fail | |
| 3 | Ground truth read from code and SPEC | pass/fail | files |
| 4 | Front matter complete, versions recorded | pass/fail | |
| 5 | Every code sample compiled | pass/fail | analyze output |
| 6 | Every command run; observed output pasted | pass/fail | |
| 7 | Every path and link resolved | pass/fail | |
| 8 | Verification step present (guide/tutorial/runbook) | pass/skip | |
| 9 | Unverified items marked inline | pass/skip | |
| 10 | Standards linked, not restated | pass/fail | |
| 11 | `verified:` date set | pass/fail | |
| 12 | Indexed | pass/fail | index entry |
