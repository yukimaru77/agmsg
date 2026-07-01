#!/usr/bin/env bash
set -euo pipefail

# Print a watch.sh command with a literal session id baked in.
#
# Usage:
#   monitor-command.sh [--session-id <id>] <type> <project_path> [active_name]
#
# Agent instructions should use this before invoking a Monitor tool. Some
# Monitor runtimes do not inherit the agent CLI's session environment, so a
# command containing "$CODEX_THREAD_ID" can start with an empty session id. This
# helper resolves the id in the normal shell first, then prints a shell-quoted
# command line that can be passed to Monitor verbatim.

SESSION_ID_OVERRIDE=""
if [ "${1:-}" = "--session-id" ]; then
  SESSION_ID_OVERRIDE="${2:?Missing session id for --session-id}"
  shift 2
fi

TYPE="${1:?Usage: monitor-command.sh [--session-id <id>] <type> <project_path> [active_name]}"
PROJECT="${2:?Missing project_path}"
ACTIVE_NAME="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/compat.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/type-registry.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/resolve-project.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/instance-id.sh"

if [ "$(agmsg_type_get "$TYPE" monitor 2>/dev/null || true)" != "yes" ]; then
  echo "Unsupported monitor type: $TYPE" >&2
  exit 2
fi

if [ -n "$SESSION_ID_OVERRIDE" ]; then
  session_id="$(agmsg_normalize_instance_id "$SESSION_ID_OVERRIDE" "$TYPE")"
else
  session_id="$("$SCRIPT_DIR/session-id.sh" "$TYPE" "$PROJECT")"
fi

if [ -n "$ACTIVE_NAME" ]; then
  printf '%q %q %q %q %q\n' "$SKILL_DIR/scripts/watch.sh" "$session_id" "$PROJECT" "$TYPE" "$ACTIVE_NAME"
else
  printf '%q %q %q %q\n' "$SKILL_DIR/scripts/watch.sh" "$session_id" "$PROJECT" "$TYPE"
fi
