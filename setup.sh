#!/usr/bin/env bash
set -euo pipefail

# Which repo/ref to install. This fork branch intentionally defaults to itself
# so a raw setup.sh download does not silently reinstall fujibee/agmsg main.
REPO="${AGMSG_REPO:-https://github.com/yukimaru77/agmsg.git}"
REF="${AGMSG_REF:-codex-monitor-default}"

TMP=$(mktemp -d)
if ! git clone --depth 1 --branch "$REF" "$REPO" "$TMP/agmsg" 2>/dev/null; then
  echo "agmsg: failed to clone ref '$REF' from $REPO" >&2
  rm -rf "$TMP"
  exit 1
fi
"$TMP/agmsg/install.sh" "$@"
rm -rf "$TMP"
