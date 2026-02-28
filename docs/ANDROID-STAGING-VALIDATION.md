# SmartTime AI — Android Staging Validation Checklist

## Preconditions (must be ready first)
- [x] Flutter SDK installed (`flutter --version` works)
- [x] Android project scaffold exists (`android/app` present)
- [ ] Android SDK installed and detected by `flutter doctor`

## Firebase / Auth Setup
- [ ] `google-services.json` from staging Firebase project added to app
- [ ] Android package name matches Firebase app registration
- [ ] SHA-1 and SHA-256 fingerprints configured in Firebase project
- [ ] Email/password auth enabled
- [ ] Google Sign-In enabled and OAuth consent configured
- [ ] Web client ID and Android client ID verified

## Build/Signing
- [ ] Staging keystore configured
- [ ] `key.properties` verified (not committed to repo)
- [x] `flutter build apk --release` succeeds
- [x] `flutter build appbundle --release` succeeds
- [x] `flutter build apk --debug` succeeds (evidence captured)

## Runtime Validation
- [ ] Email sign-in works
- [ ] Account creation works
- [ ] Google sign-in works
- [ ] Sign-out works
- [ ] Role claim routing works (teacher/student/parent/incharge/super_admin)
- [ ] Timetable grid renders from published version

## Security/Release Hygiene
- [ ] No debug logs leaking secrets
- [ ] API base/staging endpoints correct
- [ ] Crash reporting configured

## Sign-off
- Validator:
- Date:
- Result: [ ] PASS [ ] FAIL
- Notes:

## Current Findings (2026-02-28)
- `android/app/google-services.json`: missing
- `android/key.properties`: missing
- Android `applicationId` is still default (`com.example.smarttime_ai`) and must be changed for production.
- Release builds are generating successfully (`app-release.apk`, `app-release.aab`), but production signing/auth configuration is still pending.
