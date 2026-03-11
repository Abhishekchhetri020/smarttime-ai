import '../../../core/database.dart';

sealed class MoveLessonValidatedResult {
  const MoveLessonValidatedResult();
}

class MoveLessonSuccess extends MoveLessonValidatedResult {
  const MoveLessonSuccess();
}

class MoveLessonTeacherConflict extends MoveLessonValidatedResult {
  final String message;
  const MoveLessonTeacherConflict(this.message);
}

class MoveLessonClassConflict extends MoveLessonValidatedResult {
  final String message;
  const MoveLessonClassConflict(this.message);
}

class MoveLessonRoomConflict extends MoveLessonValidatedResult {
  final String message;
  const MoveLessonRoomConflict(this.message);
}

class MoveLessonNotFound extends MoveLessonValidatedResult {
  final String message;
  const MoveLessonNotFound(this.message);
}

class TimetableService {
  Future<MoveLessonValidatedResult> moveLessonValidated(
    AppDatabase db,
    String lessonId,
    String newSlotId,
  ) async {
    return db.transaction(() async {
      final parts = newSlotId.split(':');
      if (parts.length != 2) {
        return const MoveLessonNotFound('Invalid slot target.');
      }
      final dayIndex = int.tryParse(parts[0]);
      final periodIndex = int.tryParse(parts[1]);
      if (dayIndex == null || periodIndex == null) {
        return const MoveLessonNotFound('Invalid slot target.');
      }

      final lesson = await (db.select(db.lessons)
            ..where((t) => t.id.equals(lessonId)))
          .getSingleOrNull();
      if (lesson == null) return const MoveLessonNotFound('Lesson not found.');

      final existingCard = await (db.select(db.cards)
            ..where((t) => t.lessonId.equals(lessonId)))
          .getSingleOrNull();
      if (existingCard == null) {
        return const MoveLessonNotFound('Scheduled card not found.');
      }

      if (existingCard.dayIndex == dayIndex &&
          existingCard.periodIndex == periodIndex) {
        return const MoveLessonSuccess();
      }

      final slotCards = await (db.select(db.cards)
            ..where((t) => t.dayIndex.equals(dayIndex))
            ..where((t) => t.periodIndex.equals(periodIndex))
            ..where((t) => t.lessonId.isNotValue(lessonId)))
          .get();
      if (slotCards.isEmpty) {
        await db.update(db.cards).replace(existingCard.copyWith(
            dayIndex: dayIndex, periodIndex: periodIndex));
        return const MoveLessonSuccess();
      }

      final otherLessonIds = slotCards.map((e) => e.lessonId).toList();
      final otherLessons = await (db.select(db.lessons)
            ..where((t) => t.id.isIn(otherLessonIds)))
          .get();
      final byId = {for (final l in otherLessons) l.id: l};
      final teacherNames = {
        for (final t in await db.select(db.teachers).get())
          t.id: (t.abbreviation.isNotEmpty ? t.abbreviation : t.name),
      };
      final classNames = {
        for (final c in await db.select(db.classes).get())
          c.id: (c.abbr.isNotEmpty ? c.abbr : c.name),
      };

      for (final c in slotCards) {
        final other = byId[c.lessonId];
        if (other == null) continue;
        final teacherConflict =
            lesson.teacherIds.toSet().intersection(other.teacherIds.toSet());
        if (teacherConflict.isNotEmpty) {
          final tid = teacherConflict.first;
          return MoveLessonTeacherConflict(
            "Teacher ${teacherNames[tid] ?? tid} is already assigned on day ${dayIndex + 1}, period ${periodIndex + 1}.",
          );
        }
        final classConflict =
            lesson.classIds.toSet().intersection(other.classIds.toSet());
        if (classConflict.isNotEmpty) {
          final cid = classConflict.first;
          return MoveLessonClassConflict(
            "Class ${classNames[cid] ?? cid} already has a lesson on day ${dayIndex + 1}, period ${periodIndex + 1}.",
          );
        }
        final roomId = existingCard.roomId;
        if (roomId != null && roomId.isNotEmpty && c.roomId == roomId) {
          return MoveLessonRoomConflict(
            'Room $roomId is already occupied on day ${dayIndex + 1}, period ${periodIndex + 1}.',
          );
        }
      }

      await db.update(db.cards).replace(
          existingCard.copyWith(dayIndex: dayIndex, periodIndex: periodIndex));
      return const MoveLessonSuccess();
    });
  }
}
