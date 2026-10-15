#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
exec /bin/zsh "$PROJECT_DIR/tools/launch_version.sh" classique
