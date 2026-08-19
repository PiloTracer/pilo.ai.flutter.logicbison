# Flutter Agent OS

An agent operating system for Flutter application development: **plan, build, verify, repair** — with gates that stop work when the ground underneath it is not ready, and evidence rules that stop an agent claiming results it did not observe.

MIT licensed. Every recommended dependency is free, open source and permitted for commercial use.

**New here?** [`START_HERE.md`](START_HERE.md). **Want something done?** `@flutter-director - <what you want>`.

---

## Why this exists

AI agents are very good at producing Flutter code that looks right. The failure modes are specific and repeatable:

| Failure | What this framework does about it |
|---------|-----------------------------------|
| Builds the wrong thing, confidently | Foundation and SPEC gates: nothing is implemented from an unapproved contract |
| Claims tests pass without running them | Evidence rules: quote the command and its output, or the result is `unverified` |
| Weakens a check to get to green | Explicit prohibition, plus FLS-12's weakening ledger |
| Changes something three files away | FLS-06: blast radius, adjacent behaviour, and what was **not** verified |
| Invents a package version or API | Verification against pub.dev is mandatory before recommending |
| Skips the states users actually hit | Six-state requirement on every data-backed surface |
| Forgets accessibility, security, offline | Dedicated verifiers and concept lenses, wired into the milestone gate |
| Loses context between sessions | HANDOFF and NEXT, maintained as deliverables |

The framework is a set of **markdown protocols** any LLM can follow, plus **shell scripts** that make the mechanical checks non-negotiable.

---

## What is in here

| Directory | Contents |
|-----------|----------|
| [`skills/`](skills/README.md) | 27 skills. Each has hard rules, modes, prerequisite gates, protocols and a completion checklist |
| [`standards/`](standards/README.md) | 21 standards + protected surfaces. Templates that become project-binding once tokens are filled |
| [`concepts/`](concepts/README.md) | FLS-01…FLS-13 review lenses, run against real diffs |
| [`stacks/`](stacks/README.md) | Per-state-management idiom guides: Riverpod, Bloc, Provider, Signals |
| [`resources/`](resources/README.md) | Vetted OSS package catalog with licences; Flutter CLI reference; UI-craft evidence base |
| [`templates/`](templates/) | What `@flutter-bootstrap init` writes into a repo |
| [`scripts/`](scripts/README.md) | Mechanical verifiers and installers |
| [`hooks/`](hooks/) | Git hooks: pre-commit, commit-msg, prepare-commit-msg, post-commit, pre-push |
| [`docs/`](docs/) | Adoption and workflow guides |

---

## The skills

**Orchestration** — `flutter-director` (free text → skill chain) · `flutter-router` (read-only signpost)

**Setup and planning** — `flutter-bootstrap` · `flutter-stack` · `flutter-foundation` · `flutter-plan-master` · `flutter-feature-spec` · `flutter-plan-verify` · `flutter-plan-repair`

**Implementation** — `flutter-scaffold` · `flutter-implementation` · `flutter-data` · `flutter-platform` · `flutter-release`

**Verification** — `flutter-test` · `flutter-verify` · `flutter-perf` · `flutter-a11y` · `flutter-security`

**Repair** — `flutter-repair` (code) · `flutter-doctor` (toolchain)

**Support** — `flutter-session` · `flutter-concept-run` · `flutter-docs` · `flutter-deploy-basic` (thin) · `flutter-deploy-files` (fat)

Full registry with roles: [`skills/README.md`](skills/README.md). Gates and prerequisites: [`skills/SKILL_DEPENDENCIES.md`](skills/SKILL_DEPENDENCIES.md).

---

## Readiness states

Progress is a state machine, and each transition has a certifier. Nothing is inferred from documents looking finished.

```
scaffold → stack-locked → foundation-complete → plan-ready
         → implementation-ready → release-ready
```

| State | Certified by | Unlocks |
|-------|-------------|---------|
| scaffold | `@flutter-bootstrap init` | stack selection, foundation |
| stack-locked | `@flutter-stack set` | scaffolding, architecture decisions |
| foundation-complete | `@flutter-foundation status` | certification |
| plan-ready | `@flutter-foundation certify` | the master plan |
| implementation-ready | master plan status Approved | writing code |
| release-ready | `@flutter-release certify` | building artifacts |

---

## Grilling

Requirements are not collected; they are **interrogated**. [`skills/probe-protocol.md`](skills/probe-protocol.md) runs an adaptive loop — assess coverage, ask the highest-value question, record, re-score — and then a **challenge pass** that attacks the answers: where is the evidence, what would a hostile reviewer attack, what happens if this is wrong.

Every question and answer lands in a probe ledger, and [`scripts/readiness-verify.sh`](scripts/readiness-verify.sh) fails a ledger that claims confirmation it did not earn.

The economics are simple: a question during planning costs a minute. The same gap discovered during implementation costs a task. Discovered after release, it costs a release.

---

## Install

```bash
bash scripts/deploy-basic.sh --target /path/to/repo   # thin — reads from here
bash scripts/deploy-files.sh --target /path/to/repo   # fat — self-contained
```

Then, in the target repo:

```
@flutter-bootstrap init
```

Installing the framework and scaffolding the project are separate steps. Both are required.

---

## Cohabitation

Designed to sit beside [Agent OS](../.ai) (`.ai`) and [UI Design OS](../.ai.ui) (`.ai.ui`) without collision: every skill is `flutter-` prefixed, the work tree is `.work.flutter/`, `.cursorrules` is merged between markers, and cross-framework work is routed rather than absorbed. See [`COHABITATION.md`](COHABITATION.md).

---

## Contributing

[`CONTRIBUTING.md`](CONTRIBUTING.md). Every change runs two suites: `framework-verify.sh` machine-checks skill and FLS registration, frontmatter, context budgets, internal links, `@skill` route resolution and path discipline; `self-test.sh` runs the verifiers against known-good and known-bad fixtures, so a check that has quietly stopped catching things fails rather than reassures.
