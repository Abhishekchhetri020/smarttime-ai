import 'package:flutter/material.dart';

enum ScheduleEntryType { period, breakTime }

extension ScheduleEntryTypeX on ScheduleEntryType {
  String get jsonValue => this == ScheduleEntryType.period ? 'period' : 'break';

  String get label => this == ScheduleEntryType.period ? 'Period' : 'Break';

  static ScheduleEntryType fromJsonValue(String? value) {
    if (value == 'break') return ScheduleEntryType.breakTime;
    return ScheduleEntryType.period;
  }
}

class ScheduleEntry {
  final String label;
  final TimeOfDay start;
  final TimeOfDay end;
  final ScheduleEntryType type;

  const ScheduleEntry({
    required this.label,
    required this.start,
    required this.end,
    required this.type,
  });

  String get timeRange => '${_fmt(start)}-${_fmt(end)}';

  Map<String, dynamic> toJson() => {
        'label': label,
        'start': _fmt(start),
        'end': _fmt(end),
        'type': type.jsonValue,
      };

  ScheduleEntry copyWith({
    String? label,
    TimeOfDay? start,
    TimeOfDay? end,
    ScheduleEntryType? type,
  }) {
    return ScheduleEntry(
      label: label ?? this.label,
      start: start ?? this.start,
      end: end ?? this.end,
      type: type ?? this.type,
    );
  }

  static ScheduleEntry? fromJson(Map<String, dynamic> json) {
    final start = _parse(json['start']?.toString());
    final end = _parse(json['end']?.toString());
    if (start == null || end == null) return null;
    return ScheduleEntry(
      label: (json['label']?.toString() ?? '').trim().isEmpty
          ? 'Period'
          : json['label'].toString().trim(),
      start: start,
      end: end,
      type: ScheduleEntryTypeX.fromJsonValue(json['type']?.toString()),
    );
  }

  static ScheduleEntry? fromBellTime(String raw, {required int index}) {
    final parts = raw.split('-');
    if (parts.length != 2) return null;
    final start = _parse(parts[0].trim());
    final end = _parse(parts[1].trim());
    if (start == null || end == null) return null;
    return ScheduleEntry(
      label: 'Period ${index + 1}',
      start: start,
      end: end,
      type: ScheduleEntryType.period,
    );
  }

  static String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null || h < 0 || h > 23 || min < 0 || min > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: min);
  }
}
