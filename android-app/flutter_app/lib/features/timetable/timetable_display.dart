import '../../core/database.dart';

class TimetableSlotDescriptor {
  final String id;
  final String label;
  final bool isBreak;
  final int? periodIndex;

  /// Time range string, e.g. '7:40 - 8:20'. Null if not available.
  final String? timeRange;

  const TimetableSlotDescriptor({
    required this.id,
    required this.label,
    this.isBreak = false,
    this.periodIndex,
    this.timeRange,
  });
}

class TimetableDisplayCatalog {
  final Map<String, String> subjectById;
  final Map<String, int> subjectColorById;
  final Map<String, String> teacherById;
  final Map<String, String> classById;
  final Map<String, String> roomById;

  const TimetableDisplayCatalog({
    this.subjectById = const {},
    this.subjectColorById = const {},
    this.teacherById = const {},
    this.classById = const {},
    this.roomById = const {},
  });

  factory TimetableDisplayCatalog.fromDatabase({
    required List<SubjectRow> subjects,
    required List<TeacherRow> teachers,
    required List<ClassRow> classes,
    Map<String, dynamic>? plannerSnapshot,
  }) {
    return TimetableDisplayCatalog(
      subjectById: {
        for (final s in subjects)
          s.id: _bestLabel(primary: s.abbr, secondary: s.name, rawId: s.id),
      },
      subjectColorById: {for (final s in subjects) s.id: s.color},
      teacherById: {
        for (final t in teachers)
          t.id: _bestLabel(
            primary: t.abbreviation,
            secondary: t.name,
            rawId: t.id,
          ),
      },
      classById: {
        for (final c in classes)
          c.id: _bestLabel(primary: c.abbr, secondary: c.name, rawId: c.id),
      },
      roomById: _roomMapFromPlannerSnapshot(plannerSnapshot),
    );
  }

  String subjectLabel(String subjectId) =>
      _bestLabel(primary: subjectById[subjectId], rawId: subjectId);

  String teacherLabel(String teacherId) =>
      _bestLabel(primary: teacherById[teacherId], rawId: teacherId);

  String classLabel(String classId) =>
      _bestLabel(primary: classById[classId], rawId: classId);

  String joinTeacherLabels(List<String> teacherIds) => _joinResolved(
        teacherIds.map(teacherLabel),
      );

  String joinClassLabels(List<String> classIds) => _joinResolved(
        classIds.map(classLabel),
      );

  String? roomLabel(String? roomId) {
    final value = roomId?.trim() ?? '';
    if (value.isEmpty) return null;
    final direct = roomById[value];
    final resolved = _bestLabel(primary: direct, rawId: value);
    return resolved.isEmpty ? null : resolved;
  }

  int? subjectColor(String subjectId) => subjectColorById[subjectId];
}

List<TimetableSlotDescriptor> buildTimetableSlots({
  required Map<String, dynamic>? plannerSnapshot,
  required Iterable<int> usedPeriodIndexes,
}) {
  final entries = ((plannerSnapshot?['scheduleEntries'] as List?) ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  if (entries.isNotEmpty) {
    final slots = <TimetableSlotDescriptor>[];
    var periodIndex = 0;
    for (final entry in entries) {
      final type = (entry['type']?.toString() ?? '').toLowerCase();
      final label = (entry['label']?.toString() ?? '').trim();
      final start = (entry['start']?.toString() ?? '').trim();
      final end = (entry['end']?.toString() ?? '').trim();
      final timeRange = start.isNotEmpty && end.isNotEmpty ? '$start-$end' : '';
      final display = label.isNotEmpty ? label : timeRange;
      if (type == 'break') {
        slots.add(
          TimetableSlotDescriptor(
            id: 'break_${slots.length}',
            label: display.isNotEmpty ? display : 'Break',
            isBreak: true,
            timeRange: timeRange.isNotEmpty ? timeRange : null,
          ),
        );
        continue;
      }
      slots.add(
        TimetableSlotDescriptor(
          id: 'period_${periodIndex + 1}',
          label: display.isNotEmpty ? display : 'P${periodIndex + 1}',
          periodIndex: periodIndex,
          timeRange: timeRange.isNotEmpty ? timeRange : null,
        ),
      );
      periodIndex++;
    }
    if (slots.any((slot) => slot.periodIndex != null)) {
      return slots;
    }
  }

  final maxPeriodIndex = usedPeriodIndexes.fold<int>(
      -1, (max, value) => value > max ? value : max);
  final count = (maxPeriodIndex + 1).clamp(1, 12);
  return List.generate(
    count,
    (index) => TimetableSlotDescriptor(
      id: 'period_${index + 1}',
      label: 'P${index + 1}',
      periodIndex: index,
    ),
    growable: false,
  );
}

bool looksLikeRawTimetableId(String value) {
  final v = value.trim();
  if (v.isEmpty) return true;
  return RegExp(r'^(SUB|CLS|TEA|LS|room)_[A-Z0-9_]+$').hasMatch(v) ||
      RegExp(r'^[A-Za-z]+:[A-Za-z0-9_:-]+$').hasMatch(v);
}

String humanizeTimetableId(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return '';

  if (value.startsWith('room_')) {
    value = value.replaceFirst('room_', '');
  }
  final prefixed = RegExp(r'^(SUB|CLS|TEA|LS)_(.+)$').firstMatch(value);
  if (prefixed != null) {
    value = prefixed.group(2) ?? value;
  } else if (value.contains(':')) {
    value = value.split(':').last;
  }

  value = value
      .replaceAll(RegExp(r'[_:-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (value.isEmpty) return '';
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(_humanizeToken)
      .join(' ');
}

String _bestLabel({
  String? primary,
  String? secondary,
  required String rawId,
}) {
  for (final candidate in [primary, secondary]) {
    final trimmed = candidate?.trim() ?? '';
    if (trimmed.isNotEmpty && !looksLikeRawTimetableId(trimmed)) {
      return trimmed;
    }
  }

  final humanized = humanizeTimetableId(rawId);
  if (humanized.isNotEmpty && humanized != rawId.trim()) {
    return humanized;
  }

  return looksLikeRawTimetableId(rawId) ? '' : rawId.trim();
}

Map<String, String> _roomMapFromPlannerSnapshot(
    Map<String, dynamic>? snapshot) {
  return {
    for (final room
        in ((snapshot?['classrooms'] as List?) ?? const []).whereType<Map>())
      if ((room['id']?.toString() ?? '').trim().isNotEmpty)
        room['id'].toString().trim(): _bestLabel(
          primary: room['name']?.toString(),
          rawId: room['id'].toString(),
        ),
  };
}

String _joinResolved(Iterable<String> values) {
  final cleaned = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
  return cleaned.join(', ');
}

String _humanizeToken(String token) {
  if (token.isEmpty) return token;
  // If it's literally just a roman numeral like "IV" or "XI"
  final upper = token.toUpperCase();
  if (RegExp(r'^[IVXLCDM]+$').hasMatch(upper)) return upper;

  // If it has digits, keep it upper (like "1A", "C2")
  if (RegExp(r'\d').hasMatch(token)) return upper;

  // Otherwise treat as a normal word: Capitalize first, lowercase rest
  final lower = token.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}
