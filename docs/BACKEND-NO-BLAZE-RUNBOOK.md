# SmartTime Backend (No Blaze) — Runbook

Use this backend when Firebase Functions deploy is blocked on Spark/Blaze.

## Local/VPS run
```bash
cd smarttime-ai/backend/server
npm install
FIREBASE_SERVICE_ACCOUNT_JSON=/path/service-account.json FIREBASE_PROJECT_ID=smarttime-ai-1b64f PORT=8080 npm start
```

## Endpoints
- `GET /v1/health`
- `POST /v1/schools/:schoolId/solver/jobs`
- `GET /v1/schools/:schoolId/solver/jobs`
- `POST /v1/schools/:schoolId/timetables/:versionId/publish`

## Android app usage
Run app with API override:
```bash
flutter run --dart-define=API_BASE=http://<your-host>:8080/v1
```

For emulator talking to host machine, use `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:8080/v1
```
