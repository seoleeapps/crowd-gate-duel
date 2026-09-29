#!/usr/bin/env bash
# 앱 흐름 스모크: 온보딩 → 결과 → 홈 → 대국 → 결과. 사용자 저장과 분리된 경로를 쓴다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

echo "[smoke] 임포트 패스"
import_project "$LOG_DIR/import.log"

echo "[smoke] 첫 세션 흐름"
set +e
run_godot "$LOG_DIR/smoke.log" --headless --path "$ROOT/game" --script res://tools/smoke_flow.gd \
  -- --progress-path user://smoke/progress.json
STATUS=$?
set -e
assert_no_godot_errors "$LOG_DIR/smoke.log" || STATUS=1
if ! grep -q "\[smoke\] ALL GREEN" "$LOG_DIR/smoke.log"; then
  echo "[smoke] ALL GREEN 표시가 없습니다."
  STATUS=1
fi
exit "$STATUS"
