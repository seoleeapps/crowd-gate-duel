#!/usr/bin/env bash
# 전략 승률 행렬 출력. 밸런스 회귀를 눈으로 확인하는 참고 지표다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

import_project "$LOG_DIR/import.log"
run_godot "$LOG_DIR/matrix.log" --headless --path "$ROOT/game" \
  --script res://tools/strategy_matrix.gd -- "$@"
assert_no_godot_errors "$LOG_DIR/matrix.log"
