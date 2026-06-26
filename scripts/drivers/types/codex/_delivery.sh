#!/usr/bin/env bash
# codex delivery plug.
#
# codex keeps the default JSON event-hooks apply (agmsg_delivery_apply). By
# default, monitor mode uses the runtime's native Monitor tool via the generic
# SessionStart directive. The legacy app-server bridge remains available only
# when codex-monitor.sh opts in with AGMSG_CODEX_BRIDGE=1. Sourced into
# delivery.sh's context, so SKILL_DIR, agmsg_resolve_node, emit_monitor_directive,
# kill_all_watchers, and stop_codex_bridge are in scope.
# Args (both hooks): on_enable <mode> <type> <project>; on_disable <type> <project>.

agmsg_delivery_on_enable() {
  local mode="$1" type="$2" project="$3"
  [ "$mode" = "monitor" ] || return 0

  if [ "${AGMSG_CODEX_BRIDGE:-}" = "1" ]; then
    echo "Codex legacy app-server bridge mode is enabled for this project."
    # Node preflight: the bridge (codex-bridge.js) is a Node program, so without
    # Node it silently never starts — flag it at enable time. Resolve via the same
    # path the runtime uses (lib/node.sh). AGMSG_NODE / AGMSG_CODEX_NODE override.
    local codex_node
    codex_node="$(agmsg_resolve_node)"
    if ! command -v "$codex_node" >/dev/null 2>&1 && [ ! -x "$codex_node" ]; then
      echo "WARNING: Node.js ('$codex_node') was not found. The Codex bridge needs Node —"
      echo "  monitor delivery will NOT start until Node is installed (or set AGMSG_NODE)."
    fi
    echo "Future sessions: launch through $SKILL_DIR/scripts/drivers/types/codex/codex-monitor.sh to use the legacy bridge."
    return 0
  fi

  local stopped
  stopped=$(stop_codex_bridge "$project")
  if [ "${stopped:-0}" -gt 0 ]; then
    echo "Stopped $stopped legacy Codex bridge process(es) for this project."
  fi
  echo "Future sessions: SessionStart hook will auto-launch the watcher."
  emit_monitor_directive "$type" "$project"
}

agmsg_delivery_on_disable() {
  local type="$1" project="$2"
  kill_all_watchers "$project" "$type" >/dev/null 2>&1 || true

  local stopped
  stopped=$(stop_codex_bridge "$project")
  if [ "${stopped:-0}" -gt 0 ]; then
    echo "Stopped $stopped Codex bridge process(es) for this project and cleaned their run files."
  fi
}
