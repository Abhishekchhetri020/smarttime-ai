import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/data/timetable_pdf_service.dart';
import 'package:smarttime_ai/features/timetable/presentation/controllers/solver_controller.dart';
import 'package:smarttime_ai/features/timetable/timetable_display.dart';

void main() {
  test('pdf service renders basic 5x8 colored grid', () async {
    final service = TimetablePdfService();
    const assignments = [
      TimetableAssignment(
        lessonId: 'L1',
        day: 1,
        period: 1,
        subjectId: 'MATH',
        classIds: ['C1'],
        teacherIds: ['T1'],
      ),
    ];

    final bytes = await service.buildMasterGridPdf(
      assignments: assignments,
      days: 5,
      periodsPerDay: 8,
      title: 'Test Grid',
    );

    expect(bytes.isNotEmpty, isTrue);
    expect(bytes.length, greaterThan(1000));
  });

  test('pdf cell text keeps strict two-line subject and secondary output', () {
    expect(
      pdfCellText(subject: 'Mathematics', secondary: 'Mrs. Dsouza'),
      'Mathematics\nMrs. Dsouza',
    );
    expect(
      pdfCellText(subject: 'RECESS', secondary: ''),
      'RECESS',
    );
  });

  test('timetable slots preserve break entries as distinct rows', () {
    final slots = buildTimetableSlots(
      plannerSnapshot: {
        'scheduleEntries': [
          {
            'label': 'Period 1',
            'start': '08:00',
            'end': '08:45',
            'type': 'period',
          },
          {
            'label': 'RECESS',
            'start': '08:45',
            'end': '09:00',
            'type': 'break',
          },
          {
            'label': 'Period 2',
            'start': '09:00',
            'end': '09:45',
            'type': 'period',
          },
        ],
      },
      usedPeriodIndexes: const [0, 1],
    );

    expect(slots, hasLength(3));
    expect(slots[1].isBreak, isTrue);
    expect(slots[1].label, 'RECESS');
    expect(slots[0].periodIndex, 0);
    expect(slots[2].periodIndex, 1);
  });
}
