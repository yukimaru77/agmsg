#!/usr/bin/env bash
set -euo pipefail

# Optional Codex entrypoint shim for agmsg monitor mode.
#
# This shim is kept only for backwards compatibility with users who still have
# ~/.agents/bin/codex or a shell function pointing at agmsg. Native Codex monitor
# mode no longer routes launches through codex-monitor.sh; delivery is handled by
# the normal SessionStart -> Monitor -> watch.sh path. Therefore every command is
# passed straight through to the real Codex binary.

if [ "${AGMSG_CODEX_SHIM_WRAPPER:-}" = "1" ] && [ -n "${AGMSG_CODEX_SHIM_SCRIPT_DIR:-}" ]; then
  SCRIPT_DIR="$AGMSG_CODEX_SHIM_SCRIPT_DIR"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

is_agmsg_wrapper() {
  [ -f "$1" ] && grep -q "Optional Codex entrypoint shim for agmsg monitor mode" "$1" 2>/dev/null
}

resolve_real_codex() {
  if [ -n "${AGMSG_REAL_CODEX:-}" ]; then
    printf '%s\n' "$AGMSG_REAL_CODEX"
    return 0
  fi

  local self_dir self_path shim_target path_dir candidate candidate_dir candidate_path
  self_dir="$(cd "$(dirname "$0")" && pwd)"
  self_path="$self_dir/$(basename "$0")"
  shim_target="${AGMSG_CODEX_SHIM_TARGET:-}"

  local old_ifs="$IFS"
  IFS=:
  for path_dir in $PATH; do
    IFS="$old_ifs"
    [ -n "$path_dir" ] || path_dir="."
    candidate="$path_dir/codex"
    if [ -x "$candidate" ]; then
      candidate_dir="$(cd "$(dirname "$candidate")" 2>/dev/null && pwd || true)"
      [ -n "$candidate_dir" ] || continue
      candidate_path="$candidate_dir/$(basename "$candidate")"
      if [ "$candidate_path" != "$self_path" ] \
        && [ "$candidate_path" != "$shim_target" ] \
        && ! is_agmsg_wrapper "$candidate_path"; then
        printf '%s\n' "$candidate_path"
        return 0
      fi
    fi
    IFS=:
  done
  IFS="$old_ifs"

  echo "agmsg codex shim: real codex not found on PATH" >&2
  return 1
}

real_codex="$(resolve_real_codex)"
exec "$real_codex" "$@"
