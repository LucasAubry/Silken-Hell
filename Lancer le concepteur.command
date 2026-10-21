#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
CACHE_DIR="$HOME/Library/Application Support/Silken Hell"
RUNTIME="$CACHE_DIR/runtime/love.app/Contents/MacOS/love"
if [[ -x /Applications/love.app/Contents/MacOS/love ]]; then RUNTIME=/Applications/love.app/Contents/MacOS/love; fi
SILKEN_PREPARE_ONLY=1 /bin/zsh "$PROJECT_DIR/Lancer Silken Hell.command"
export SILKEN_PROJECT="$PROJECT_DIR"
# LÖVE peut rouvrir l’archive pour charger un module à la demande.
# Garder une édition immuable, également utilisée par les fenêtres de test.
# Elle reste disponible après la fermeture de l’éditeur si un test est ouvert.
EDITION=$(shasum -a 256 "$CACHE_DIR/Silken Hell.love")
EDITION=${EDITION%% *}
mkdir -p "$CACHE_DIR/versions"
EDITOR_ARCHIVE="$CACHE_DIR/versions/editor-$EDITION.love"
if [[ ! -s "$EDITOR_ARCHIVE" ]]; then
  EDITOR_STAGE=$(mktemp "$CACHE_DIR/versions/editor.XXXXXX")
  trap 'rm -f "$EDITOR_STAGE"' EXIT
  cp "$CACHE_DIR/Silken Hell.love" "$EDITOR_STAGE"
  mv -f "$EDITOR_STAGE" "$EDITOR_ARCHIVE"
fi
"$RUNTIME" "$EDITOR_ARCHIVE" --editor
