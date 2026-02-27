# SmartTime AI — Staging Deployment Runbook

## 1. Preconditions
- Firebase staging project created
- Cloud Run staging service ready for solver
- Required secrets configured
- CI green on main branch

## 2. Configure environment
- Copy `infra/.env.example` to staging env config
- Set:
  - `FIREBASE_PROJECT_ID`
  - `SOLVER_BASE_URL`
  - `SOLVER_TOPIC`

## 3. Deploy backend (functions)
```bash
cd smarttime-ai/backend/functions
npm install
npm run build
firebase use <staging-project>
firebase deploy --only functions,firestore:rules,firestore:indexes
```

## 4. Deploy solver (Cloud Run)
```bash
cd smarttime-ai/solver
gcloud builds submit --tag gcr.io/<project>/smarttime-solver:staging
gcloud run deploy smarttime-solver-staging \
  --image gcr.io/<project>/smarttime-solver:staging \
  --region asia-south1 --allow-unauthenticated
```

## 5. Deploy admin web (staging)
- Build and deploy to your hosting target (Vercel/Firebase Hosting).
- Set `NEXT_PUBLIC_API_BASE` to staging functions URL.

## 6. Android staging build
- Configure `google-services.json` for staging Firebase project
- Build internal APK/AAB and distribute to internal testers

## 7. Smoke checks
- Login with each role
- CRUD entities
- Run solver job
- Conflict dashboard shows diagnostics
- Publish timetable
- Android renders published timetable grid

## 8. Rollback
- Revert to previous tagged release
- Redeploy functions and solver image from previous tag
- Mark failed release in release log
