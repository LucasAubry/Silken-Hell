#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
RUNTIME="$HOME/Library/Application Support/Silken Hell/runtime/love.app/Contents/MacOS/love"
SILKEN_PREPARE_ONLY=1 /bin/zsh "$PROJECT_DIR/Lancer Silken Hell.command"
export SILKEN_PROJECT="$PROJECT_DIR"
exec "$RUNTIME" "$PROJECT_DIR/designer"
