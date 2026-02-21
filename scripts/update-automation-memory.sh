#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <automation-id> <summary> [memory-file-path]"
  echo "Example: $0 skill-progression-map \"Reviewed 3 PRs; updated skill recommendations.\""
  exit 1
fi

AUTOMATION_ID="$1"
SUMMARY="$2"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
MEMORY_PATH_DEFAULT="${CODEX_HOME_DIR}/automations/${AUTOMATION_ID}/memory.md"
MEMORY_PATH="${3:-$MEMORY_PATH_DEFAULT}"
RUN_TIME="$(date -u '+%Y-%m-%d %H:%M UTC')"

mkdir -p "$(dirname "$MEMORY_PATH")"
touch "$MEMORY_PATH"

{
  echo ""
  echo "Run: ${RUN_TIME}"
  echo "Summary: ${SUMMARY}"
} >> "$MEMORY_PATH"

echo "Updated automation memory: ${MEMORY_PATH}"
