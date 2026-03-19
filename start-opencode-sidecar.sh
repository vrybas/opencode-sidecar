#!/bin/zsh
set -euo pipefail

PORT="${OPENCODE_SIDECAR_PORT:-4096}"
HOST="${OPENCODE_SIDECAR_HOST:-127.0.0.1}"

exec opencode serve --hostname "$HOST" --port "$PORT"
