#!/usr/bin/env bash
set -euo pipefail

# Resolve a monitor-capable agent's current agmsg instance id.
#
# Usage:
#   session-id.sh <type> <project_path>
#
# The printed id is safe to pass to actas-claim.sh/reset.sh and to watch.sh.
# It is normalized the same way watch.sh normalizes its first argument, so a
# caller can resolve it once and reuse it across a role switch without depending
# on the Monitor runtime inheriting the agent CLI's session environment.

TYPE="${1:?Usage: session-id.sh <type> <project_path>}"
PROJECT="${2:?Missing project_path}"

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

session_id="${AGMSG_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  case "$TYPE" in
    claude-code) session_id="${CLAUDE_CODE_SESSION_ID:-}" ;;
    codex) session_id="${CODEX_THREAD_ID:-}" ;;
  esac
fi

if [ -z "$session_id" ]; then
  agent_pid="$(agmsg_agent_pid "$TYPE" 2>/dev/null || true)"
  if [ -n "$agent_pid" ]; then
    session_id="agmsg-$TYPE-$agent_pid"
  else
    session_id="agmsg-$(compat_uuidgen | tr 'A-Z' 'a-z')"
    printf 'agmsg: generated fallback session id for type=%s project=%s; cleanup may require session-end/off if no agent pid is visible\n' "$TYPE" "$PROJECT" >&2
  fi
fi

agmsg_normalize_instance_id "$session_id" "$TYPE"
printf '\n'
