#!/usr/bin/env bash
# 코스 생성기 대량 검증 (AC-002). 기본 10,000 시드.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

import_project "$LOG_DIR/import.log"

set +e
GODOT_COMMAND_TIMEOUT_SECONDS="${GODOT_COMMAND_TIMEOUT_SECONDS:-3600}" \
  run_godot "$LOG_DIR/validate.log" --headless --path "$ROOT/game" \
  --script res://tools/validate_courses.gd -- "$@"
STATUS=$?
set -e

assert_no_godot_errors "$LOG_DIR/validate.log" || STATUS=1
if ! grep -q "ALL GREEN" "$LOG_DIR/validate.log"; then
  STATUS=1
fi
exit "$STATUS"
