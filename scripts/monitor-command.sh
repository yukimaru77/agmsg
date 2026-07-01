#!/usr/bin/env bash
set -euo pipefail

# Print a watch.sh command with a literal session id baked in.
#
# Usage:
#   monitor-command.sh <type> <project_path> [active_name]
#
# Agent instructions should use this before invoking a Monitor tool. Some
# Monitor runtimes do not inherit the agent CLI's session environment, so a
# command containing "$CODEX_THREAD_ID" can start with an empty session id. This
# helper resolves the id in the normal shell first, then prints a shell-quoted
# command line that can be passed to Monitor verbatim.

TYPE="${1:?Usage: monitor-command.sh <type> <project_path> [active_name]}"
PROJECT="${2:?Missing project_path}"
ACTIVE_NAME="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/compat.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/resolve-project.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/instance-id.sh"

session_id=""
case "$TYPE" in
  claude-code) session_id="${CLAUDE_CODE_SESSION_ID:-}" ;;
  codex) session_id="${CODEX_THREAD_ID:-}" ;;
  grok-build) session_id="${GROK_SESSION_ID:-}" ;;
esac
[ -n "$session_id" ] || session_id="agmsg-$(compat_uuidgen | tr 'A-Z' 'a-z')"
session_id="$(agmsg_normalize_instance_id "$session_id" "$TYPE")"

if [ -n "$ACTIVE_NAME" ]; then
  printf '%q %q %q %q %q\n' "$SKILL_DIR/scripts/watch.sh" "$session_id" "$PROJECT" "$TYPE" "$ACTIVE_NAME"
else
  printf '%q %q %q %q\n' "$SKILL_DIR/scripts/watch.sh" "$session_id" "$PROJECT" "$TYPE"
fi
