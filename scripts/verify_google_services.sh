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

OAUTH_COUNT=$(python3 - <<'PY'
import json
p='/Users/abhishekchhetri/.openclaw/workspace/smarttime-ai/android-app/flutter_app/android/app/google-services.json'
d=json.load(open(p))
client=(d.get('client') or [{}])[0]
print(len(client.get('oauth_client') or []))
PY
)

echo "[INFO] oauth_client count in google-services.json: $OAUTH_COUNT"
if [ "$OAUTH_COUNT" -eq 0 ]; then
  echo "[FAIL] No OAuth clients found in google-services.json. Google Sign-In will fail (ApiException: 10)."
  echo "       Add SHA-1/SHA-256 fingerprints in Firebase Android app settings and re-download google-services.json."
  exit 3
fi

echo "[OK] OAuth client entries present"
