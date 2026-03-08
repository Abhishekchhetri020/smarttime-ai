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

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get abbr => text()();
  TextColumn get groupId => text().nullable()();
  IntColumn get roomTypeId => integer().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0xFF0B3D91))();

  @override
  Set<Column> get primaryKey => {id};
}

class Classes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get abbr => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class ClassDivisions extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text().references(Classes, #id)();
  TextColumn get name => text()();
  TextColumn get code => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get classId => text().nullable()();
  TextColumn get classDivisionId => text().nullable().references(ClassDivisions, #id)();
  IntColumn get countPerWeek => integer().withDefault(const Constant(1))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get fixedDay => integer().nullable()();
  IntColumn get fixedPeriod => integer().nullable()();
  IntColumn get roomTypeId => integer().nullable()();
  IntColumn get relationshipType => integer().withDefault(const Constant(0))();
  TextColumn get relationshipGroupKey => text().nullable()();

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
  TextColumn get teacherId => text()();

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
    ClassDivisions,
    Lessons,
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
  int get schemaVersion => 7;

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
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<Map<String, dynamic>?> loadPlannerSnapshot() async {
    final row = await (select(appState)..where((t) => t.id.equals(1))).getSingleOrNull();
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
    return (select(appState)..where((t) => t.id.equals(1))).watchSingleOrNull().map((row) {
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
      return sum + ((m['countPerWeek'] as num?)?.toInt() ?? 1);
    });

    int hardConflicts = 0;
    for (final e in lessons) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['isPinned'] != true) continue;
      final day = (m['fixedDay'] as num?)?.toInt();
      final period = (m['fixedPeriod'] as num?)?.toInt();
      if (day == null || period == null) continue;
      final key = '$day-$period';
      final tIds = ((m['teacherIds'] as List?) ?? const []).map((x) => x.toString());

      for (final t in teachers) {
        final tm = Map<String, dynamic>.from(t as Map);
        final tid = tm['id']?.toString();
        if (tid == null || !tIds.contains(tid)) continue;
        final off = Map<String, dynamic>.from((tm['timeOff'] as Map?) ?? const {});
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
    final avgGaps = gaps.isEmpty ? 0.0 : gaps.reduce((a, b) => a + b) / gaps.length;

    return AnalyticsSnapshot(
      totalAssignedLessons: totalAssignedLessons,
      hardConflictCount: hardConflicts,
      averageTeacherGaps: avgGaps,
    );
  }
}
