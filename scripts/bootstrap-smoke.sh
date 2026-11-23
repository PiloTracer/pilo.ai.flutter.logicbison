#!/usr/bin/env bash
# Smoke: templates/bootstrap.sh in a clean temp repo — required scaffolding exists.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flutter-bootstrap-smoke.XXXXXX")"
trap 'rm -rf "${TMP}"' EXIT

git -C "${TMP}" init -q

BS="${REPO_ROOT}/templates/bootstrap.sh"
[[ -f "${BS}" ]] || { echo "bootstrap-smoke: missing templates/bootstrap.sh" >&2; exit 1; }

bash "${BS}" --repo "${TMP}" >/dev/null

for f in \
  .work.flutter/context/HANDOFF_FLUTTER.md \
  .work.flutter/plans/NEXT_FLUTTER.md \
  .cursorrules
do
  [[ -s "${TMP}/${f}" ]] || { echo "bootstrap-smoke: missing or empty ${f}" >&2; exit 1; }
done

echo "bootstrap-smoke: OK"
