import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/timetable/presentation/widgets/universal_timetable_grid.dart';
import 'package:smarttime_ai/features/timetable/timetable_display.dart';

void main() {
  test('display catalog resolves raw ids to human-readable labels', () {
    const catalog = TimetableDisplayCatalog(
      roomById: {'room_CLS_XI_A': 'XI A'},
    );

    expect(catalog.subjectLabel('SUB_MATHEMATICS'), 'Mathematics');
    expect(catalog.teacherLabel('TEA_JOHN_DOE'), 'John Doe');
    expect(catalog.classLabel('CLS_XI_A'), 'XI A');
    expect(catalog.roomLabel('room_CLS_XI_A'), 'XI A');
  });

  testWidgets('universal timetable cell keeps secondary text to two lines', (
    tester,
  ) async {
    const cell = TimetableCellData(
      id: 'L1',
      primary: 'Advanced Mathematics',
      secondary: 'Mr. Benedict Prakash Dsouza and Mrs. Saloni Fernandes',
      tertiary: 'Senior Wing',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 152,
            height: 98,
            child: TimetableCell(data: cell),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final secondaryText = tester.widget<Text>(
      find.text('Mr. Benedict Prakash Dsouza and Mrs. Saloni Fernandes'),
    );
    expect(secondaryText.maxLines, 2);
  });
}
