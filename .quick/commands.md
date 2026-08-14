# Commands

Every invocation, by skill. Argument form is `@skill mode - argument`.

---

## Orchestration

```
@flutter-director - <free text>            classify, chain, confirm, execute
@flutter-director status                   readiness snapshot
@flutter-director review-routing           read-only routing-confidence report

@flutter-router - <question>               ≤3 sentences + citation, read-only
@flutter-router help                       what exists and where
```

## Setup

```
@flutter-bootstrap init                    scaffold .work.flutter/ (idempotent)
@flutter-bootstrap status                  what is scaffolded
@flutter-bootstrap hooks                   install git hooks only

@flutter-stack probe                       interrogate the 7 dimensions
@flutter-stack set - <dimension>=<choice>  lock a choice
@flutter-stack detect                      infer from existing code (brownfield)
@flutter-stack show                        the locked stack
@flutter-stack audit                       package health and licences
```

## Planning

```
@flutter-foundation greenfield             run P0–P6
@flutter-foundation continue               resume at the first incomplete phase
@flutter-foundation probe - <dimension>    grill one dimension
@flutter-foundation certify                → plan-ready
@flutter-foundation status                 phase completion

@flutter-plan-master greenfield            author the 21-section plan
@flutter-plan-master continue
@flutter-plan-master probe
@flutter-plan-master integrity             run the verifier scripts
@flutter-plan-master revise - <change>     amend an approved plan
@flutter-plan-master status                → implementation-ready?
@flutter-plan-master show - F<n>           one milestone

@flutter-feature-spec intake - <request>   classify before writing
@flutter-feature-spec create - <slug>
@flutter-feature-spec probe - <slug>
@flutter-feature-spec review - <slug>
@flutter-feature-spec approve - <slug>
@flutter-feature-spec amend - <slug>
@flutter-feature-spec status

@flutter-plan-verify foundation|master|alignment|coverage|brownfield|all
@flutter-plan-repair repair - from <source>
@flutter-plan-repair brownfield            recover foundation FROM the code
```

## Implementation

```
@flutter-scaffold app                      generate the project skeleton
@flutter-scaffold feature - <name>
@flutter-scaffold package - <name>
@flutter-scaffold flavor - <name>
@flutter-scaffold ci
@flutter-scaffold test-harness

@flutter-implementation plan - F<n>        write the iteration block
@flutter-implementation start              load context, begin
@flutter-implementation continue           next task, or - F<n>-T<k>
@flutter-implementation task - F<n>-T<k>   one specific task
@flutter-implementation complete           close the iteration
@flutter-implementation status

@flutter-data model|repository|source|cache|migration|verify|audit|status
@flutter-platform channel|permission|deeplink|config|background|plugin|parity
@flutter-release prepare|certify|build - <target>|size|distribute|metadata
```

## Verification

```
@flutter-verify milestone                  15-dimension audit
@flutter-verify uncommitted                pre-commit sweep
@flutter-verify last                       post-commit check
@flutter-verify gate                       mechanical chain only

@flutter-test plan|unit|widget|golden|integration|a11y
@flutter-test run                          - <path> to narrow
@flutter-test coverage
@flutter-test goldens - update             only after reviewing the diff

@flutter-perf budget|audit|profile|startup|size|memory|trace
@flutter-a11y audit|test|traverse|contrast|scale
@flutter-security audit|secrets|storage|transport|deps|permissions|harden
```

## Repair

```
@flutter-repair repair - from <milestone|uncommitted|last|gate|test|a11y|security|perf|data-audit|stack-audit|concept>
@flutter-doctor diagnose                   classify first, always
@flutter-doctor env|deps|build|codegen|clean
```

## Support

```
@flutter-session status|context|start|close|handoff|next|blockers|add|commit|push
@flutter-session close [commit] [scoped] [push]   any combination; order is close → add → commit → push
@flutter-concept-run list|select|run - <FLS-nn>|status
@flutter-docs create guide|tutorial|reference|explanation|runbook
@flutter-docs readme|review|index|status
@flutter-deploy-basic basic|update|--update|verify|uninstall|status - <target>
@flutter-deploy-files files|update|--update|verify|uninstall|status - <target>
@flutter-deploy-repo repo|update|--update|verify|uninstall|status - <target>
```

---

## Scripts

```bash
bash scripts/framework-verify.sh
bash scripts/master-plan-verify.sh <plan.md>
bash scripts/traceability-verify.sh <plan.md>
bash scripts/readiness-verify.sh <ledger.md> [--gate]
bash scripts/gate-verify.sh
bash scripts/touch-scope-verify.sh --staged
bash scripts/blast-radius-check.sh --staged
bash scripts/dart-hygiene-check.sh [path]
bash scripts/install-git-hooks.sh
```

## Flutter

```bash
dart format --set-exit-if-changed .
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter test --coverage
flutter test integration_test/ -d <device>
flutter run --profile
flutter build appbundle --obfuscate --split-debug-info=build/symbols
```

Project-specific commands live in `DOCS_FLUTTER_STACK.md`. When it disagrees with this card, it wins — it describes the actual project.
