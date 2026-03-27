import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'planner_state.dart';
import 'schedule_entry.dart';
import '../timetable/presentation/widgets/universal_timetable_grid.dart';
import '../../core/services/pdf_export_service.dart';

class LessonsBuilderScreen extends StatefulWidget {
  const LessonsBuilderScreen({super.key});

  @override
  State<LessonsBuilderScreen> createState() => _LessonsBuilderScreenState();
}

class _LessonsBuilderScreenState extends State<LessonsBuilderScreen> {
  ViewMode _viewMode = ViewMode.classView;
  String? _selectedId; // ID for the current view pivot (teacherId or classId)

  final Color motherSage = const Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();

    // Prepare labels and selection based on mode
    List<DropdownMenuItem<String>> pivotItems = [];
    if (_viewMode == ViewMode.teacher) {
      pivotItems = planner.teachers
          .map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName)))
          .toList();
    } else if (_viewMode == ViewMode.classView) {
      pivotItems = planner.classes
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList();
    } else {
      pivotItems = planner.classrooms
          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
          .toList();
    }

    if (_selectedId == null && pivotItems.isNotEmpty) {
      _selectedId = pivotItems.first.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Grid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Export to PDF',
            onPressed: () => PdfExportService().exportTimetable(planner),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Legacy PDF Export',
            onPressed: () => _handleExportPdf(context, planner),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: motherSage.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SegmentedButton<ViewMode>(
                  segments: const [
                    ButtonSegment(value: ViewMode.classView, label: Text('Class')),
                    ButtonSegment(value: ViewMode.teacher, label: Text('Teacher')),
                    ButtonSegment(value: ViewMode.room, label: Text('Room')),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (v) => setState(() {
                    _viewMode = v.first;
                    _selectedId = null;
                  }),
                ),
                const SizedBox(width: 16),
                if (pivotItems.isNotEmpty)
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedId,
                      isExpanded: true,
                      items: pivotItems,
                      onChanged: (v) => setState(() => _selectedId = v),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: UniversalTimetableGrid(
              viewMode: _viewMode,
              rowLabels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].sublist(0, planner.workingDays),
              periods: planner.scheduleEntries.map((e) => PeriodSlot(
                id: e.id,
                label: e.label,
                isBreak: e.type == ScheduleEntryType.breakTime,
              )).toList(),
              cells: _buildCells(planner),
              onMoveCell: (lessonId, row, col) async {
                await planner.pinLessonToSlot(lessonId: lessonId, day: row, period: col);
                return null;
              },
              onValidateMove: (lessonId, row, col) {
                final targetLessonIdx = planner.lessons.indexWhere((l) => l.id == lessonId);
                if (targetLessonIdx < 0) return false;
                final targetLesson = planner.lessons[targetLessonIdx];

                // Check for conflicts with already pinned lessons at this day/period
                for (final otherLesson in planner.lessons) {
                  if (otherLesson.id == lessonId) continue;
                  if (!otherLesson.isPinned) continue;
                  if (otherLesson.fixedDay != row || otherLesson.fixedPeriod != col) continue;

                  // Teacher conflict
                  for (final tId in targetLesson.teacherIds) {
                    if (otherLesson.teacherIds.contains(tId)) return false;
                  }

                  // Class conflict
                  for (final cId in targetLesson.classIds) {
                    if (otherLesson.classIds.contains(cId)) return false;
                  }

                  // Room conflict (if both require the same specific room)
                  if (targetLesson.requiredClassroomId != null &&
                      otherLesson.requiredClassroomId != null &&
                      targetLesson.requiredClassroomId == otherLesson.requiredClassroomId) {
                    return false;
                  }
                }
                return true;
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: motherSage,
        onPressed: () => _showAddLessonSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Map<String, TimetableCellData> _buildCells(PlannerState planner) {
    final Map<String, TimetableCellData> cells = {};
    
    for (final lesson in planner.lessons) {
      if (!lesson.isPinned) continue;
      final day = lesson.fixedDay;
      final period = lesson.fixedPeriod;
      if (day == null || period == null) continue;

      // Only show if it matches the current pivot view
      bool shouldShow = false;
      if (_viewMode == ViewMode.teacher) {
        shouldShow = lesson.teacherIds.contains(_selectedId);
      } else if (_viewMode == ViewMode.classView) {
        shouldShow = lesson.classIds.contains(_selectedId);
      } else if (_viewMode == ViewMode.room) {
        shouldShow = lesson.requiredClassroomId == _selectedId;
      }

      if (shouldShow) {
        // Find names for display
        final subject = planner.subjects.firstWhere((s) => s.id == lesson.subjectId, orElse: () => SubjectItem(name: 'Unknown', abbr: 'UNK', color: 0)).name;
        
        String secondary = '';
        if (_viewMode == ViewMode.teacher) {
           secondary = lesson.classIds.map((cid) => planner.classes.firstWhere((c) => c.id == cid, orElse: () => ClassItem(name: 'Unknown', abbr: 'UNK')).abbr).join(', ');
        } else if (_viewMode == ViewMode.classView) {
           secondary = lesson.teacherIds.map((tid) => planner.teachers.firstWhere((t) => t.id == tid, orElse: () => TeacherItem(firstName: 'Unknown', lastName: '', abbr: 'UNK')).abbr).join(', ');
        }

        String? tertiary;
        if (lesson.requiredClassroomId != null) {
          tertiary = planner.classrooms.firstWhere((r) => r.id == lesson.requiredClassroomId, orElse: () => ClassroomItem(name: 'Unknown')).name;
        }

        cells['$day|$period'] = TimetableCellData(
          id: lesson.id,
          primary: subject,
          secondary: secondary,
          tertiary: tertiary,
          accent: Color(planner.subjects.firstWhere((s) => s.id == lesson.subjectId, orElse: () => SubjectItem(name: 'Unknown', abbr: 'UNK', color: 0xFF4F46E5)).color),
        );
      }
    }
    
    return cells;
  }

  void _handleExportPdf(BuildContext context, PlannerState planner) async {
    final pdfBytes = await generateTimetablePdf(planner);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${planner.schoolName}_Timetable.pdf',
    );
  }

  void _showAddLessonSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Lesson functionality would open here.')),
    );
  }
}

Future<Uint8List> generateTimetablePdf(PlannerState planner) async {
  final pdf = pw.Document();
  final motherSageColor = PdfColor.fromInt(0xFF4F46E5);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      header: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Text(
          'Timetable: ${planner.schoolName}',
          style: pw.TextStyle(color: motherSageColor, fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
      ),
      footer: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by SmartTime AI', style: const pw.TextStyle(fontSize: 10)),
            pw.Column(
              children: [
                pw.Text('GD Goenka Public School', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Academic Excellence', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
      build: (pw.Context context) => [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: motherSageColor),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Day / Period', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                ),
                ...planner.scheduleEntries.map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(e.label, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                    )),
              ],
            ),
            ...List.generate(planner.workingDays, (dayIdx) {
              final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][dayIdx];
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(dayName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  ...planner.scheduleEntries.map((period) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(''),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}
