#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
CACHE_DIR="$HOME/Library/Application Support/Silken Hell"
RUNTIME="$CACHE_DIR/runtime/love.app/Contents/MacOS/love"
if [[ -x /Applications/love.app/Contents/MacOS/love ]]; then RUNTIME=/Applications/love.app/Contents/MacOS/love; fi
SILKEN_PREPARE_ONLY=1 /bin/zsh "$PROJECT_DIR/Lancer Silken Hell.command"
export SILKEN_PROJECT="$PROJECT_DIR"
"$RUNTIME" "$CACHE_DIR/Silken Hell.love" --editor
