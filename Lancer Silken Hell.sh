#!/bin/sh
set -eu
BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -n "${SILKEN_LOVE:-}" ]; then
  RUNTIME=$SILKEN_LOVE
elif command -v love >/dev/null 2>&1; then
  RUNTIME=love
elif [ -x /Applications/love.app/Contents/MacOS/love ]; then
  RUNTIME=/Applications/love.app/Contents/MacOS/love
elif [ -x "$HOME/Library/Application Support/Silken Hell/runtime/love.app/Contents/MacOS/love" ]; then
  RUNTIME="$HOME/Library/Application Support/Silken Hell/runtime/love.app/Contents/MacOS/love"
else
  echo 'Installez LÖVE 11.5 (https://love2d.org), puis relancez le jeu.' >&2
  exit 1
fi
if [ -f "$BASE/dist/game.love" ]; then
  exec "$RUNTIME" "$BASE/dist/game.love" "$@"
fi
exec "$RUNTIME" "$BASE" "$@"
