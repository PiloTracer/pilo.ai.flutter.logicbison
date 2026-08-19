# Contributing

This framework is read and executed by language models. That constrains how it is written more than a normal documentation project: ambiguity does not produce a question, it produces a confident wrong action.

---

## Before you change anything

```bash
bash scripts/framework-verify.sh   # is the framework well-formed?
bash scripts/self-test.sh          # do the checks still catch what they claim to?
```

Green before, green after. A change that breaks either is not ready, regardless of how good the prose is.

---

## Writing for an LLM reader

**Be decidable.** Every rule must be checkable by the agent from what it can see. "Keep widgets small" is unactionable. "A `build` method longer than 60 lines must extract a widget" is a rule.

**Front-load the constraint.** Models weight early tokens more heavily. Hard rules go near the top of a skill, not in a closing section.

**Prohibit concretely.** "Handle errors properly" is decoration. "Never `catch` without a type; map to a domain failure at the repository boundary" is enforceable.

**Give the failure path.** Every protocol states what to do when its step fails. A protocol without a failure branch invites improvisation, and improvisation is where agents cause damage.

**Never invite invention.** Where a fact is not available, the instruction is to ask or to record `unverified`. Never to assume.

**Say what "done" is.** Every skill ends with a completion checklist whose items are observable.

---

## Adding a skill

1. **Justify it.** If an existing skill could take a new mode instead, add the mode. Skill count is a cost paid by every agent that reads the registry.
2. **Name it `flutter-<noun-or-verb>`.** No exceptions — the prefix is what keeps cohabitation safe.
3. **Create `skills/flutter-<name>/skill.md`** with frontmatter (`name`, `description`), then: Role · Hard rules · Modes · Prerequisite gate · Protocols · Anti-patterns · Completion checklist.
4. **Stay under the context budget.** Soft limit 400 lines, hard limit 600. Overflow goes to `reference.md` beside it — tables, worked examples, question banks. `skill.md` holds what is needed every time; `reference.md` holds what is needed sometimes.
5. **Register it** in [`skills/README.md`](skills/README.md) and add its row to [`skills/SKILL_DEPENDENCIES.md`](skills/SKILL_DEPENDENCIES.md).
6. **Wire the routes** in `flutter-director/reference.md` and `flutter-router/reference.md`.
7. **Run the verifier.**

**Use the canonical verbs.** `status` · `init` · `plan` · `start` · `continue` · `complete` · `create` · `review` · `approve` · `amend` · `verify` · `audit` · `repair` · `probe` · `certify` · `show`. A new verb needs a reason that an existing one cannot cover.

---

## Adding a standard

Named `standards/YYYYMMDD-NAME_STANDARD.md`. Registered in `standards/README.md` with its binding condition and primary consumer.

Most standards are **templates** — they contain `REPLACE:` tokens filled by `@flutter-foundation` P3 when copied into `.work.flutter/standards/`. The project copy is binding; the framework copy is the source. If a standard has no project-specific variation, mark it non-templated and say why.

State what is **required**, what is **forbidden**, and what is **a judgement call with named factors**. A standard that is entirely judgement calls is an essay.

---

## Adding a concept (FLS)

A concept is a review lens: a prompt run against real code that produces findings with file and line.

`concepts/<slug>/prompt.md`, registered in `concepts/README.md` with its triggers. It must specify the questions (all of which must be answered, including with "not applicable"), the output shape, and **verdict rules** — the conditions that make a finding a blocker rather than a note. A concept without verdict rules produces opinions.

Numbering is sequential and permanent. FLS ids are not reused.

---

## Adding a script

POSIX-ish bash, no dependencies beyond coreutils and git. Exit `0` pass, `1` findings, `2` usage error. Output one line per check. Never destructive — report, and let a skill or a human decide.

If a script needs Flutter and Flutter is absent, print `unverified` and do not exit 0 as though it passed. A missing check is not a passing check.

Register it in `scripts/README.md`, and add a fixture plus an assertion to `scripts/self-test.sh`. A check with no fixture is a check nobody will notice breaking — assert both that clean input passes and that the specific defect is *named* in the output, not merely that the exit code is non-zero.

---

## Prose style

Skills and standards are technical instruments; they should read like a well-written engineering handbook. Complete sentences. No filler. Where a rule exists because of a specific failure, say what the failure was — a rule with a reason survives contact with an agent looking for a shortcut.

Avoid: hedging that leaves the decision open, "etc." in a list an agent must act on, examples that contradict the rule above them, and marketing language. Nothing in here should sound like it is selling itself.

---

## Testing a change

```bash
bash scripts/framework-verify.sh                        # structure, links, routes
bash scripts/self-test.sh                               # fixtures + bootstrap round trip
for f in scripts/*.sh hooks/*; do bash -n "$f"; done    # syntax
```

For a skill change, the real test is a dry run: give the skill's protocol to a model with no additional context and see whether it produces the intended action. If it needs you to explain something, that explanation belongs in the file.

---

## Versioning

Semver in [`CHANGELOG.md`](CHANGELOG.md).

- **Major** — a readiness state, path placeholder, or gate contract changes. Existing projects need migration.
- **Minor** — new skill, standard, concept, or mode. Additive.
- **Patch** — corrections, clarifications, script fixes.

`@flutter-deploy-basic update` / `@flutter-deploy-files update` compare versions and classify each file, so an accurate changelog is load-bearing, not decorative.

---

## Licence

MIT. Contributions are accepted under the same terms. Only free, open-source, commercially usable resources may be recommended — a package with a restrictive licence does not enter the catalog regardless of quality.
