# SmartTime AI — Test Matrix (V1)

## Backend
- API routes: auth, entities, solver jobs, publish/latest
- Error format consistency
- Role authorization matrix
- Repository integration (Firestore emulator)

## Solver
- Health endpoint
- Basic solve request
- Conflict/unscheduled behavior
- Pinned lessons behavior

## Android
- Firebase init success/fallback
- Email sign-in, create account
- Google sign-in
- Role-based screen routing
- Timetable grid render

## Devices (minimum)
- Android 10 (small phone)
- Android 11 (mid)
- Android 12 (mid)
- Android 13 (high)
- Android 14 (high)

## UAT Scenarios
1. Setup school + entities + constraints
2. Run solver
3. Review conflicts
4. Publish timetable
5. Teacher login and view timetable
6. Student login and view timetable
7. Parent login and view timetable
