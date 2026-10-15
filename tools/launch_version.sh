#!/bin/zsh
# Launch an immutable edition; never switch Git branches or rebuild sources.
set -eu
PROJECT_DIR="${0:A:h:h}"
EDITION="${1:-}"
case "$EDITION" in
  classique|new-deccors) ;;
  *) print -u2 'Version inconnue.'; exit 1 ;;
esac
SOURCE_ARCHIVE="$PROJECT_DIR/dist/versions/$EDITION.love"
CACHE_ROOT="$HOME/Library/Application Support/Silken Hell"
EDITION_CACHE="$CACHE_ROOT/versions/$EDITION"
RUNTIME="$CACHE_ROOT/runtime/love.app/Contents/MacOS/love"
if [[ -x /Applications/love.app/Contents/MacOS/love ]]; then
  RUNTIME=/Applications/love.app/Contents/MacOS/love
fi
if [[ ! -s "$SOURCE_ARCHIVE" ]]; then
  print -u2 'Archive de cette version absente. Exécute python3 tools/package_versions.py depuis le projet.'
  exit 1
fi
if [[ ! -x "$RUNTIME" ]]; then
  print -u2 'Moteur LÖVE absent. Lance une fois Lancer Silken Hell.command pour l’installer.'
  exit 1
fi
mkdir -p "$EDITION_CACHE"
if ! cmp -s "$SOURCE_ARCHIVE" "$EDITION_CACHE/game.love"; then
  STAGED=$(mktemp "$EDITION_CACHE/game.XXXXXX")
  cp "$SOURCE_ARCHIVE" "$STAGED"
  mv -f "$STAGED" "$EDITION_CACHE/game.love"
fi
if [[ "${SILKEN_VERSION_PREPARE_ONLY:-0}" == 1 ]]; then
  print -r -- "$EDITION_CACHE/game.love"
  exit 0
fi
export SILKEN_ASSET_ARCHIVE="$EDITION_CACHE/game.love"
SESSION_DIR=$(mktemp -d "$EDITION_CACHE/session.XXXXXX")
trap 'rm -f "$SESSION_DIR/game.love"; rmdir "$SESSION_DIR"' EXIT
cp "$EDITION_CACHE/game.love" "$SESSION_DIR/game.love"
"$RUNTIME" "$SESSION_DIR/game.love"
