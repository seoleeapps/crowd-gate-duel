#!/usr/bin/env bash
# 빌드 진입점. 지금은 디버그 APK 만 만든다(06 빌드와 테스트 명령).
#   scripts/build.sh --debug
# 서명은 Godot 편집기 설정의 디버그 키스토어를 쓴다. 출시용 서명은 여기서 다루지 않는다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"

if [ "${1:-}" != "--debug" ]; then
  echo "사용법: scripts/build.sh --debug" >&2
  exit 2
fi

OUT="$ROOT/build/android/crowd-gate-duel-debug.apk"
BUDGET_MB=80
mkdir -p "$(dirname "$OUT")"
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

echo "[build] 임포트 패스"
import_project "$LOG_DIR/import.log"

echo "[build] 디버그 APK 내보내기"
set +e
run_godot "$LOG_DIR/export.log" --headless --path "$ROOT/game" --export-debug "Android Debug" "$OUT"
STATUS=$?
set -e
assert_no_godot_errors "$LOG_DIR/export.log" || STATUS=1
if [ ! -f "$OUT" ]; then
  echo "[build] APK 가 만들어지지 않았습니다."
  exit 1
fi
SIZE_MB=$(( $(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT") / 1024 / 1024 ))
echo "[build] $OUT (${SIZE_MB}MB, 예산 ${BUDGET_MB}MB)"
if [ "$SIZE_MB" -gt "$BUDGET_MB" ]; then
  echo "[build] 패키지 크기 예산 초과"
  STATUS=1
fi
exit "$STATUS"
