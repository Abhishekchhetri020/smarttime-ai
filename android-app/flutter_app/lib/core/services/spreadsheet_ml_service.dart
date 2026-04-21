import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/admin/planner_state.dart';

/// Zero-dependency Excel generator using Microsoft SpreadsheetML (XML).
/// Matches ASC's approach for lightweight, styled report generation.
class SpreadsheetMlService {
  Future<void> exportTeacherWorkloads(PlannerState planner) async {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0"?>');
    sb.writeln('<?mso-application progid="Excel.Sheet"?>');
    sb.writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
    sb.writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"');
    sb.writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
    sb.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"');
    sb.writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">');

    // ── Styles ──
    sb.writeln(' <Styles>');
    sb.writeln('  <Style ss:ID="Default" ss:Name="Normal">');
    sb.writeln('   <Alignment ss:Vertical="Bottom"/>');
    sb.writeln('   <Borders/>');
    sb.writeln('   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>');
    sb.writeln('   <Interior/>');
    sb.writeln('   <NumberFormat/>');
    sb.writeln('   <Protection/>');
    sb.writeln('  </Style>');
    sb.writeln('  <Style ss:ID="sHeader">');
    sb.writeln('   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="12" ss:Color="#FFFFFF" ss:Bold="1"/>');
    sb.writeln('   <Interior ss:Color="#4F46E5" ss:Pattern="Solid"/>');
    sb.writeln('  </Style>');
    sb.writeln(' </Styles>');

    // ── Worksheet ──
    sb.writeln(' <Worksheet ss:Name="Teacher Workloads">');
    sb.writeln('  <Table>');
    sb.writeln('   <Row ss:Height="20">');
    sb.writeln('    <Cell ss:StyleID="sHeader"><Data ss:Type="String">Teacher Name</Data></Cell>');
    sb.writeln('    <Cell ss:StyleID="sHeader"><Data ss:Type="String">Abbreviation</Data></Cell>');
    sb.writeln('    <Cell ss:StyleID="sHeader"><Data ss:Type="String">Total Lessons</Data></Cell>');
    sb.writeln('   </Row>');

    for (final teacher in planner.teachers) {
      final totalLessons = planner.lessons
          .where((l) => l.teacherIds.contains(teacher.id))
          .fold<double>(0.0, (sum, l) => sum + (l.periodsPerWeek.toDouble()))
          .toInt();

      sb.writeln('   <Row>');
      sb.writeln('    <Cell><Data ss:Type="String">${teacher.firstName} ${teacher.lastName}</Data></Cell>');
      sb.writeln('    <Cell><Data ss:Type="String">${teacher.abbreviation}</Data></Cell>');
      sb.writeln('    <Cell><Data ss:Type="Number">$totalLessons</Data></Cell>');
      sb.writeln('   </Row>');
    }

    sb.writeln('  </Table>');
    sb.writeln(' </Worksheet>');
    sb.writeln('</Workbook>');

    // ── Save and Share ──
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Teacher_Workloads.xml');
    await file.writeAsString(sb.toString());

    await Share.shareXFiles([XFile(file.path)], subject: 'Teacher Workloads Export');
  }
}
