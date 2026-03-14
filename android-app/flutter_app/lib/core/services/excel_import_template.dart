// Excel Import Template Generator — creates downloadable .xlsx templates
// with validation headers, example data, and color-coded instruction rows.

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelImportTemplateService {
  static const _headerBgHex = '7B906F';
  static const _headerFontHex = 'FFFFFF';
  static const _instructionBgHex = 'FFF3CD';
  static const _exampleBgHex = 'E8F5E9';

  /// Generate and share the import template .xlsx
  Future<void> generateAndShare() async {
    final bytes = generateTemplate();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartTime_Import_Template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      text: 'SmartTime AI Import Template',
    );
  }

  /// Generate the template bytes.
  Uint8List generateTemplate() {
    final excel = Excel.createExcel();

    _buildLessonsSheet(excel);
    _buildTeachersSheet(excel);
    _buildClassesSheet(excel);
    _buildSubjectsSheet(excel);
    _buildRoomsSheet(excel);

    // Remove default Sheet1
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw StateError('Failed to encode template');
    return Uint8List.fromList(encoded);
  }

  void _buildLessonsSheet(Excel excel) {
    final sheet = excel['Lessons'];

    // Instruction row
    _instructionCell(sheet, 0, 0, 'INSTRUCTIONS: Fill in one row per lesson. '
        'lesson_id is optional (auto-generated if blank). '
        'teacher_name must match the Teachers sheet. '
        'class_name must match the Classes sheet. '
        'subject_name must match the Subjects sheet.');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
    );

    // Headers
    final headers = [
      'lesson_id',
      'class_name',
      'subject_name',
      'teacher_name',
      'weekly_lessons',
      'lesson_length',
      'preferred_room',
    ];
    for (int i = 0; i < headers.length; i++) {
      _headerCell(sheet, 1, i, headers[i]);
    }

    // Example rows
    final examples = [
      ['L001', 'Grade 10', 'Mathematics', 'Aarav Sharma', '6', 'single', 'Room 101'],
      ['L002', 'Grade 10', 'Science', 'Priya Verma', '2', 'double', 'Science Lab'],
      ['L003', 'Grade 10', 'English', 'Ravi Kumar', '5', 'single', ''],
      ['L004', 'Grade 11', 'Physics', 'Priya Verma', '4', 'single', 'Physics Lab'],
      ['L005', 'Grade 11', 'Mathematics', 'Aarav Sharma', '5', 'single', 'Room 201'],
    ];
    for (int r = 0; r < examples.length; r++) {
      for (int c = 0; c < examples[r].length; c++) {
        _exampleCell(sheet, r + 2, c, examples[r][c]);
      }
    }

    // Column widths
    final widths = [12.0, 18.0, 18.0, 22.0, 14.0, 14.0, 18.0];
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  void _buildTeachersSheet(Excel excel) {
    final sheet = excel['Teachers'];

    _instructionCell(sheet, 0, 0, 'INSTRUCTIONS: One row per teacher. '
        'teacher_name must be unique. off_days: comma-separated day names. '
        'off_slots: comma-separated "Day-Period" pairs. '
        'max_periods_per_day and max_gaps_per_day are optional.');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );

    final headers = [
      'teacher_name',
      'teacher_abbr',
      'off_days',
      'off_slots',
      'max_periods_per_day',
      'max_gaps_per_day',
    ];
    for (int i = 0; i < headers.length; i++) {
      _headerCell(sheet, 1, i, headers[i]);
    }

    final examples = [
      ['Aarav Sharma', 'AS', '', 'Mon-7,Fri-8', '6', '2'],
      ['Priya Verma', 'PV', 'Saturday', '', '7', '3'],
      ['Ravi Kumar', 'RK', '', '', '8', '2'],
    ];
    for (int r = 0; r < examples.length; r++) {
      for (int c = 0; c < examples[r].length; c++) {
        _exampleCell(sheet, r + 2, c, examples[r][c]);
      }
    }

    final widths = [22.0, 14.0, 16.0, 22.0, 18.0, 16.0];
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  void _buildClassesSheet(Excel excel) {
    final sheet = excel['Classes'];

    _instructionCell(sheet, 0, 0, 'INSTRUCTIONS: One row per class. '
        'class_name must match the names used in the Lessons sheet.');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
    );

    final headers = ['class_name', 'class_abbr', 'strength'];
    for (int i = 0; i < headers.length; i++) {
      _headerCell(sheet, 1, i, headers[i]);
    }

    final examples = [
      ['Grade 10', '10', '45'],
      ['Grade 11', '11', '40'],
      ['Grade 12', '12', '35'],
    ];
    for (int r = 0; r < examples.length; r++) {
      for (int c = 0; c < examples[r].length; c++) {
        _exampleCell(sheet, r + 2, c, examples[r][c]);
      }
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 12);
  }

  void _buildSubjectsSheet(Excel excel) {
    final sheet = excel['Subjects'];

    _instructionCell(sheet, 0, 0, 'INSTRUCTIONS: One row per subject. '
        'subject_name must match the names used in the Lessons sheet. '
        'group_id groups related subjects (e.g., "Science" for Physics, Chemistry, Bio).');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );

    final headers = ['subject_name', 'subject_abbr', 'group_id', 'requires_lab'];
    for (int i = 0; i < headers.length; i++) {
      _headerCell(sheet, 1, i, headers[i]);
    }

    final examples = [
      ['Mathematics', 'Math', '', 'no'],
      ['Science', 'Sci', 'Science', 'yes'],
      ['English', 'Eng', 'Language', 'no'],
      ['Physics', 'Phy', 'Science', 'yes'],
      ['Hindi', 'Hin', 'Language', 'no'],
    ];
    for (int r = 0; r < examples.length; r++) {
      for (int c = 0; c < examples[r].length; c++) {
        _exampleCell(sheet, r + 2, c, examples[r][c]);
      }
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 14);
  }

  void _buildRoomsSheet(Excel excel) {
    final sheet = excel['Rooms'];

    _instructionCell(sheet, 0, 0, 'INSTRUCTIONS: One row per room. '
        'room_type: standard, lab, computer, art, sports. '
        'capacity is the maximum students.');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
    );

    final headers = ['room_name', 'room_type', 'capacity'];
    for (int i = 0; i < headers.length; i++) {
      _headerCell(sheet, 1, i, headers[i]);
    }

    final examples = [
      ['Room 101', 'standard', '50'],
      ['Room 201', 'standard', '45'],
      ['Science Lab', 'lab', '30'],
      ['Physics Lab', 'lab', '30'],
      ['Computer Lab', 'computer', '40'],
    ];
    for (int r = 0; r < examples.length; r++) {
      for (int c = 0; c < examples[r].length; c++) {
        _exampleCell(sheet, r + 2, c, examples[r][c]);
      }
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 12);
  }

  // ── Cell styling helpers ──

  void _headerCell(Sheet sheet, int row, int col, String text) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#$_headerFontHex'),
      backgroundColorHex: ExcelColor.fromHexString('#$_headerBgHex'),
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  void _instructionCell(Sheet sheet, int row, int col, String text) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      fontSize: 9,
      italic: true,
      backgroundColorHex: ExcelColor.fromHexString('#$_instructionBgHex'),
      textWrapping: TextWrapping.WrapText,
    );
  }

  void _exampleCell(Sheet sheet, int row, int col, String text) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      fontSize: 9,
      backgroundColorHex: ExcelColor.fromHexString('#$_exampleBgHex'),
    );
  }
}
