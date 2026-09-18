#!/usr/bin/env bash
# Godot 헤드리스 공용 실행기.
# Godot 은 스크립트 오류가 있어도 종료 코드 0 을 낼 수 있으므로 로그를 직접 검사한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
TIMEOUT_SECONDS="${GODOT_COMMAND_TIMEOUT_SECONDS:-600}"

run_godot() {
  local log_file="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout --kill-after=10s "${TIMEOUT_SECONDS}s" "$GODOT_BIN" "$@" 2>&1 | tee "$log_file"
  else
    # macOS 기본 환경에는 timeout 이 없다. 그대로 실행한다.
    "$GODOT_BIN" "$@" 2>&1 | tee "$log_file"
  fi
  return "${PIPESTATUS[0]}"
}

assert_no_godot_errors() {
  local log_file="$1"
  if grep -qE '(SCRIPT ERROR|^ERROR:|Parse Error)' "$log_file"; then
    echo ""
    echo "[gate] Godot 로그에 오류가 있습니다. 종료 코드와 무관하게 실패로 처리합니다."
    grep -nE '(SCRIPT ERROR|^ERROR:|Parse Error)' "$log_file" | head -20
    return 1
  fi
  return 0
}

import_project() {
  local log_file="$1"
  run_godot "$log_file" --headless --path "$ROOT/game" --import --quit >/dev/null
  assert_no_godot_errors "$log_file"
}
