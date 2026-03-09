#!/usr/bin/env python3
import json, sqlite3, sys, uuid, random, time

DB = sys.argv[1] if len(sys.argv) > 1 else "/tmp/smarttime.sqlite"

teachers = [
    (f"T{i:02d}", name, abbr)
    for i, (name, abbr) in enumerate([
        ("Aarav Sharma", "AS"), ("Priya Verma", "PV"), ("Rahul Singh", "RS"),
        ("Neha Gupta", "NG"), ("Vikram Rao", "VR"), ("Kavita Iyer", "KI"),
        ("Sanjay Das", "SD"), ("Meera Nair", "MN"), ("Rohit Jain", "RJ"),
        ("Anita Bose", "AB"), ("Deepak Kumar", "DK"), ("Sneha Patel", "SP"),
        ("Manoj Yadav", "MY"), ("Pooja Roy", "PR"), ("Harsh Mehta", "HM"),
    ], start=1)
]

classes = [(f"C{i:02d}", f"Grade {i}", f"G{i}") for i in range(1, 11)]
subjects = [
    ("SUB_MATH", "Mathematics", "MATH"),
    ("SUB_SCI", "Science", "SCI"),
    ("SUB_ENG", "English", "ENG"),
    ("SUB_HIN", "Hindi", "HIN"),
    ("SUB_SPT", "Sports", "SPT"),
]
rooms = [(f"ROOM_{i}", f"Room {i}") for i in range(101, 109)]

# 100 lessons: 10 classes x 5 subjects x 2 lessons = 100
random.seed(42)
lessons = []
pool = {
    "SUB_MATH": ["T01", "T02", "T03"],
    "SUB_SCI": ["T04", "T05", "T06"],
    "SUB_ENG": ["T07", "T08", "T09"],
    "SUB_HIN": ["T10", "T11", "T12"],
    "SUB_SPT": ["T13", "T14", "T15"],
}
lid = 1
for cls in classes:
    for sub in subjects:
        for _ in range(2):
            sid = sub[0]
            t1 = random.choice(pool[sid])
            if lid % 9 == 0:
                t1 = "T01"
            room_id = rooms[(lid - 1) % len(rooms)][0]
            lessons.append({
                "id": f"L{lid:03d}",
                "subject_id": sid,
                "teacher_ids": [t1],
                "class_ids": [cls[0]],
                "periods_per_week": 1,
                "required_room_id": room_id,
            })
            lid += 1

planner_snapshot = {
    "schoolName": "SmartTime Realistic School",
    "workingDays": 5,
    "bellTimes": [
        "08:00-08:45", "08:45-09:30", "09:45-10:30", "10:30-11:15",
        "11:30-12:15", "12:15-13:00", "13:30-14:15", "14:15-15:00"
    ],
    "subjects": [
        {"id": s[0], "name": s[1], "abbr": s[2], "color": 0xFF0B3D91, "relationshipGroupKey": None}
        for s in subjects
    ],
    "classes": [{"id": c[0], "name": c[1], "abbr": c[2]} for c in classes],
    "divisions": [],
    "teachers": [
        {
            "id": t[0], "firstName": t[1].split()[0], "lastName": " ".join(t[1].split()[1:]),
            "abbr": t[2], "maxGapsPerDay": 2, "maxConsecutivePeriods": 3, "timeOff": {}
        }
        for t in teachers
    ],
    "classrooms": [
        {"id": r[0], "name": r[1], "roomType": "standard"}
        for r in rooms
    ],
    "lessons": [
        {
            "id": l["id"], "subjectId": l["subject_id"], "teacherIds": l["teacher_ids"],
            "classIds": l["class_ids"], "classDivisionId": None, "countPerWeek": 1,
            "length": "single", "requiredClassroomId": l["required_room_id"], "isPinned": False,
            "fixedDay": None, "fixedPeriod": None, "roomTypeId": None,
            "relationshipType": 0, "relationshipGroupKey": None
        }
        for l in lessons
    ],
}

con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("PRAGMA foreign_keys=OFF")
cur.execute("BEGIN")

for tbl in ["cards", "lesson_teachers", "lesson_classes", "lessons", "teacher_unavailability", "divisions", "classes", "teachers", "subjects"]:
    cur.execute(f"DELETE FROM {tbl}")

for sid, name, abbr in subjects:
    cur.execute(
        "INSERT INTO subjects(id,name,abbr,group_id,room_type_id,color,guid) VALUES(?,?,?,?,?,?,?)",
        (sid, name, abbr, None, None, 0xFF0B3D91, str(uuid.uuid4())),
    )

for cid, name, abbr in classes:
    cur.execute(
        "INSERT INTO classes(id,name,abbr,guid) VALUES(?,?,?,?)",
        (cid, name, abbr, str(uuid.uuid4())),
    )

for tid, name, abbr in teachers:
    cur.execute(
        "INSERT INTO teachers(id,name,abbreviation,max_periods_per_day,max_gaps_per_day,guid) VALUES(?,?,?,?,?,?)",
        (tid, name, abbr, 6, 2, str(uuid.uuid4())),
    )

for l in lessons:
    cur.execute(
        """INSERT INTO lessons(id,subject_id,periods_per_week,teacher_ids,class_ids,class_id,class_division_id,is_pinned,fixed_day,fixed_period,room_type_id,relationship_type,relationship_group_key)
           VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (
            l["id"], l["subject_id"], l["periods_per_week"], json.dumps(l["teacher_ids"]), json.dumps(l["class_ids"]),
            l["class_ids"][0], None, 0, None, None, None, 0, None,
        ),
    )

cur.execute(
    "INSERT OR REPLACE INTO app_state(id,planner_json,updated_at) VALUES(1,?,?)",
    (json.dumps(planner_snapshot), int(time.time())),
)

cur.execute("COMMIT")
con.close()
print("Seeded: teachers=15 classes=10 subjects=5 rooms=8 lessons=100")
