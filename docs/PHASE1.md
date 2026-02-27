# Phase 1 Implementation Notes

## Delivered
1. Firebase Functions skeleton (TypeScript)
2. Firestore-aware API route placeholders for:
   - schools
   - teachers
   - classes
   - subjects
   - rooms
   - constraints
   - solver jobs
3. Role middleware (`super_admin`, `incharge`, `teacher`, `student`, `parent`)
4. Solver service (FastAPI) with:
   - `/health`
   - `/solve` (stubbed scoring/diagnostics)
5. Admin web scaffold (Next.js minimal)
6. Infra templates (`.env.example`, run commands)

## Next (Phase 2)
- Implement real CRUD + Firestore indexes
- Implement async solver job trigger via Pub/Sub
- Add authentication + custom claims wiring
- Add first admin UI screens
- Add Android auth + read-only timetable screens
