#!/bin/zsh
# Double-cliquer ce fichier depuis le Finder.
set -eu
GAME_DIR="${0:A:h}"
RUNTIME="$HOME/Library/Application Support/Silken Hell/runtime/love.app"
if [[ -x /Applications/love.app/Contents/MacOS/love ]]; then
  RUNTIME=/Applications/love.app
elif [[ ! -x "$RUNTIME/Contents/MacOS/love" ]]; then
  echo 'Installation du moteur LÖVE (premier lancement uniquement)…'
  INSTALL_DIR="${RUNTIME:h}"
  mkdir -p "$INSTALL_DIR"
  ARCHIVE=$(mktemp -t silken-love)
  trap 'rm -f "$ARCHIVE"' EXIT
  curl -L --fail --retry 2 https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip -o "$ARCHIVE"
  unzip -q -o "$ARCHIVE" -d "$INSTALL_DIR"
fi
# Le cache hors iCloud garde les textures disponibles pendant toute la partie.
CACHE_DIR="$HOME/Library/Application Support/Silken Hell"
mkdir -p "$CACHE_DIR"
printf '%s\n' "$GAME_DIR" > "$CACHE_DIR/project-path.txt"
# Lancer une version publiée, sans reconstruire ni télécharger les fichiers iCloud.
if [[ ! -s "$CACHE_DIR/Silken Hell.love" ]]; then
  cp "$GAME_DIR/game.love" "$CACHE_DIR/Silken Hell.love.new"
  mv -f "$CACHE_DIR/Silken Hell.love.new" "$CACHE_DIR/Silken Hell.love"
fi
if [[ "${SILKEN_PREPARE_ONLY:-0}" == 1 ]]; then exit 0; fi
exec "$RUNTIME/Contents/MacOS/love" "$CACHE_DIR/Silken Hell.love"
