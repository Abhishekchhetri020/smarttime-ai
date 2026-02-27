# SmartTime AI — Release Candidate Checklist

## Code & Quality
- [ ] All CI jobs passing
- [ ] No critical open defects
- [ ] API contract stable (versioned if changed)
- [ ] Migration/index changes reviewed

## Functional
- [ ] Timetable generation works on real staging data
- [ ] Conflict dashboard usable with actionable info
- [ ] Publish flow updates latest timetable correctly
- [ ] Role access enforced correctly across app + API

## Mobile
- [ ] Email and Google sign-in validated
- [ ] Timetable grid readability validated on small/large screens
- [ ] Sign-out and session restore tested

## Security
- [ ] Firestore rules validated
- [ ] Secrets not present in repo
- [ ] Least privilege claims reviewed

## Operational
- [ ] Monitoring/alerts configured
- [ ] Support and escalation contacts set
- [ ] Rollback procedure rehearsed

## Release approval
- [ ] Product owner sign-off
- [ ] Tech lead sign-off
- [ ] QA sign-off
