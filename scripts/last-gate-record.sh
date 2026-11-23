#!/usr/bin/env bash
# Write .work.flutter/reports/last-gate.json after a verification run (audit trail).
#
# Usage:
#   bash scripts/last-gate-record.sh --verifier NAME --verdict VERDICT \
#     [--command "cmd" --exit N]...
#
# VERDICT uses the flutter-verify vocabulary: pass | pass_with_gaps | fail | unverified.
# Every --command must be followed by its own --exit. An exit code is a
# non-negative integer, or `not_run` for a check that could not execute (recorded
# as null). A command without an exit, or an exit without a command, is refused:
# a record that pairs the wrong exit with the wrong command is worse than none.
#
# The record stamps HEAD *and* whether the worktree was dirty. An `uncommitted`
# verify audits changes that HEAD does not contain; stamping HEAD alone would
# claim the gate passed on a commit it never saw.
#
# Override root with LAST_GATE_ROOT. Session close does not read this file.
# Dependencies: bash, git, coreutils (no python, no jq).
# Exit: 0 written · 2 usage
set -euo pipefail

usage() {
  echo "usage: last-gate-record.sh --verifier NAME --verdict pass|pass_with_gaps|fail|unverified [--command CMD --exit N|not_run]..." >&2
  exit 2
}
die() { echo "last-gate-record: $*" >&2; exit 2; }

# JSON string literal: strip control characters JSON cannot carry raw, then escape.
json_str() {
  local s
  s="$(printf '%s' "$1" | LC_ALL=C tr -d '\000-\010\013\014\016-\037')"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '"%s"' "$s"
}

if [[ -n "${LAST_GATE_ROOT:-}" ]]; then
  ROOT="${LAST_GATE_ROOT}"
else
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
REL_OUT=".work.flutter/reports/last-gate.json"
OUT="${ROOT}/${REL_OUT}"

VERIFIER=""
VERDICT=""
CMDS=()
EXITS=()
PENDING=""
HAVE_PENDING=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verifier)
      [[ $# -ge 2 ]] || usage; VERIFIER="$2"; shift 2 ;;
    --verdict)
      [[ $# -ge 2 ]] || usage; VERDICT="$2"; shift 2 ;;
    --command)
      [[ $# -ge 2 ]] || usage
      [[ $HAVE_PENDING -eq 0 ]] || die "--command '${PENDING}' has no matching --exit"
      [[ -n "$2" ]] || die "--command must not be empty"
      PENDING="$2"; HAVE_PENDING=1; shift 2 ;;
    --exit)
      [[ $# -ge 2 ]] || usage
      [[ $HAVE_PENDING -eq 1 ]] || die "--exit '$2' has no preceding --command"
      if [[ "$2" =~ ^[0-9]+$ ]]; then
        EXITS+=("$2")
      elif [[ "$2" == "not_run" ]]; then
        EXITS+=("null")
      else
        die "--exit must be a non-negative integer or not_run, got '$2'"
      fi
      CMDS+=("$PENDING"); PENDING=""; HAVE_PENDING=0; shift 2 ;;
    -h|--help) usage ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ $HAVE_PENDING -eq 0 ]] || die "--command '${PENDING}' has no matching --exit"
[[ -n "$VERIFIER" && -n "$VERDICT" ]] || usage
case "$VERDICT" in
  pass|pass_with_gaps|fail|unverified) ;;
  *) die "--verdict must be pass, pass_with_gaps, fail or unverified, got '$VERDICT'" ;;
esac

# Git facts. Absent or unborn repository → null, never a guessed value.
BRANCH_JSON=null; COMMIT_JSON=null; DIRTY_JSON=null
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if b="$(git -C "$ROOT" symbolic-ref --short -q HEAD 2>/dev/null)"; then
    BRANCH_JSON="$(json_str "$b")"
  else
    BRANCH_JSON='"(detached)"'
  fi
  if c="$(git -C "$ROOT" rev-parse --verify -q HEAD 2>/dev/null)"; then
    COMMIT_JSON="$(json_str "$c")"
  fi
  # The record itself must not make the next run look dirty.
  if [[ -n "$(git -C "$ROOT" status --porcelain -- . ":(exclude)${REL_OUT}" 2>/dev/null)" ]]; then
    DIRTY_JSON=true
  else
    DIRTY_JSON=false
  fi
fi

COMMANDS_JSON="["
if [[ ${#CMDS[@]} -gt 0 ]]; then
  for i in "${!CMDS[@]}"; do
    [[ $i -eq 0 ]] || COMMANDS_JSON+=","
    COMMANDS_JSON+=$'\n    {"command": '"$(json_str "${CMDS[$i]}")"', "exit_code": '"${EXITS[$i]}"'}'
  done
  COMMANDS_JSON+=$'\n  '
fi
COMMANDS_JSON+="]"

mkdir -p "$(dirname "$OUT")"
TMP_OUT="$(mktemp "${OUT}.XXXXXX")"
trap 'rm -f "$TMP_OUT"' EXIT
cat > "$TMP_OUT" <<JSON
{
  "version": 1,
  "recorded_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "branch": ${BRANCH_JSON},
  "commit": ${COMMIT_JSON},
  "worktree_dirty": ${DIRTY_JSON},
  "verifier": $(json_str "$VERIFIER"),
  "verdict": $(json_str "$VERDICT"),
  "commands": ${COMMANDS_JSON}
}
JSON
mv "$TMP_OUT" "$OUT"
trap - EXIT
echo "last-gate-record: wrote ${OUT} (${VERIFIER} ${VERDICT})"
