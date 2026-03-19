#!/bin/zsh
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <dir> <task...>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

PORT="${OPENCODE_SIDECAR_PORT:-4096}"
HOST="${OPENCODE_SIDECAR_HOST:-127.0.0.1}"
STATE_DIR="${OPENCODE_SIDECAR_STATE_DIR:-${0:A:h}/state}"
DIR="$1"
shift

if [[ ! -d "$DIR" ]]; then
  echo "Directory does not exist: $DIR" >&2
  exit 1
fi

ABS_DIR="$(cd "$DIR" && pwd -P)"
TASK="$*"
PROMPT=$'Read-only analysis only. Do not edit files, run destructive commands, or propose patches.\nReturn at most 8 concise bullets.\nCite exact file paths and line numbers when possible.\nIf the answer is uncertain, say so briefly.\n\nTask:\n'"$TASK"
SESSION_KEY="$(print -nr -- "$ABS_DIR" | shasum -a 256 | awk '{print $1}')"
SESSION_FILE="${STATE_DIR}/${SESSION_KEY}.session"
BASE_URL="http://${HOST}:${PORT}"
DIR_QUERY="$(jq -rn --arg v "$ABS_DIR" '$v|@uri')"
mkdir -p "$STATE_DIR"

AUTH_ARGS=()
if [[ -n "${OPENCODE_SERVER_PASSWORD:-}" ]]; then
  AUTH_ARGS=(-u ":${OPENCODE_SERVER_PASSWORD}")
fi

create_session() {
  local response
  response="$(
    curl -sS "${AUTH_ARGS[@]}" \
      -X POST "${BASE_URL}/session?directory=${DIR_QUERY}" \
      -H 'Content-Type: application/json' \
      -d '{"title":"codex-sidecar"}'
  )"
  local session_id
  session_id="$(printf '%s' "$response" | jq -r '.id // empty')"
  if [[ -z "$session_id" ]]; then
    echo "Failed to create OpenCode session" >&2
    printf '%s\n' "$response" >&2
    exit 1
  fi
  printf '%s' "$session_id" > "$SESSION_FILE"
  printf '%s' "$session_id"
}

post_prompt() {
  local session_id="$1"
  local body_file http_code
  body_file="$(mktemp)"
  http_code="$(
    curl -sS "${AUTH_ARGS[@]}" \
      -o "$body_file" \
      -w '%{http_code}' \
      -X POST "${BASE_URL}/session/${session_id}/message?directory=${DIR_QUERY}" \
      -H 'Content-Type: application/json' \
      -d "$(jq -nc --arg prompt "$PROMPT" '{parts:[{type:"text", text:$prompt}]}')"
  )"
  printf '%s\n%s\n' "$http_code" "$body_file"
}

if [[ -f "$SESSION_FILE" ]]; then
  SESSION_ID="$(<"$SESSION_FILE")"
else
  SESSION_ID="$(create_session)"
fi

RESULT="$(post_prompt "$SESSION_ID")"
HTTP_CODE="${RESULT%%$'\n'*}"
BODY_FILE="${RESULT#*$'\n'}"

if [[ "$HTTP_CODE" == "404" ]]; then
  SESSION_ID="$(create_session)"
  rm -f "$BODY_FILE"
  RESULT="$(post_prompt "$SESSION_ID")"
  HTTP_CODE="${RESULT%%$'\n'*}"
  BODY_FILE="${RESULT#*$'\n'}"
fi

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "OpenCode prompt failed with HTTP ${HTTP_CODE}" >&2
  cat "$BODY_FILE" >&2
  rm -f "$BODY_FILE"
  exit 1
fi

jq -r '
  .parts[]
  | select(.type == "text")
  | .text
' "$BODY_FILE"

rm -f "$BODY_FILE"
