#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/Users/abhishekchhetri/.openclaw/workspace/smarttime-ai/android-app/flutter_app/android/app"
FILE="$APP_DIR/google-services.json"
EXPECTED="com.smarttime.ai"

echo "Verifying google-services.json..."
if [ ! -f "$FILE" ]; then
  echo "[FAIL] $FILE not found"
  exit 1
fi

PKG=$(grep -oE '"package_name"\s*:\s*"[^"]+"' "$FILE" | head -n1 | sed -E 's/.*"([^"]+)"$/\1/' || true)
if [ -z "$PKG" ]; then
  echo "[FAIL] Could not parse package_name from google-services.json"
  exit 1
fi

echo "[INFO] package_name=$PKG"
if [ "$PKG" != "$EXPECTED" ]; then
  echo "[FAIL] package mismatch. expected=$EXPECTED got=$PKG"
  exit 2
fi

echo "[OK] google-services.json package matches applicationId ($EXPECTED)"
