# SmartTime AI — Next Action Card (Immediate)

## Objective
Close remaining release blockers B2 and B3.

## B2 (Android staging auth/signing) — Current status
- Toolchain: ✅
- Debug/Release builds: ✅
- appId (`com.smarttime.ai`): ✅
- `google-services.json`: ❌ missing
- `android/key.properties`: ❌ missing

## Exact next steps (copy-paste)
1. Add Firebase config file:
   - place at: `smarttime-ai/android-app/flutter_app/android/app/google-services.json`
2. Create keystore properties:
   - copy `android/key.properties.example` -> `android/key.properties`
   - fill real values
3. Run verification scripts:
```bash
./smarttime-ai/scripts/verify_google_services.sh
./smarttime-ai/scripts/check_keystore_readiness.sh
./smarttime-ai/scripts/check_android_release_readiness.sh
```
4. Rebuild release artifacts:
```bash
cd smarttime-ai/android-app/flutter_app
flutter build apk --release
flutter build appbundle --release
```

## B3 (Role-based UAT)
Run `docs/UAT-SCRIPT.md` and fill `docs/UAT-EXECUTION-LOG.md` with pass/fail + evidence links for each role.
