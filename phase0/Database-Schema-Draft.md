# SmartTime AI — Firestore Schema Draft

## Collections

### schools/{schoolId}
- name
- timezone
- academicYear
- workingDays[]
- periods[]
- createdAt, updatedAt

### schools/{schoolId}/users/{userId}
- role: super_admin | incharge | teacher | student | parent
- linkedEntityId (teacherId/studentId/parentId)
- status

### schools/{schoolId}/teachers/{teacherId}
- name, code
- subjects[]
- availability[day][period] => bool
- maxDailyLoad

### schools/{schoolId}/classes/{classId}
- grade
- section
- strength

### schools/{schoolId}/subjects/{subjectId}
- name
- weeklyPeriodsByClass{classId: n}
- requiresLab(bool)

### schools/{schoolId}/rooms/{roomId}
- name
- type
- capacity
- availability

### schools/{schoolId}/constraints/{constraintId}
- type
- scope (teacher/class/subject/global)
- params
- weight
- enabled

### schools/{schoolId}/solverJobs/{jobId}
- status: queued|running|failed|done
- triggeredBy
- startedAt, endedAt
- seed
- score
- diagnosticsRef

### schools/{schoolId}/timetables/{versionId}
- status: draft|published|archived
- sourceJobId
- createdBy
- createdAt
- publishedAt

### schools/{schoolId}/timetables/{versionId}/entries/{entryId}
- day
- period
- classId
- subjectId
- teacherId
- roomId
- pinned(bool)

### schools/{schoolId}/auditLogs/{logId}
- actorId
- action
- payload
- timestamp

### schools/{schoolId}/exports/{exportId}
- type: pdf|xlsx
- scope: class|teacher|school
- storagePath
- createdAt

## Indexing Notes
- Composite index on timetable entries: (classId, day, period)
- Composite index on timetable entries: (teacherId, day, period)
- Solver jobs by status+createdAt

## Data Partitioning
All records include/are nested under `schoolId` boundary for isolation and scaling.
