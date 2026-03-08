import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/data/timetable_pdf_service.dart';
import 'package:smarttime_ai/features/timetable/presentation/controllers/solver_controller.dart';

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
}
