#!/usr/bin/env bash
# 도메인 헤드리스 테스트. 기기·네트워크·Firebase 없이 돌아야 한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

echo "[test] 임포트 패스"
import_project "$LOG_DIR/import.log"

echo "[test] 도메인 테스트"
set +e
run_godot "$LOG_DIR/test.log" --headless --path "$ROOT/game" --script res://tests/run_all.gd
STATUS=$?
set -e

assert_no_godot_errors "$LOG_DIR/test.log" || STATUS=1
if ! grep -q "ALL GREEN" "$LOG_DIR/test.log"; then
  echo "[test] ALL GREEN 표시가 없습니다."
  STATUS=1
fi
exit "$STATUS"
