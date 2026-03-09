import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class AnalyticsSnapshot {
  final int totalAssignedLessons;
  final int hardConflictCount;
  final double averageTeacherGaps;

  const AnalyticsSnapshot({
    required this.totalAssignedLessons,
    required this.hardConflictCount,
    required this.averageTeacherGaps,
  });
}

@DataClassName('SubjectRow')
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get guid => text().nullable()();
  TextColumn get name => text()();
  TextColumn get abbr => text()();
  TextColumn get groupId => text().nullable()();
  IntColumn get roomTypeId => integer().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0xFF0B3D91))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClassRow')
class Classes extends Table {
  TextColumn get id => text()();
  TextColumn get guid => text().nullable()();
  TextColumn get name => text()();
  TextColumn get abbr => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.trim().isEmpty) return const <String>[];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const <String>[];
    return decoded.map((e) => e.toString()).toList(growable: false);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

@DataClassName('DivisionRow')
class Divisions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get classId => text().references(Classes, #id)();

  @override
  String get tableName => 'divisions';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TeacherRow')
class Teachers extends Table {
  TextColumn get id => text()();
  TextColumn get guid => text().nullable()();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  IntColumn get maxPeriodsPerDay => integer().nullable()();
  IntColumn get maxGapsPerDay => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TeacherUnavailabilityRow')
class TeacherUnavailability extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text().references(Teachers, #id)();
  IntColumn get day => integer()();
  IntColumn get period => integer()();
  IntColumn get state =>
      integer().withDefault(const Constant(1))(); // 1=unavailable,2=conditional

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LessonRow')
class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();

  // aSc contract-style requirement fields
  IntColumn get periodsPerWeek => integer().withDefault(const Constant(1))();
  TextColumn get teacherIds => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get classIds => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  // Back-compat fields retained for existing planner/controller flow.
  TextColumn get classId => text().nullable()();
  TextColumn get classDivisionId =>
      text().nullable().references(Divisions, #id)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get fixedDay => integer().nullable()();
  IntColumn get fixedPeriod => integer().nullable()();
  IntColumn get roomTypeId => integer().nullable()();
  IntColumn get relationshipType => integer().withDefault(const Constant(0))();
  TextColumn get relationshipGroupKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CardRow')
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  IntColumn get dayIndex => integer()();
  IntColumn get periodIndex => integer()();
  TextColumn get roomId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LessonClasses extends Table {
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get classId => text().references(Classes, #id)();

  @override
  Set<Column> get primaryKey => {lessonId, classId};
}

class LessonTeachers extends Table {
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get teacherId => text().references(Teachers, #id)();

  @override
  Set<Column> get primaryKey => {lessonId, teacherId};
}

class EntityTimeOff extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get day => integer()();
  IntColumn get period => integer()();
  IntColumn get state => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SoftConstraintProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get maxGapsPerDay => integer().nullable()();
  IntColumn get maxConsecutivePeriods => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get plannerJson => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smarttime.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(
  tables: [
    Subjects,
    Classes,
    Divisions,
    Teachers,
    TeacherUnavailability,
    Lessons,
    Cards,
    LessonClasses,
    LessonTeachers,
    EntityTimeOff,
    SoftConstraintProfiles,
    AppState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 7) {
            await m.createAll();
            await customStatement('''
              INSERT OR IGNORE INTO lesson_classes (lesson_id, class_id)
              SELECT id, class_id FROM lessons WHERE class_id IS NOT NULL
            ''');
          }
          if (from < 8) {
            await m.createTable(teachers);
            await m.createTable(teacherUnavailability);
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_teacher_unavailability_teacher_slot ON teacher_unavailability(teacher_id, day, period)');
          }
          if (from < 9) {
            await m.createTable(divisions);
            await m.createTable(cards);

            await customStatement(
              'ALTER TABLE lessons ADD COLUMN periods_per_week INTEGER NOT NULL DEFAULT 1',
            );
            await customStatement(
              "ALTER TABLE lessons ADD COLUMN teacher_ids TEXT NOT NULL DEFAULT '[]'",
            );
            await customStatement(
              "ALTER TABLE lessons ADD COLUMN class_ids TEXT NOT NULL DEFAULT '[]'",
            );

            await customStatement(
              'UPDATE lessons SET periods_per_week = count_per_week WHERE periods_per_week IS NULL OR periods_per_week = 1',
            );
          }
          if (from < 10) {
            await customStatement('''
              CREATE TABLE lessons_new (
                id TEXT NOT NULL PRIMARY KEY,
                subject_id TEXT NOT NULL REFERENCES subjects(id),
                periods_per_week INTEGER NOT NULL DEFAULT 1,
                teacher_ids TEXT NOT NULL DEFAULT '[]',
                class_ids TEXT NOT NULL DEFAULT '[]',
                class_id TEXT NULL,
                class_division_id TEXT NULL REFERENCES divisions(id),
                is_pinned INTEGER NOT NULL DEFAULT 0,
                fixed_day INTEGER NULL,
                fixed_period INTEGER NULL,
                room_type_id INTEGER NULL,
                relationship_type INTEGER NOT NULL DEFAULT 0,
                relationship_group_key TEXT NULL
              )
            ''');

            await customStatement('''
              INSERT INTO lessons_new (
                id, subject_id, periods_per_week, teacher_ids, class_ids,
                class_id, class_division_id, is_pinned, fixed_day, fixed_period,
                room_type_id, relationship_type, relationship_group_key
              )
              SELECT
                id,
                subject_id,
                COALESCE(periods_per_week, count_per_week, 1),
                COALESCE(teacher_ids, '[]'),
                COALESCE(class_ids, '[]'),
                class_id,
                class_division_id,
                is_pinned,
                fixed_day,
                fixed_period,
                room_type_id,
                relationship_type,
                relationship_group_key
              FROM lessons
            ''');

            await customStatement('DROP TABLE lessons');
            await customStatement('ALTER TABLE lessons_new RENAME TO lessons');
          }
          if (from < 11) {
            await customStatement(
                'ALTER TABLE subjects ADD COLUMN guid TEXT NULL');
            await customStatement(
                'ALTER TABLE classes ADD COLUMN guid TEXT NULL');
            await customStatement(
                'ALTER TABLE teachers ADD COLUMN guid TEXT NULL');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<Map<String, dynamic>?> loadPlannerSnapshot() async {
    final row = await (select(appState)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.plannerJson) as Map<String, dynamic>;
  }

  Future<void> savePlannerSnapshot(Map<String, dynamic> data) async {
    final payload = jsonEncode(data);
    await into(appState).insertOnConflictUpdate(
      AppStateCompanion(
        id: const Value(1),
        plannerJson: Value(payload),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<AnalyticsSnapshot> watchAnalytics() {
    return (select(appState)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null) {
        return const AnalyticsSnapshot(
          totalAssignedLessons: 0,
          hardConflictCount: 0,
          averageTeacherGaps: 0,
        );
      }
      final snap = jsonDecode(row.plannerJson) as Map<String, dynamic>;
      return analyticsFromSnapshot(snap);
    });
  }

  AnalyticsSnapshot analyticsFromSnapshot(Map<String, dynamic> snap) {
    final lessons = ((snap['lessons'] as List?) ?? const []);
    final teachers = ((snap['teachers'] as List?) ?? const []);

    // Joint classes should still count as one lesson row.
    final totalAssignedLessons = lessons.fold<int>(0, (sum, e) {
      final m = Map<String, dynamic>.from(e as Map);
      return sum +
          ((m['periodsPerWeek'] as num?)?.toInt() ??
              (m['countPerWeek'] as num?)?.toInt() ??
              1);
    });

    int hardConflicts = 0;
    for (final e in lessons) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['isPinned'] != true) continue;
      final day = (m['fixedDay'] as num?)?.toInt();
      final period = (m['fixedPeriod'] as num?)?.toInt();
      if (day == null || period == null) continue;
      final key = '$day-$period';
      final tIds =
          ((m['teacherIds'] as List?) ?? const []).map((x) => x.toString());

      for (final t in teachers) {
        final tm = Map<String, dynamic>.from(t as Map);
        final tid = tm['id']?.toString();
        if (tid == null || !tIds.contains(tid)) continue;
        final off =
            Map<String, dynamic>.from((tm['timeOff'] as Map?) ?? const {});
        if ((off[key] as num?)?.toInt() == 1) {
          // 1 => unavailable in persisted map
          hardConflicts++;
        }
      }
    }

    final gaps = <int>[];
    for (final t in teachers) {
      final tm = Map<String, dynamic>.from(t as Map);
      final v = (tm['maxGapsPerDay'] as num?)?.toInt();
      if (v != null) gaps.add(v);
    }
    final avgGaps =
        gaps.isEmpty ? 0.0 : gaps.reduce((a, b) => a + b) / gaps.length;

    return AnalyticsSnapshot(
      totalAssignedLessons: totalAssignedLessons,
      hardConflictCount: hardConflicts,
      averageTeacherGaps: avgGaps,
    );
  }
}
