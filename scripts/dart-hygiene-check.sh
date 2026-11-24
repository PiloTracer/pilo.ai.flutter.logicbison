#!/usr/bin/env bash
# Dart/Flutter hygiene patterns the analyzer does not catch.
#
# Fast, dependency-free, and safe to run on a diff or the whole tree. Every hit
# is a finding with a file and a line; nothing is auto-fixed.
#
# Usage: dart-hygiene-check.sh [file|dir ...]    (default: all .dart under lib/)
# Exit: 0 clean · 1 findings · 2 usage

set -uo pipefail

FINDINGS=0
FILES=()

collect() { # collect <dir>
  while IFS= read -r f; do FILES+=("$f"); done < <(
    find "$1" -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' \
         ! -name '*.mocks.dart' 2>/dev/null | sort
  )
}

if [ $# -gt 0 ]; then
  for f in "$@"; do
    if [ -d "$f" ]; then
      collect "$f"
    elif [ -f "$f" ]; then
      case "$f" in *.dart) FILES+=("$f") ;; esac
    fi
  done
else
  collect lib
fi

[ ${#FILES[@]} -eq 0 ] && { echo "no Dart files to check"; exit 0; }

report() {
  FINDINGS=$((FINDINGS+1))
  printf '  %-8s %s:%s  %s\n' "$1" "$2" "$3" "$4" >&2
}

# Theme/token files DEFINE raw values; tests construct fixtures. Both are
# exempt from the value scans below — at path level, because an exemption that
# only inspects line content would fire inside the very files where a palette
# or spacing scale is declared, and a check that fires there gets switched off.
THEME_PATHS='(^|/)theme/|_theme\.dart|color_scheme|typography\.dart|spacing\.dart|radii\.dart|durations\.dart|(^|/)(test|integration_test)/|_test\.dart'

# scan <severity> <regex> <message> [exclude-regex] [in-comments]
#
# Comment-only lines are skipped by default so that a commented-out `print(` is
# not reported as live code. Scans that deliberately target comments (TODO,
# ignore directives, commented-out code) must pass `in-comments`, or they find
# nothing at all.
#
# The exclude regex applies at two levels: a file whose PATH matches is skipped
# entirely (the theme exemptions above), and a matching LINE is skipped
# individually (e.g. an ignore directive carrying its reason on the same line).
scan() {
  local sev="$1" re="$2" msg="$3" excl="${4:-}" incomments="${5:-}"
  for f in "${FILES[@]}"; do
    if [ -n "$excl" ] && grep -qE "$excl" <<< "$f"; then continue; fi
    while IFS=: read -r line content; do
      [ -z "$line" ] && continue
      if [ -z "$incomments" ]; then
        case "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" in '//'*) continue ;; esac
      fi
      if [ -n "$excl" ] && grep -qE "$excl" <<< "$content"; then continue; fi
      report "$sev" "$f" "$line" "$msg"
    done < <(grep -nE "$re" "$f" 2>/dev/null)
  done
}

printf '\nHygiene scan (%s files)\n\n' "${#FILES[@]}"

scan BLOCKER '(^|[^a-zA-Z_.])print\(' \
     'print() in committed code — use the project logger'

scan BLOCKER 'debugPrint\(' \
     'debugPrint() left in code'

scan BLOCKER 'Color\(0x[0-9a-fA-F]{8}\)' \
     'hardcoded colour literal — colours come from the theme' \
     "$THEME_PATHS"

# UI craft (UI_CRAFT_STANDARD): the values a widget must take from the theme.
# A `padding: 13` or a `Colors.blue` in a diff is the cheap signal made visible.
scan BLOCKER 'Colors\.[a-zA-Z]+' \
     'factory palette colour — colours come from the theme (UI_CRAFT §4)' \
     "$THEME_PATHS|Colors\.transparent"

# A digit counts only as a direct argument: not inside a nested call
# (`child: bar(1)`) and not inside an identifier (`spacing.x2`), both of which
# were false positives that push teams to switch the scan off.
scan MAJOR '(EdgeInsets\.(all|only|symmetric|fromLTRB)|SizedBox|Gap)\(([^()]*[^A-Za-z0-9_.()])?[0-9]' \
     'raw spacing literal — spacing comes from the theme scale (UI_CRAFT §2)' \
     "$THEME_PATHS"

scan MAJOR 'fontSize: *[0-9]' \
     'fontSize literal — text styles come from the TextTheme (UI_CRAFT §3)' \
     "$THEME_PATHS"

# API currency (resources/flutter-api-currency.md): APIs a model's training data
# still favours. Removed ones do not compile (BLOCKER); deprecated ones fail the
# gate under --fatal-infos or lose behaviour (MAJOR). Only patterns that are
# unambiguous without type information are scanned here — the rest belong to the
# analyzer's deprecated_member_use. Every message names the replacement, because
# an agent told only "deprecated" tends to invent a third API.
W='[^A-Za-z0-9_]'  # word boundary without \b (not portable to every grep -E)

scan BLOCKER "(^|$W)(FlatButton|RaisedButton|OutlineButton)($W|\$)" \
     'removed API — use TextButton / FilledButton / OutlinedButton (api-currency)'

scan BLOCKER '[tT]extTheme\??\.(headline[1-6]|subtitle[12]|bodyText[12]|caption|overline|button)([^A-Za-z0-9_]|$)' \
     'removed TextTheme name — use display*/headline*/title*/body*/label* roles (api-currency)'

scan BLOCKER '\.(primaryVariant|secondaryVariant)([^A-Za-z0-9_]|$)|[tT]heme(\.of\([a-z]*\))?\.accentColor' \
     'removed theme colour — use ColorScheme roles (primaryContainer, secondary…) (api-currency)'

scan BLOCKER 'Scaffold\.of\([^)]*\)\.showSnackBar' \
     'removed API — use ScaffoldMessenger.of(context).showSnackBar (api-currency)'

scan MAJOR '\.withOpacity\(' \
     'deprecated withOpacity — use .withValues(alpha: …) (api-currency)'

scan MAJOR "(^|$W)WillPopScope($W|\$)|onWillPop:|onPopInvoked:" \
     'deprecated pop API (breaks Android predictive back) — use PopScope(canPop:, onPopInvokedWithResult:) (api-currency)'

scan MAJOR "(^|$W)MaterialState" \
     'deprecated MaterialState* — use the WidgetState* equivalent (api-currency)'

# @Preview(textScaleFactor: …) is the widget-preview API's current parameter.
scan MAJOR '[tT]extScaleFactor' \
     'deprecated textScaleFactor — use textScaler / MediaQuery.textScalerOf (api-currency)' \
     'Preview\('

scan MAJOR '[sS]cheme\??\.(background|onBackground|surfaceVariant)([^A-Za-z0-9_]|$)' \
     'deprecated ColorScheme role — use surface / onSurface / surfaceContainerHighest (api-currency)'

scan MAJOR "(^|$W)ButtonBar(ThemeData)?($W|\$)" \
     'deprecated ButtonBar — use OverflowBar (api-currency)'

scan MAJOR "(^|$W)(RawKeyboardListener|RawKeyEvent|RawKeyDownEvent|RawKeyUpEvent|RawKeyboard)($W|\$)|(^|$W)onKey:" \
     'deprecated raw key API — use KeyboardListener / KeyEvent / HardwareKeyboard / onKeyEvent (api-currency)'

scan MAJOR "(^|$W)(ui|instance|binding)\.window($W|\$)|\.fromWindow(Padding)?\(" \
     'deprecated single-window API — use View.of(context) / fromView / fromViewPadding (api-currency)'

scan MAJOR 'SemanticsService\.announce\(' \
     'deprecated SemanticsService.announce — use Semantics(liveRegion: true) or sendAnnouncement(View.of(context), …) (api-currency)'

scan MAJOR "dialogBackgroundColor|(^|$W)ExpansionTileController($W|\$)" \
     'deprecated API — use DialogThemeData(backgroundColor:) / ExpansibleController (api-currency)'

scan MAJOR '// *ignore(_for_file)?:' \
     'analyzer suppression — needs a linked ADR or a reason on the same line' \
     'ignore(_for_file)?: *[^ ]+ +[-—] ' \
     in-comments

# grep -E has no lookahead: match TODO not followed by '(' directly.
scan MAJOR 'TODO([^(]|$)' \
     'TODO without an owner — use TODO(owner): description' \
     '' in-comments

scan MAJOR "'http://" \
     'cleartext http:// URL'

scan MAJOR 'catch *\( *\) *\{' \
     'bare catch'

scan MAJOR 'catch *\([a-zA-Z_]+ *\) *\{ *\}' \
     'empty catch block — swallowed exception'

scan MAJOR 'Future\.delayed\(' \
     'Future.delayed — if this is synchronisation, it is a race condition' \
     '(test|_test\.dart)'

scan MAJOR 'MediaQuery\.of\(context\)\.size' \
     'MediaQuery size used for layout — prefer LayoutBuilder and constraints'

scan MINOR '^[[:space:]]*//[[:space:]]*(final|var|const|return|if|for|while|await|import)[[:space:](]' \
     'commented-out code — git remembers' \
     '' in-comments

scan MINOR 'ListView\( *$' \
     'non-builder ListView — verify the child count is bounded'

# Layer purity: Flutter imports inside domain/
# Test trees mirror lib/ paths; they exercise layers — they are not the product graph.
for f in "${FILES[@]}"; do
  case "$f" in
    test/*|*/test/*) continue ;;
  esac
  case "$f" in
    */domain/*)
      while IFS=: read -r line _; do
        [ -n "$line" ] && report BLOCKER "$f" "$line" 'Flutter/UI-library import inside domain/ — layer violation (FLS-03)'
      done < <(grep -nE "^import 'package:(flutter|material_ui|cupertino_ui)/" "$f" 2>/dev/null | cut -d: -f1)
      ;;
  esac
done

# Repository → repository imports. The most common architectural violation, and
# the one that turns a layered codebase into a graph. A repository needing two
# sources composes services; logic needing two repositories belongs in the
# ViewModel or a use case.
for f in "${FILES[@]}"; do
  case "$f" in
    test/*|*/test/*) continue ;;
  esac
  case "$f" in
    *_repository.dart|*_repository_impl.dart|*/repositories/*)
      self="$(basename "$f" .dart)"
      # Interfaces this file implements, as snake_case file stems
      # (`implements UserRepository` -> user_repository). Importing one of those
      # is an implementation depending on its own contract, whatever the file is
      # named (in_memory_*, fake_*, remote_*), not a repository-to-repository edge.
      own="$(grep -oE 'implements +[A-Z][A-Za-z0-9_]*( *, *[A-Z][A-Za-z0-9_]*)*' "$f" 2>/dev/null \
             | sed -e 's/^implements *//' | tr ',' '\n' | tr -d ' ' \
             | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')"
      while IFS=: read -r line content; do
        [ -n "$line" ] || continue
        # An implementation importing its own interface is correct, not a violation.
        grep -qE "${self%_impl}\.dart" <<< "$content" && continue
        stem="$(printf '%s' "$content" | sed -nE "s#.*/([a-z0-9_]+)\.dart'.*#\1#p; s#^import '([a-z0-9_]+)\.dart'.*#\1#p" | head -1)"
        if [ -n "$stem" ] && grep -qx "$stem" <<< "$own"; then continue; fi
        report BLOCKER "$f" "$line" 'repository imports another repository — compose in the ViewModel or a use case (FLS-03)'
      done < <(grep -nE "^import .*(repositories/|_repository)\.?.*\.dart'" "$f" 2>/dev/null)
      ;;
  esac
done

# Widgets reaching past the ViewModel into the data layer. The boundary exists
# so the view cannot do this; an import is the proof it happened.
# Composition roots under presentation/ (e.g. *_providers.dart) wire interfaces
# to implementations — that is DI, not a widget reaching past the ViewModel.
for f in "${FILES[@]}"; do
  case "$f" in
    test/*|*/test/*) continue ;;
    *_providers.dart|*_provider.dart|*/di/*) continue ;;
  esac
  case "$f" in
    */presentation/*|*_view.dart|*_screen.dart|*_page.dart)
      while IFS=: read -r line _; do
        [ -n "$line" ] && report BLOCKER "$f" "$line" 'UI imports the data layer — go through the ViewModel (FLS-03)'
      done < <(grep -nE "^import .*(/data/|_api_client|_service\.dart|/services/)" "$f" 2>/dev/null | cut -d: -f1)
      ;;
  esac
done

# Secrets heuristics (never echo the value)
for f in "${FILES[@]}"; do
  while IFS=: read -r line _; do
    [ -n "$line" ] && report BLOCKER "$f" "$line" 'possible hardcoded credential — verify and rotate if real'
  done < <(grep -nEi "(api[_-]?key|secret|password|token|bearer) *[:=] *['\"][A-Za-z0-9_\-]{16,}" "$f" 2>/dev/null | cut -d: -f1)
done

printf '\nfindings: %s\n' "$FINDINGS"
[ "$FINDINGS" -eq 0 ] && { printf 'dart-hygiene-check: CLEAN\n'; exit 0; }
printf 'dart-hygiene-check: FINDINGS\n'
exit 1
