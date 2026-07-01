#!/usr/bin/env bash
# codex delivery plug.
#
# Codex follows the same monitor contract as Claude Code:
# SessionStart hook -> Monitor tool -> watch.sh stream.
# Sourced into delivery.sh's context, so emit_monitor_directive is in scope.
# Args: on_enable <mode> <type> <project>.

agmsg_delivery_on_enable() {
  if [ "${AGMSG_CODEX_BRIDGE:-}" != "1" ]; then
    stop_codex_bridge "$3" >/dev/null 2>&1 || true
  fi
  echo "Future sessions: SessionStart hook will auto-launch the watcher."
  emit_monitor_directive "$2" "$3"
}

agmsg_delivery_on_disable() {
  kill_all_watchers "$2" "$1" >/dev/null 2>&1 || true
  stop_codex_bridge "$2" >/dev/null 2>&1 || true
}
