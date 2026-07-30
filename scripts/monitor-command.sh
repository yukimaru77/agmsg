#!/usr/bin/env bash
set -euo pipefail

# Print a watch.sh command with a literal session id baked in. Monitor workers
# do not necessarily inherit the parent agent's session environment.
# Usage: monitor-command.sh [--session-id <id>] <type> <project_path> [active_name]

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

if [ -n "$SESSION_ID_OVERRIDE" ]; then
  session_id="$SESSION_ID_OVERRIDE"
else
  session_id="$("$SCRIPT_DIR/session-id.sh" "$TYPE" "$PROJECT")"
fi

if [ -n "$ACTIVE_NAME" ]; then
  printf '%q %q %q %q %q\n' "$SKILL_DIR/scripts/watch.sh" "$session_id" "$PROJECT" "$TYPE" "$ACTIVE_NAME"
else
  printf '%q %q %q %q\n' "$SKILL_DIR/scripts/watch.sh" "$session_id" "$PROJECT" "$TYPE"
fi
