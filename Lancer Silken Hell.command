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
cd "$GAME_DIR"
echo 'Préparation du jeu…'
BUILD_DIR=$(mktemp -d "$CACHE_DIR/build.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT
if [[ -f "$CACHE_DIR/Silken Hell.love" ]]; then
  cp "$CACHE_DIR/Silken Hell.love" "$BUILD_DIR/game.love"
fi
# Synchronise aussi les suppressions, sans relire les textures inchangées.
/usr/bin/zip -q -FS -r "$BUILD_DIR/game.love" ./*.lua ./*.glsl police.ttf levels assets texture tests designer || {
  RESULT=$?
  if [[ "$RESULT" != 12 ]]; then exit "$RESULT"; fi
}
mv -f "$BUILD_DIR/game.love" "$CACHE_DIR/Silken Hell.love"
if [[ "${SILKEN_PREPARE_ONLY:-0}" == 1 ]]; then exit 0; fi
open -n -a "$RUNTIME" --args "$CACHE_DIR/Silken Hell.love"
