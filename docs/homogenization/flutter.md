# Flutter Agent OS — sister registry and deploy parity (as-built)

**Status:** Implemented (see `CHANGELOG.md` 0.6.1+) · **Needs:** none for registry/deploy parity  
**Repo:** `/mnt/work/Projects/pilo.ai.flutter.logicbison`

This document describes the **current** sister-framework and deploy contract. Historical upgrade steps from 2026-08-19 are retired; do not treat the old "registry never shipped" prose as live state.

---

## As-built

| Surface | State |
|---------|--------|
| Discovery lib | `scripts/sister-discovery.sh` — legacy `.ai.<fw>` + family `pilo.ai.<fw>.logicbison`; `find_agent_os_dir` for the bare `.ai` slot |
| Framework `.cursorrules` | 7-row Frameworks registry (self-hosted Flutter row + six sisters) before Core principles |
| Adopter snippet | `templates/cursorrules.flutter.snippet.template` — registry with `REPLACE:AI_PATH` + `REPLACE:AI_*_PATH` cells |
| Full template | Gets the registry via `REPLACE:FLUTTER_SNIPPET_BLOCK` expansion |
| Deploy modes | **basic** (thin) and **files** (fat) only — `deploy-repo` removed |
| Deploy fill | `deploy-basic.sh` / `deploy-files.sh` fill sister cells at install; missing sisters stay `REPLACE:` |
| Source override | `AI_FLUTTER_SOURCE=/abs/path` — when the origin dir moves; bogus value aborts (exit 1), never silent fallback |
| Verify | `deploy-verify.sh` Frameworks registry section; `framework-verify.sh` + `self-test.sh` |

Bootstrap artifact for every sister cell: that framework's `skills/README.md` (file, not directory).

---

## Modes and skills

| Mode | Skill | Script |
|------|-------|--------|
| basic | `@flutter-deploy-basic` | `scripts/deploy-basic.sh` |
| files | `@flutter-deploy-files` | `scripts/deploy-files.sh` |

The former `deploy-repo` skill and `scripts/deploy-repo.sh` do not exist. A target still advertising `Mode: repo` fails `deploy-verify` with a migration instruction to reinstall via basic or files.

---

## Residual gaps

| Gap | Notes |
|-----|-------|
| Pre-0.6.1 thin installs | Consumers such as OfficeToolCombo may still point at a moved/missing source path and lack the registry — fix with `AI_FLUTTER_SOURCE=… bash scripts/deploy-basic.sh --target <repo> update` |
| `SKILL_DEPENDENCIES.md` prose | Keep registry resolution text aligned with the six sisters when editing that section |

---

## Verify

```bash
bash scripts/framework-verify.sh
bash scripts/self-test.sh
AI_FLUTTER_SOURCE=/mnt/work/Projects/pilo.ai.flutter.logicbison \
  bash scripts/deploy-verify.sh --target <adopter-repo>
```

## Next action

Next action: none — registry and deploy parity are shipped; refresh stale consumers with `@flutter-deploy-basic update`.
