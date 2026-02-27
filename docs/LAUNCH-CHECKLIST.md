# SmartTime AI — Launch Checklist (Play Store)

## Product Readiness
- [ ] No P0/P1 bugs open
- [ ] Solver hard-conflict publish block verified
- [ ] Admin publish workflow verified on staging
- [ ] Android auth flows verified (email + Google)
- [ ] Role access verified (super admin, incharge, teacher, student, parent)

## Testing
- [ ] Backend tests passing (Jest)
- [ ] Solver tests passing (Pytest)
- [ ] Emulator integration tests passing in CI
- [ ] Android smoke on at least 5 device profiles
- [ ] Performance check: timetable generation target met

## Security & Compliance
- [ ] Firestore rules reviewed
- [ ] Sensitive keys in Secret Manager (not repo)
- [ ] Privacy Policy published URL ready
- [ ] Terms of Use URL ready
- [ ] Data deletion request flow documented

## Release Assets
- [ ] App icon + feature graphic
- [ ] Screenshots (phone + tablet)
- [ ] Store listing copy finalized
- [ ] Support email + contact page

## Rollout
- [ ] Internal test track release
- [ ] Closed test release
- [ ] Production staged rollout (10% -> 25% -> 50% -> 100%)
- [ ] Crash/ANR monitoring active

## Post-launch
- [ ] Day-1 health dashboard review
- [ ] User feedback triage channel
- [ ] Hotfix rollback plan validated
