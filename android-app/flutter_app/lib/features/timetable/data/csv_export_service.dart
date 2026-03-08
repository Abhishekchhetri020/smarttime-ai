import '../presentation/controllers/solver_controller.dart';

class CsvExportService {
  String buildAssignmentsCsv(List<TimetableAssignment> assignments) {
    final rows = <List<String>>[
      ['Day', 'Period', 'Subject', 'Teacher', 'Class', 'Room']
    ];

    for (final a in assignments) {
      rows.add([
        a.day.toString(),
        a.period.toString(),
        a.subjectId,
        a.teacherIds.join('|'),
        a.classIds.join('|'),
        a.roomId.isEmpty ? '-' : a.roomId,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}

class ListToCsvConverter {
  const ListToCsvConverter();

  String convert(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      final encoded = row.map(_escape).join(',');
      buffer.writeln(encoded);
    }
    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
