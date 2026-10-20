#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/build.env"
: "${JAVA_HOME:?JAVA_HOME is required}"
: "${ANDROID_HOME:?ANDROID_HOME is required}"
TEMPLATES="${GODOT_TEMPLATES_DIR:-$HOME/.local/share/godot/export_templates}/${GODOT_VERSION}.${GODOT_STATUS}"
if [ ! -d "$TEMPLATES" ] && [ "$(uname -s)" = Darwin ]; then
  TEMPLATES="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.${GODOT_STATUS}"
fi
[ -f "$TEMPLATES/android_source.zip" ] || { echo "Android export templates missing: $TEMPLATES" >&2; exit 1; }
if [ ! -f "$ROOT/game/android/build/build.gradle" ]; then
  mkdir -p "$ROOT/game/android/build"
  unzip -q "$TEMPLATES/android_source.zip" -d "$ROOT/game/android/build"
fi
printf '%s\n' "${GODOT_VERSION}.${GODOT_STATUS}" > "$ROOT/game/android/.build_version"
mkdir -p "$ROOT/game/android/plugins"
touch "$ROOT/game/android/.gdignore"
"$ROOT/native/android/crowd_gate_platform/gradlew" -p "$ROOT/native/android/crowd_gate_platform" :plugin:assembleRelease --console=plain
cp "$ROOT/native/android/crowd_gate_platform/plugin/build/outputs/aar/plugin-release.aar" "$ROOT/game/android/plugins/CrowdGatePlatform.aar"
cat > "$ROOT/game/android/plugins/CrowdGatePlatform.gdap" <<'GDAP'
[config]
name="CrowdGatePlatform"
binary_type="local"
binary="CrowdGatePlatform.aar"
[dependencies]
remote=["com.google.android.gms:play-services-ads:25.5.0", "com.google.android.ump:user-messaging-platform:4.0.0", "androidx.core:core:1.17.0"]
GDAP
chmod +x "$ROOT/game/android/build/gradlew"
