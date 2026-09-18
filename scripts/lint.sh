#!/usr/bin/env bash
# 정적 검사: 임포트와 스크립트 파싱만 확인한다. CI 컴파일 게이트와 같은 범위다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

echo "[lint] 임포트 패스"
import_project "$LOG_DIR/import.log"

echo "[lint] 스크립트 컴파일 확인"
set +e
run_godot "$LOG_DIR/compile.log" --headless --path "$ROOT/game" --quit
STATUS=$?
set -e
assert_no_godot_errors "$LOG_DIR/compile.log" || STATUS=1
exit "$STATUS"
