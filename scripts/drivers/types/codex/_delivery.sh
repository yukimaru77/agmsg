#!/usr/bin/env bash
# codex delivery plug.
#
# Codex follows the same monitor contract as Claude Code:
# SessionStart hook -> Monitor tool -> watch.sh stream.
# Sourced into delivery.sh's context, so emit_monitor_directive is in scope.
# Args: on_enable <mode> <type> <project>.

agmsg_delivery_on_enable() {
  echo "Future sessions: SessionStart hook will auto-launch the watcher."
  emit_monitor_directive "$2" "$3"
}
