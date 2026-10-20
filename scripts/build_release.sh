#!/usr/bin/env bash
# 신뢰된 annotated 출시 태그와 등록된 앱 키만 사용한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/_godot.sh"
: "${GOOGLE_PLAY_UPLOAD_CERTIFICATE_SHA256:?Expected certificate fingerprint is required}"
: "${RELEASE_TAG:?RELEASE_TAG is required}"
: "${GOOGLE_PLAY_UPLOAD_KEYSTORE_FILE:?App-specific upload keystore is required}"
: "${GOOGLE_PLAY_UPLOAD_KEYSTORE_PASSWORD:?Keystore password is required}"
: "${GOOGLE_PLAY_UPLOAD_KEY_ALIAS:?Keystore alias is required}"
: "${GOOGLE_PLAY_UPLOAD_KEY_PASSWORD:?Key password is required}"
[[ "$RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid release tag'; exit 1; }
[ "$(git cat-file -t "$RELEASE_TAG")" = tag ] || { echo 'Annotated tag required'; exit 1; }
[ "$(git rev-parse "$RELEASE_TAG^{commit}")" = "$(git rev-parse HEAD)" ] || { echo 'Tag and source mismatch'; exit 1; }
git merge-base --is-ancestor HEAD origin/main || { echo 'Release must belong to main'; exit 1; }
receipt="$(git for-each-ref --format='%(contents)' "refs/tags/$RELEASE_TAG")"
source_sha="$(git rev-parse HEAD)"
version_name="${RELEASE_TAG#v}"
version_code="$(printf '%s\n' "$receipt" | sed -n 's/^android-version-code: //p')"
[[ "$version_code" =~ ^[1-9][0-9]*$ ]] || { echo 'Tag receipt missing Android code'; exit 1; }
printf '%s\n' "$receipt" | rg -qx "source-sha: $source_sha"
printf '%s\n' "$receipt" | rg -qx "version-name: $version_name"
python3 scripts/check_release.py
export ADMOB_APP_ID
ADMOB_APP_ID="$(python3 -c 'import json; print(json.load(open("game/config/android.json"))["admob_app_id"])')"
scripts/prepare_android.sh
# Only the tagged source is versioned. The export preset is a build-time execution copy.
python3 - "$version_name" "$version_code" <<'PY'
from pathlib import Path
import re, sys
p = Path('game/export_presets.cfg')
s = p.read_text()
header, release = s.split('[preset.1.options]', 1)
release = re.sub(r'version/name="[^"]*"', 'version/name="' + sys.argv[1] + '"', release)
release = re.sub(r'version/code=\d+', 'version/code=' + sys.argv[2], release)
p.write_text(header + '[preset.1.options]' + release)
PY
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$GOOGLE_PLAY_UPLOAD_KEYSTORE_FILE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$GOOGLE_PLAY_UPLOAD_KEY_ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$GOOGLE_PLAY_UPLOAD_KEYSTORE_PASSWORD"
export GODOT_ANDROID_KEYSTORE_RELEASE_KEY_PASSWORD="$GOOGLE_PLAY_UPLOAD_KEY_PASSWORD"
mkdir -p build/android
import_project build/android/import.log
run_godot build/android/export.log --headless --path "$ROOT/game" --export-release Android "$ROOT/build/android/crowd-gate-duel.aab"
assert_no_godot_errors build/android/export.log
[ -s build/android/crowd-gate-duel.aab ]
python3 scripts/verify_aab.py build/android/crowd-gate-duel.aab --version "$version_name" --code "$version_code" --certificate "$GOOGLE_PLAY_UPLOAD_CERTIFICATE_SHA256" | tee build/android/receipt.json
