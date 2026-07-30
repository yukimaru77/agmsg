#!/usr/bin/env bash
set -euo pipefail

# Resolve a monitor-capable agent's current agmsg instance id.
# Usage: session-id.sh <type> <project_path>

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

if [ "$(agmsg_type_get "$TYPE" monitor 2>/dev/null || true)" != "yes" ]; then
  echo "Unsupported monitor type: $TYPE" >&2
  exit 2
fi

session_id="${AGMSG_SESSION_ID:-}"
agent_pid="$(agmsg_agent_pid "$TYPE" 2>/dev/null || true)"

# SessionStart records the authoritative, already-normalized instance id here.
if [ -z "$session_id" ] && [ -n "$agent_pid" ]; then
  state_file="$SKILL_DIR/run/cc-instance.$agent_pid"
  if [ -f "$state_file" ]; then
    session_id="$(head -1 "$state_file" 2>/dev/null || true)"
  fi
fi

if [ -z "$session_id" ]; then
  case "$TYPE" in
    claude-code) session_id="${CLAUDE_CODE_SESSION_ID:-}" ;;
    codex) session_id="${CODEX_THREAD_ID:-}" ;;
    grok-build) session_id="${GROK_SESSION_ID:-}" ;;
  esac
fi

# Manual skill invocation can precede SessionStart. A pid-based fallback is
# stable for this agent process and lets the later hook replace it cleanly.
if [ -z "$session_id" ]; then
  if [ -n "$agent_pid" ]; then
    session_id="agmsg-$TYPE-$agent_pid"
  else
    session_id="agmsg-$(compat_uuidgen | tr 'A-Z' 'a-z')"
  fi
fi

instance_id="$(agmsg_normalize_instance_id "$session_id" "$TYPE" 2>/dev/null)"

if [ -n "$agent_pid" ]; then
  mkdir -p "$SKILL_DIR/run" 2>/dev/null || true
  printf '%s\n' "$instance_id" > "$SKILL_DIR/run/cc-instance.$agent_pid"
fi

printf '%s\n' "$instance_id"
