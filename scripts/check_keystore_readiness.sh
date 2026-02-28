#!/usr/bin/env bash
set -euo pipefail
ANDROID_DIR="/Users/abhishekchhetri/.openclaw/workspace/smarttime-ai/android-app/flutter_app/android"
KEY_PROPS="$ANDROID_DIR/key.properties"

echo "Checking release keystore readiness..."
if [ ! -f "$KEY_PROPS" ]; then
  echo "[FAIL] key.properties missing: $KEY_PROPS"
  exit 1
fi

for k in storePassword keyPassword keyAlias storeFile; do
  if ! grep -q "^$k=" "$KEY_PROPS"; then
    echo "[FAIL] Missing $k in key.properties"
    exit 2
  fi
done

STORE_FILE=$(grep '^storeFile=' "$KEY_PROPS" | sed 's/^storeFile=//')
if [ ! -f "$STORE_FILE" ]; then
  echo "[FAIL] storeFile does not exist: $STORE_FILE"
  exit 3
fi

echo "[OK] key.properties is present and references an existing keystore file"

echo "Fingerprint reminder command:"
echo "keytool -list -v -keystore \"$STORE_FILE\" -alias \"$(grep '^keyAlias=' "$KEY_PROPS" | sed 's/^keyAlias=//')\""
