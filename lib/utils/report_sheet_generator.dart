import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_report_data.dart';

class ReportSheetGenerator {
  static Future<Uint8List> generateClassReports({
    required List<StudentReportData> reports,
    String? schoolLogoBase64,
    required String schoolName,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    Uint8List? logoBytes;
    if (schoolLogoBase64 != null && schoolLogoBase64.contains(',')) {
      logoBytes = base64Decode(schoolLogoBase64.split(',')[1]);
    }

    for (final report in reports) {
      Uint8List? studentBytes;
      if (report.studentImageUrl != null &&
          report.studentImageUrl!.contains(',')) {
        try {
          studentBytes = base64Decode(report.studentImageUrl!.split(',')[1]);
        } catch (e) {
          studentBytes = null;
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Theme(
              data: pw.ThemeData.withFont(base: font, bold: fontBold),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // School Logo
                      if (logoBytes != null)
                        pw.Image(
                          pw.MemoryImage(logoBytes),
                          width: 60,
                          height: 60,
                        )
                      else
                        pw.SizedBox(width: 60, height: 60),

                      // School Info
                      pw.Column(
                        children: [
                          pw.Text(
                            schoolName.toUpperCase(),
                            style: pw.TextStyle(font: fontBold, fontSize: 16),
                          ),
                          pw.Text(
                            'Academic Performance Report',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 13,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            '${report.term} - ${report.session}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                        ],
                      ),

                      // Student Photo
                      if (studentBytes != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Image(
                            pw.MemoryImage(studentBytes),
                            fit: pw.BoxFit.cover,
                          ),
                        )
                      else
                        pw.Container(
                          width: 60,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'No Photo',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),

                  // Student Info Table
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Student Name:',
                              report.studentName,
                              font,
                              fontBold,
                            ),
                            _buildInfoRow(
                              'Student ID:',
                              report.studentId,
                              font,
                              fontBold,
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Class:',
                              '${report.section} - ${report.grade}${report.arm.isNotEmpty ? " (${report.arm})" : ""}',
                              font,
                              fontBold,
                            ),
                            _buildInfoRow(
                              'Position:',
                              report.overallPosition.displayText,
                              font,
                              fontBold,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 24),

                  // Grades Table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          _buildTableCell('SUBJECT', fontBold, isHeader: true),
                          _buildTableCell('CA (30)', fontBold, isHeader: true),
                          _buildTableCell(
                            'EXAM (70)',
                            fontBold,
                            isHeader: true,
                          ),
                          _buildTableCell('TOTAL', fontBold, isHeader: true),
                          _buildTableCell('GRADE', fontBold, isHeader: true),
                          _buildTableCell('POS', fontBold, isHeader: true),
                          _buildTableCell('REMARK', fontBold, isHeader: true),
                        ],
                      ),
                      // Rows
                      ...report.individualGrades.map((g) {
                        final position = report.subjectPositions[g.subject];
                        return pw.TableRow(
                          children: [
                            _buildTableCell(g.subject, font),
                            _buildTableCell(g.caScore.toStringAsFixed(1), font),
                            _buildTableCell(
                              g.examScore.toStringAsFixed(1),
                              font,
                            ),
                            _buildTableCell(
                              g.totalScore.toStringAsFixed(1),
                              fontBold,
                            ),
                            _buildTableCell(g.grade, fontBold),
                            _buildTableCell(position?.ordinal ?? '-', font),
                            _buildTableCell(_getRemark(g.grade), font),
                          ],
                        );
                      }),
                    ],
                  ),

                  pw.SizedBox(height: 24),

                  // Summary Section
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Stats
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RESULT SUMMARY',
                            style: pw.TextStyle(font: fontBold, fontSize: 11),
                          ),
                          pw.SizedBox(height: 6),
                          _buildSummaryRow(
                            'Average Score:',
                            '${report.averageScore.toStringAsFixed(2)}%',
                            font,
                          ),
                          _buildSummaryRow(
                            'Attendance:',
                            '${report.attendancePresent} / ${report.attendanceTotal} Days',
                            font,
                          ),
                        ],
                      ),

                      // Signature blocks
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 20),
                          pw.Container(
                            width: 140,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              'Principal\'s Signature',
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Branding
                  pw.Center(
                    child: pw.Text(
                      'Powered by Kuibit Creative Technologies Ltd.',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 9 : 8),
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
          pw.SizedBox(width: 6),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
        ],
      ),
    );
  }

  static String _getRemark(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Fair';
      case 'E':
        return 'Poor';
      default:
        return 'Fail';
    }
  }
}
