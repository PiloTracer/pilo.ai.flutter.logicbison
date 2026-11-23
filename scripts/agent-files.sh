#!/usr/bin/env bash
# Agent-file pointers — sourced by deploy-basic.sh and deploy-files.sh.
#
# Why: the operating contract lives in .cursorrules, which Cursor loads and
# most other agents do not. Claude Code loads CLAUDE.md; Codex, opencode and a
# growing set of CLIs load AGENTS.md. Without a pointer in those files the
# framework is installed but invisible to every non-Cursor agent.
#
# Contract: merge, never clobber. A marker-delimited block is appended to an
# existing file, a missing file is created, and an already-registered file is
# left alone — the same rule the installers apply to .cursorrules.
#
# write_agent_pointers <target> <skills-path-for-display> <dry:0|1>

AGENT_PTR_BEGIN='<!-- FLUTTER_AGENT_OS_BEGIN -->'
AGENT_PTR_END='<!-- FLUTTER_AGENT_OS_END -->'

_agent_ptr_block() {
  local file="$1" skills="$2"
  printf '%s\n' "$AGENT_PTR_BEGIN"
  printf '## Flutter Agent OS\n\n'
  if [ "$file" = "CLAUDE.md" ]; then
    # Claude Code expands @path imports in CLAUDE.md, so the contract is loaded
    # verbatim rather than paraphrased.
    printf '@.cursorrules\n\n'
  fi
  printf 'This repository uses Flutter Agent OS. The binding operating contract is the Flutter block in `.cursorrules`: read it before any change and follow it as if it were written in this file. It is not Cursor-specific.\n\n'
  printf -- '- Entry point: `@flutter-director - <what you want>` (skills: `%s`)\n' "$skills"
  printf -- '- Project memory: `.work.flutter/` (`NEXT_FLUTTER.md`, `HANDOFF_FLUTTER.md`)\n'
  printf '%s\n' "$AGENT_PTR_END"
}

write_agent_pointers() {
  local target="$1" skills="$2" dry="${3:-0}" name path
  for name in AGENTS.md CLAUDE.md; do
    path="${target}/${name}"
    if [ -f "$path" ] && grep -qF "$AGENT_PTR_BEGIN" "$path"; then
      echo "  keep      ${name} (Flutter pointer already registered)"
    elif [ -f "$path" ]; then
      if [ "$dry" -eq 0 ]; then
        printf '\n' >> "$path"
        _agent_ptr_block "$name" "$skills" >> "$path"
      fi
      echo "  append    ${name} (Flutter pointer; existing content preserved)"
    else
      [ "$dry" -eq 0 ] && _agent_ptr_block "$name" "$skills" > "$path"
      echo "  write     ${name}"
    fi
  done
}
