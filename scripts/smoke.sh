#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/_godot.sh"
OUT="${E2E_OUT:-$ROOT/build/e2e}"
mkdir -p "$OUT"
import_project "$OUT/import.log"
args=(--headless --audio-driver Dummy)
capture_args=()
if [ "${E2E_CAPTURE:-0}" = 1 ]; then args=(--audio-driver Dummy); capture_args=(--capture); fi
run_godot "$OUT/run.log" "${args[@]}" --path "$ROOT/game" --script res://tools/e2e/journey.gd -- \
  --progress-path "user://e2e/${E2E_RUN_ID:-local}/progress.json" --out "$OUT" \
  --locale "${E2E_LOCALE:-ko}" --size "${E2E_SIZE:-1080x2340}" "${capture_args[@]}"
assert_no_godot_errors "$OUT/run.log"
grep -Fq '[e2e] ALL GREEN' "$OUT/run.log"
python3 "$ROOT/scripts/check_e2e_coverage.py" --inventory "$ROOT/docs/qa/feature-inventory.json" --journey "$OUT/journey.json"
