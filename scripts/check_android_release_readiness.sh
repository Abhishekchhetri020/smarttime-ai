#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/Users/abhishekchhetri/.openclaw/workspace/smarttime-ai/android-app/flutter_app"
ANDROID_DIR="$APP_DIR/android"
APP_GRADLE="$ANDROID_DIR/app/build.gradle.kts"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "SmartTime AI Android Readiness Check @ $TS"
echo "=========================================="

if command -v flutter >/dev/null 2>&1; then
  echo "[OK] Flutter installed"
else
  echo "[FAIL] Flutter not installed"
fi

DOCTOR_OUT=$(flutter doctor -v 2>&1 || true)
if echo "$DOCTOR_OUT" | grep -q "Android toolchain - develop for Android devices" && ! echo "$DOCTOR_OUT" | grep -q "Unable to locate Android SDK"; then
  echo "[OK] Android toolchain detected"
else
  echo "[FAIL] Android toolchain missing"
fi

if [ -f "$ANDROID_DIR/app/google-services.json" ]; then
  echo "[OK] google-services.json present"
else
  echo "[WARN] google-services.json missing"
fi

if [ -f "$ANDROID_DIR/key.properties" ]; then
  echo "[OK] key.properties present"
else
  echo "[WARN] key.properties missing"
fi

APP_ID=$(grep -E "applicationId\s*=\s*\"" "$APP_GRADLE" | head -n1 | sed -E 's/.*"(.*)"/\1/' || true)
if [ -n "$APP_ID" ]; then
  echo "[INFO] applicationId: $APP_ID"
  if [ "$APP_ID" = "com.example.smarttime_ai" ]; then
    echo "[WARN] applicationId is still default"
  else
    echo "[OK] applicationId is non-default"
  fi
else
  echo "[WARN] could not parse applicationId"
fi

echo "\nArtifacts check:"
[ -f "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" ] && echo "[OK] app-release.apk exists" || echo "[WARN] app-release.apk missing"
[ -f "$APP_DIR/build/app/outputs/bundle/release/app-release.aab" ] && echo "[OK] app-release.aab exists" || echo "[WARN] app-release.aab missing"
