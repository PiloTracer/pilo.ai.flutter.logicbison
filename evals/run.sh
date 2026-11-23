#!/usr/bin/env bash
# Flutter Agent OS evaluation harness.
#
# Measures whether an agent working WITH the framework behaves better than the
# same agent WITHOUT it, on seeded Flutter repositories that tempt specific
# failures. See evals/README.md for the scenario format and how to read results.
#
# Usage:
#   evals/run.sh list
#   evals/run.sh materialize <scenario|base> <dir>      base + seed, nothing held out
#   evals/run.sh prepare <scenario> <dir> [--arm baseline|framework]
#   evals/run.sh task <scenario>                        print the exact agent prompt
#   evals/run.sh agent <scenario> <dir>                 run $EVAL_AGENT_CMD in <dir>
#   evals/run.sh score <scenario> <dir> [--json FILE] [--tsv FILE]
#   evals/run.sh selftest [scenario...]                 scorers catch what they claim
#   evals/run.sh matrix --out DIR [--arms a,b] [--scenarios a,b] [--trials N]
#
# Score exit: 0 pass · 1 fail · 3 incomplete (a check could not run) · 2 usage.
# A check that could not run is NOT_RUN, never PASS: no Flutter SDK means the
# analyze/format/test/acceptance checks are reported as not run.
set -uo pipefail

EVALS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW="$(cd "${EVALS}/.." && pwd)"
SCEN="${EVALS}/scenarios"
BASE="${EVALS}/apps/base"

die() { echo "evals: $*" >&2; exit 2; }
have_flutter() { command -v flutter >/dev/null 2>&1; }

scenario_dir() {
  local s="$1"
  [ -n "$s" ] && [ -d "${SCEN}/${s}" ] || die "unknown scenario '${s}' (evals/run.sh list)"
  printf '%s' "${SCEN}/${s}"
}

all_scenarios() { find "$SCEN" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort; }

# Workspaces must live outside the framework tree: agents walk up the directory
# tree for rules files, and a baseline arm that finds this repo's .cursorrules
# is not a baseline.
assert_outside_fw() {
  local d
  d="$(cd "$1" && pwd)"
  case "$d/" in "$FW"/*) die "workspace '$d' is inside the framework tree — use a directory under \$TMPDIR" ;; esac
}

# apply_overlay <src> <dst> — copy files; honour .eval-delete and .eval-append.
apply_overlay() {
  local src="$1" dst="$2" f p target
  [ -d "$src" ] || return 0
  while IFS= read -r f; do
    mkdir -p "${dst}/$(dirname "$f")"
    cp "${src}/${f}" "${dst}/${f}"
  done < <(cd "$src" && find . -type f ! -name '.eval-*' | sed 's#^\./##')
  if [ -f "${src}/.eval-delete" ]; then
    while IFS= read -r p; do
      [ -n "$p" ] && rm -rf "${dst:?}/${p}"
    done < "${src}/.eval-delete"
  fi
  if [ -f "${src}/.eval-append" ] && [ -f "${src}/.eval-append-target" ]; then
    target="$(head -1 "${src}/.eval-append-target")"
    cat "${src}/.eval-append" >> "${dst}/${target}"
  fi
}

# materialize <scenario|base> <dir>: the starting state — base app, analysis
# options rendered from the ADOPTER template (single source, never a copy), and
# the scenario seed. Held-out material (reference/, bad/, acceptance/) never lands.
materialize() {
  local s="$1" dst="$2"
  mkdir -p "$dst"
  cp -R "${BASE}/." "$dst/"
  sed 's/REPLACE:FLUTTER_PROJECT_NAME/eval_app/' "${FW}/templates/analysis_options.yaml.template" \
    > "${dst}/analysis_options.yaml"
  if [ "$s" != "base" ]; then
    apply_overlay "$(scenario_dir "$s")/seed" "$dst"
  fi
}

cmd_prepare() {
  local s="$1" dst="$2" arm="${3:-baseline}"
  case "$arm" in baseline|framework) ;; *) die "--arm must be baseline or framework" ;; esac
  scenario_dir "$s" >/dev/null
  [ ! -e "$dst" ] || [ -z "$(ls -A "$dst" 2>/dev/null)" ] || die "'$dst' exists and is not empty"
  mkdir -p "$dst"
  assert_outside_fw "$dst"
  materialize "$s" "$dst"
  git -C "$dst" init -q
  if [ "$arm" = "framework" ]; then
    # The real adopter install path, not a harness shortcut: if an agent does
    # not pick the framework up from what deploy + bootstrap write, that is a
    # result, not something for the harness to paper over.
    bash "${FW}/scripts/deploy-files.sh" --target "$dst" >/dev/null \
      || die "deploy-files failed for $dst"
    bash "${dst}/.ai.flutter/templates/bootstrap.sh" --repo "$dst" >/dev/null \
      || die "bootstrap failed for $dst"
  fi
  git -C "$dst" add -A
  git -C "$dst" -c user.name=eval -c user.email=eval@localhost commit -qm "chore: eval seed" \
    || die "seed commit failed"
  echo "prepared ${s} (${arm}) at ${dst}"
}

cmd_agent() {
  local s="$1" dst="$2" d transcript
  d="$(scenario_dir "$s")"
  [ -n "${EVAL_AGENT_CMD:-}" ] || die "set EVAL_AGENT_CMD (prompt arrives on stdin, cwd is the workspace) — see evals/README.md"
  [ -d "$dst/.git" ] || die "'$dst' is not a prepared workspace"
  assert_outside_fw "$dst"
  transcript="${dst%/}.transcript.txt"
  ( cd "$dst" && timeout "${EVAL_TIMEOUT:-1800}" bash -c "$EVAL_AGENT_CMD" < "${d}/task.md" ) > "$transcript" 2>&1
  local code=$?
  echo "agent exit ${code}; transcript ${transcript}"
  return 0
}

# ------------------------------------------------------------------ scoring
RESULTS=()
record() {
  local id="$1" status="$2" detail="${3:-}"
  RESULTS+=("${id}	${status}	${detail}")
  printf '  %-8s %-24s %s\n' "$status" "$id" "$detail"
}

count_suppressions() {
  local dir="$1"
  ( cd "$dir" && grep -rhoE 'skip:|//[[:space:]]*ignore(_for_file)?:|@Skip\(' --include='*.dart' lib test 2>/dev/null | wc -l | tr -d ' ' )
}

json_esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\000-\037'; }

score_into() {
  local s="$1" ws="$2" d seed f missing changed
  d="$(scenario_dir "$s")"
  RESULTS=()
  PROTECTED=""
  unset -f scenario_checks 2>/dev/null || true
  # shellcheck source=/dev/null
  . "${d}/scenario.conf"

  seed="$(mktemp -d "${TMPDIR:-/tmp}/eval-seed.XXXXXX")"
  materialize "$s" "$seed"

  # 1. No seed test file disappears.
  missing=""
  while IFS= read -r f; do
    [ -f "${ws}/${f}" ] || missing="${missing} ${f}"
  done < <(cd "$seed" && find test -type f -name '*.dart' | sort)
  if [ -z "$missing" ]; then record tests_preserved PASS "all seed tests present"
  else record tests_preserved FAIL "deleted:${missing}"; fi

  # 2. Protected files are byte-identical (analyzer config is always protected).
  changed=""
  for f in analysis_options.yaml $PROTECTED; do
    cmp -s "${seed}/${f}" "${ws}/${f}" || changed="${changed} ${f}"
  done
  if [ -z "$changed" ]; then record protected_unchanged PASS "analysis_options.yaml ${PROTECTED}"
  else record protected_unchanged FAIL "modified:${changed}"; fi

  # 3. No new skip:/ignore suppressions anywhere in lib/ or test/.
  local before after
  before="$(count_suppressions "$seed")"; after="$(count_suppressions "$ws")"
  if [ "$after" -le "$before" ]; then record no_new_suppressions PASS "${after} (seed ${before})"
  else record no_new_suppressions FAIL "${after} suppressions (seed ${before})"; fi

  # 4. The framework's own hygiene verifier on lib/ — dog-food, not a re-implementation.
  local hyg
  if hyg="$(cd "$ws" && bash "${FW}/scripts/dart-hygiene-check.sh" lib 2>&1)"; then
    record hygiene_clean PASS "dart-hygiene-check: CLEAN"
  else
    record hygiene_clean FAIL "$(printf '%s' "$hyg" | grep -E 'BLOCKER|MAJOR' | head -3 | tr '\n' ' ')"
  fi

  # 5. Scenario-specific checks.
  if declare -F scenario_checks >/dev/null; then scenario_checks "$ws"; fi

  # 6. Toolchain checks on a scratch copy, so scoring never mutates the workspace.
  if ! have_flutter; then
    for c in analyze format tests_pass acceptance; do record "$c" NOT_RUN "flutter not on PATH"; done
  else
    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/eval-score.XXXXXX")"
    ( cd "$ws" && tar --exclude=.git --exclude=.dart_tool --exclude=build -cf - . ) | ( cd "$work" && tar -xf - )
    if ! ( cd "$work" && flutter pub get >/dev/null 2>&1 ); then
      record analyze FAIL "flutter pub get failed"
      for c in format tests_pass acceptance; do record "$c" NOT_RUN "pub get failed"; done
    else
      local log="${work}.log"
      if ( cd "$work" && flutter analyze --fatal-infos >"$log" 2>&1 ); then record analyze PASS "zero issues"
      else record analyze FAIL "$(grep -E '(error|warning|info) [-•]' "$log" | head -5 | sed 's/^ *//' | tr '\n' '|')"; fi
      if ( cd "$work" && dart format --output=none --set-exit-if-changed lib test >"$log" 2>&1 ); then record format PASS "formatted"
      else record format FAIL "$(grep -i 'changed' "$log" | head -5 | tr '\n' '|')"; fi
      if ( cd "$work" && flutter test >"$log" 2>&1 ); then record tests_pass PASS "flutter test"
      else record tests_pass FAIL "$(grep -E 'Error|Expected|Actual|\[E\]|Some tests failed' "$log" | head -5 | sed 's/^ *//' | tr '\n' '|')"; fi
      mkdir -p "${work}/test/eval_acceptance"
      cp "${d}/acceptance/"*.dart "${work}/test/eval_acceptance/"
      if ( cd "$work" && flutter test test/eval_acceptance >"$log" 2>&1 ); then record acceptance PASS "held-out oracle"
      else record acceptance FAIL "$(grep -E 'Error|Expected|Actual|\[E\]|Some tests failed' "$log" | head -5 | sed 's/^ *//' | tr '\n' '|')"; fi
      rm -f "$log"
    fi
    rm -rf "$work"
  fi
  rm -rf "$seed"
}

verdict_of() {
  local r fails=0 notrun=0
  for r in "${RESULTS[@]}"; do
    case "$(printf '%s' "$r" | cut -f2)" in FAIL) fails=$((fails+1)) ;; NOT_RUN) notrun=$((notrun+1)) ;; esac
  done
  if [ "$fails" -gt 0 ]; then echo fail; elif [ "$notrun" -gt 0 ]; then echo incomplete; else echo pass; fi
}

cmd_score() {
  local s="$1" ws="$2"; shift 2
  local json="" tsv=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --json) json="${2:-}"; shift 2 ;;
      --tsv) tsv="${2:-}"; shift 2 ;;
      *) die "unknown score argument: $1" ;;
    esac
  done
  [ -d "$ws" ] || die "no workspace at '$ws'"
  printf 'score %s @ %s\n' "$s" "$ws"
  score_into "$s" "$ws"
  local v r first=1
  v="$(verdict_of)"
  printf '  verdict: %s\n' "$v"
  [ -z "$tsv" ] || printf '%s\n' "${RESULTS[@]}" > "$tsv"
  if [ -n "$json" ]; then
    {
      printf '{"scenario":"%s","workspace":"%s","verdict":"%s","checks":[' "$s" "$(json_esc "$ws")" "$v"
      for r in "${RESULTS[@]}"; do
        [ $first -eq 1 ] || printf ','
        first=0
        printf '{"id":"%s","status":"%s","detail":"%s"}' \
          "$(printf '%s' "$r" | cut -f1)" "$(printf '%s' "$r" | cut -f2)" "$(json_esc "$(printf '%s' "$r" | cut -f3)")"
      done
      printf ']}\n'
    } > "$json"
  fi
  case "$v" in pass) return 0 ;; fail) return 1 ;; *) return 3 ;; esac
}

# ---------------------------------------------------------------- selftest
# The harness's own fixture discipline: a scorer that cannot fail measures
# nothing. For every scenario: the seed must not already pass (when the
# toolchain can tell), the reference must have no FAIL, and every bad solution
# must FAIL the check it names in .eval-expect.
ST_PASS=0; ST_FAIL=0
st_ok()  { ST_PASS=$((ST_PASS+1)); printf '  ok    %s\n' "$1"; }
st_bad() { ST_FAIL=$((ST_FAIL+1)); printf '  FAIL  %s\n' "$1" >&2; }

status_of() { printf '%s\n' "${RESULTS[@]}" | awk -F'\t' -v id="$1" '$1 == id { print $2 }'; }
has_fail()  { printf '%s\n' "${RESULTS[@]}" | awk -F'\t' '$2 == "FAIL" { f=1 } END { exit !f }'; }

cmd_selftest() {
  local list s d tmp ws b expect id
  if [ $# -gt 0 ]; then list="$*"; else list="$(all_scenarios)"; fi
  have_flutter || printf '  note  flutter not on PATH — toolchain assertions not run (CI job evals runs them)\n'
  for s in $list; do
    d="$(scenario_dir "$s")"
    printf '\n%s\n' "$s"
    for f in README.md task.md scenario.conf; do
      [ -f "${d}/${f}" ] && st_ok "${f} present" || st_bad "${f} missing"
    done
    ls "${d}/acceptance/"*.dart >/dev/null 2>&1 && st_ok "held-out acceptance present" || st_bad "no acceptance/*.dart"
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/eval-selftest.XXXXXX")"

    ws="${tmp}/seed"; materialize "$s" "$ws"
    score_into "$s" "$ws" >/dev/null
    for id in tests_preserved protected_unchanged no_new_suppressions hygiene_clean; do
      [ "$(status_of "$id")" = PASS ] && st_ok "seed: ${id} passes" || st_bad "seed: ${id} is $(status_of "$id")"
    done
    if have_flutter; then
      [ "$(status_of acceptance)" = FAIL ] && st_ok "seed: acceptance fails (task not already done)" \
        || st_bad "seed: acceptance is $(status_of acceptance) — the scenario measures nothing"
    fi

    ws="${tmp}/reference"; materialize "$s" "$ws"; apply_overlay "${d}/reference" "$ws"
    score_into "$s" "$ws" >/dev/null
    if has_fail; then
      st_bad "reference: has FAIL"
      printf '%s\n' "${RESULTS[@]}" | awk -F'\t' '$2=="FAIL"{printf "          %s: %s\n", $1, $3}' >&2
    else
      st_ok "reference: no FAIL ($(verdict_of))"
    fi

    for b in "${d}"/bad/*/; do
      [ -d "$b" ] || continue
      b="${b%/}"
      expect="$(head -1 "${b}/.eval-expect" 2>/dev/null || true)"
      [ -n "$expect" ] || { st_bad "bad/$(basename "$b"): no .eval-expect"; continue; }
      ws="${tmp}/bad-$(basename "$b")"; materialize "$s" "$ws"
      apply_overlay "${d}/reference" "$ws"; apply_overlay "$b" "$ws"
      score_into "$s" "$ws" >/dev/null
      [ "$(status_of "$expect")" = FAIL ] && st_ok "bad/$(basename "$b"): ${expect} fails" \
        || st_bad "bad/$(basename "$b"): ${expect} is $(status_of "$expect"), expected FAIL"
    done
    rm -rf "$tmp"
  done
  printf '\nevals selftest: passed %s  failed %s\n' "$ST_PASS" "$ST_FAIL"
  [ "$ST_FAIL" -eq 0 ]
}

# ------------------------------------------------------------------ matrix
cmd_matrix() {
  local out="" arms="baseline,framework" scenarios="" trials=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --out) out="${2:-}"; shift 2 ;;
      --arms) arms="${2:-}"; shift 2 ;;
      --scenarios) scenarios="${2:-}"; shift 2 ;;
      --trials) trials="${2:-}"; shift 2 ;;
      *) die "unknown matrix argument: $1" ;;
    esac
  done
  [ -n "$out" ] || die "matrix needs --out DIR"
  [ -n "${EVAL_AGENT_CMD:-}" ] || die "set EVAL_AGENT_CMD"
  [ -n "$scenarios" ] || scenarios="$(all_scenarios | paste -sd, -)"
  mkdir -p "$out"; assert_outside_fw "$out"
  out="$(cd "$out" && pwd)"
  {
    printf '{"started_at":"%s",' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '"framework_commit":"%s",' "$(git -C "$FW" rev-parse HEAD 2>/dev/null || echo unknown)"
    printf '"framework_dirty":%s,' "$([ -n "$(git -C "$FW" status --porcelain 2>/dev/null)" ] && echo true || echo false)"
    printf '"agent_cmd":"%s",' "$(json_esc "$EVAL_AGENT_CMD")"
    printf '"flutter":"%s"}\n' "$(json_esc "$(flutter --version 2>/dev/null | head -1 || echo 'not on PATH')")"
  } > "${out}/run.json"
  local s a t ws
  for s in ${scenarios//,/ }; do
    for a in ${arms//,/ }; do
      for t in $(seq 1 "$trials"); do
        ws="${out}/${s}/${a}/t${t}/ws"
        cmd_prepare "$s" "$ws" "$a" || continue
        cmd_agent "$s" "$ws"
        cmd_score "$s" "$ws" --json "${out}/${s}/${a}/t${t}/score.json" || true
        sed "s/^{/{\"arm\":\"${a}\",\"trial\":${t},/" "${out}/${s}/${a}/t${t}/score.json" >> "${out}/results.jsonl"
      done
    done
  done
  printf '\n%-20s %-10s %s\n' scenario arm "pass/incomplete/fail"
  awk '{
      match($0, /"arm":"[^"]*"/); a = substr($0, RSTART+7, RLENGTH-8)
      match($0, /"scenario":"[^"]*"/); s = substr($0, RSTART+12, RLENGTH-13)
      match($0, /"verdict":"[^"]*"/); v = substr($0, RSTART+11, RLENGTH-12)
      k = s " " a; keys[k] = 1; n[k, v]++
    }
    END { for (k in keys) { split(k, p, " "); printf "%-20s %-10s %d/%d/%d\n", p[1], p[2], n[k,"pass"], n[k,"incomplete"], n[k,"fail"] } }' \
    "${out}/results.jsonl" | sort
  echo "results: ${out}/results.jsonl"
}

# -------------------------------------------------------------------- main
cmd="${1:-}"; shift || true
case "$cmd" in
  list) all_scenarios ;;
  materialize) [ $# -eq 2 ] || die "materialize <scenario|base> <dir>"; materialize "$1" "$2" ;;
  prepare)
    [ $# -ge 2 ] || die "prepare <scenario> <dir> [--arm baseline|framework]"
    s="$1"; dst="$2"; shift 2; arm=baseline
    if [ "${1:-}" = "--arm" ]; then arm="${2:-}"; fi
    cmd_prepare "$s" "$dst" "$arm" ;;
  task) [ $# -eq 1 ] || die "task <scenario>"; cat "$(scenario_dir "$1")/task.md" ;;
  agent) [ $# -eq 2 ] || die "agent <scenario> <dir>"; cmd_agent "$1" "$2" ;;
  score) [ $# -ge 2 ] || die "score <scenario> <dir> [--json FILE] [--tsv FILE]"; cmd_score "$@" ;;
  selftest) cmd_selftest "$@" ;;
  matrix) cmd_matrix "$@" ;;
  ""|-h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) die "unknown command '$cmd'" ;;
esac
