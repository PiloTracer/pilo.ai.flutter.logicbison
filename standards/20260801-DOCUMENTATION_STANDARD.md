# Documentation standard

> **Not templated.** Binding as written.

**Owned by:** `@flutter-docs`.

Documentation that is wrong is worse than documentation that is missing, because it is trusted. Every rule below follows from that.

---

## 1. Four kinds, chosen deliberately

| Kind | Reader's question | Optimised for |
|------|-------------------|---------------|
| **Tutorial** | "I'm new — get me to a working thing" | Learning; guaranteed success on a fixed path |
| **Guide** | "How do I do X?" | Accomplishing a task; the reader already knows the system |
| **Reference** | "What are the parameters of Y?" | Lookup; exhaustive and consistently ordered |
| **Explanation** | "Why is it built this way?" | Understanding; context and rejected alternatives |
| **Runbook** | "Production is broken" | Execution under stress; unambiguous steps with expected output |

**Mixing kinds is the most common documentation failure.** A tutorial that stops to explain loses the beginner. A reference that teaches cannot be scanned. Pick one kind per document; link to the others.

---

## 2. Verification is the core rule

| Artifact | Requirement |
|----------|-------------|
| Code sample | **Compiled.** Put it in a scratch target and analyze it |
| Command | **Run.** Paste the observed output, not the expected output |
| File path | Confirmed to exist |
| Link | Resolved; internal links relative |
| Version claim | Checked against `pubspec.yaml` and the SDK |

Anything not verifiable is marked inline: `> Not verified: <what and why>`. A document with no unverified markers and no verification date is making a claim it has not earned.

---

## 3. Front matter

```yaml
---
title: <title>
kind: tutorial | guide | reference | explanation | runbook
reader: <who this is for and what they already know>
status: draft | current | stale
flutter: <version>
dart: <version>
updated: <YYYY-MM-DD>
verified: <YYYY-MM-DD>
sources: [SPEC-004, standards/...]
---
```

`verified` is the date every command and sample was last executed — distinct from `updated`, which changes when prose changes. Without the distinction, a prose edit makes a two-year-old command look current.

Every generated doc also follows `skills/SKILL_DEPENDENCIES.md` § Document clarity contract: the header states what the document needs (review, or `nothing`); decisions the reader must make and open questions are separate numbered lists; the document ends with exactly one `## Next action` — for a procedure, the verification step in §4 is that action.

---

## 4. Writing

- **Name the reader.** A document for everyone helps no one.
- Lead with the outcome, then the detail. Readers arrive mid-problem and leave as soon as they have what they need.
- Short sentences and concrete nouns. Prefer the imperative in procedures.
- **Every guide, tutorial and runbook ends with a verification step** — a command the reader runs to confirm success. A procedure with no way to check the result is unfinished.
- Include the failure paths: what goes wrong, how to tell, and what to do.
- **Link, do not restate.** Restated standards go stale silently and create a second source of truth.
- No screenshots of text or code — unsearchable, unlocalisable, immediately stale. Screenshots of UI are fine and are dated.

---

## 5. Boundaries

| Content | Belongs in | Not in |
|---------|-----------|--------|
| Requirements and acceptance criteria | The SPEC | A guide |
| Sequencing and estimates | The master plan | A guide |
| Rules and thresholds | A standard | A guide |
| A decision and its rejected alternatives | An ADR | A guide |
| How to accomplish a task | A guide | A SPEC |

Duplicating any of the first four into prose creates a copy that will drift. Link to the source.

---

## 6. Required documents

| Document | Kind | Trigger |
|----------|------|---------|
| Repository README | reference | Always |
| Onboarding | tutorial | Second contributor |
| Local setup | guide | Always |
| Architecture overview | explanation | After foundation P2 |
| Release runbook | runbook | Before the first release |
| Incident response | runbook | Before production |
| Package README | reference | Every shared package |

A team that cannot onboard a new engineer without a conversation has an undocumented system, regardless of how many documents exist.

---

## 7. Staleness

- Every document has a `verified` date. Anything older than `REPLACE:DOC_STALE_MONTHS` months is reviewed or marked `stale`.
- `status: stale` is set the moment an accuracy finding is known, before it is fixed — readers deserve the warning immediately.
- Documentation for a removed feature is deleted, not left as history. Git remembers.
- A feature change that invalidates a document updates it in the same change. Otherwise it never happens.

---

## 8. Anti-patterns

- Code samples that were never compiled.
- Expected output instead of observed output.
- Documenting planned behaviour as current behaviour.
- Restating a standard instead of linking it.
- A procedure with no verification step.
- No named reader.
- No version or verification date.
- Screenshots of code.
- Marking a document current after editing only prose.
- Leaving a document out of the index.
