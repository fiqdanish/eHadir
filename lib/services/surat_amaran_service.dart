import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Warning-letter tier, derived from the student's attendance percentage.
/// Mirrors the at-risk chips in Module 3 (< 95% / < 90% / < 80%).
enum AmaranTier { pertama, kedua, ketiga }

extension AmaranTierX on AmaranTier {
  String get label {
    switch (this) {
      case AmaranTier.pertama: return 'AMARAN PERTAMA';
      case AmaranTier.kedua:   return 'AMARAN KEDUA';
      case AmaranTier.ketiga:  return 'AMARAN TERAKHIR';
    }
  }

  String get refCode {
    switch (this) {
      case AmaranTier.pertama: return 'A1';
      case AmaranTier.kedua:   return 'A2';
      case AmaranTier.ketiga:  return 'A3';
    }
  }

  static AmaranTier fromPercentage(double pct) {
    if (pct < 80) return AmaranTier.ketiga;
    if (pct < 90) return AmaranTier.kedua;
    return AmaranTier.pertama;
  }
}

/// Generates the official "Surat Amaran Kehadiran" PDF that a Pensyarah
/// downloads from the Module 3 at-risk list and hands to the student.
class SuratAmaranService {
  static final _dateFmt = DateFormat('dd MMMM yyyy');

  /// Builds the PDF and opens the platform print/preview dialog so the
  /// lecturer can save it as PDF or print it directly.
  Future<void> printSuratAmaran({
    required String studentName,
    required String studentClass,
    required String subjectName,
    required String subjectCode,
    required double percentage,
    required int absentCount,
    required String lecturerName,
    required String program,
  }) async {
    final bytes = await buildPdf(
      studentName: studentName,
      studentClass: studentClass,
      subjectName: subjectName,
      subjectCode: subjectCode,
      percentage: percentage,
      absentCount: absentCount,
      lecturerName: lecturerName,
      program: program,
    );
    final tier = AmaranTierX.fromPercentage(percentage);
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'Surat_Amaran_${tier.refCode}_'
          '${studentName.replaceAll(RegExp(r'\s+'), '_')}.pdf',
    );
  }

  Future<Uint8List> buildPdf({
    required String studentName,
    required String studentClass,
    required String subjectName,
    required String subjectCode,
    required double percentage,
    required int absentCount,
    required String lecturerName,
    required String program,
  }) async {
    final tier = AmaranTierX.fromPercentage(percentage);
    final now = DateTime.now();
    final refNo = 'IKMJB/HEP/${tier.refCode}/'
        '${now.year}/${now.millisecondsSinceEpoch % 10000}';

    // Built-in Helvetica is fine — the letter is Malay (Latin script), so no
    // network font fetch is needed and the PDF generates fully offline.
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(56, 48, 56, 48),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ─── Letterhead ───────────────────────────────
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('INSTITUT KEMAHIRAN MARA JOHOR BAHRU',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                      'KM 10, Jalan Kong Kong, 81750 Masai, Johor Bahru, Johor',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 2),
                  pw.Text('Sistem eHadir — Modul Pelaporan Kehadiran',
                      style: pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 12),

            // ─── Ref + date ───────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ruj. Kami: $refNo',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Tarikh: ${_dateFmt.format(now)}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 18),

            // ─── Addressee ────────────────────────────────
            pw.Text(studentName.toUpperCase(),
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.Text('Kelas: $studentClass',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Program: $program',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 16),

            pw.Text('Saudara/Saudari,',
                style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 10),

            // ─── Subject line ─────────────────────────────
            pw.Text(
              'SURAT ${tier.label}: KEHADIRAN KULIAH TIDAK MEMUASKAN — '
              '$subjectCode $subjectName'.toUpperCase(),
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  decoration: pw.TextDecoration.underline),
            ),
            pw.SizedBox(height: 14),

            // ─── Body ─────────────────────────────────────
            pw.Text(
              'Dengan segala hormatnya perkara di atas adalah dirujuk.',
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '2.  Adalah dimaklumkan bahawa rekod kehadiran saudara/saudari '
              'bagi subjek $subjectCode $subjectName setakat '
              '${_dateFmt.format(now)} adalah seperti berikut:',
              style: const pw.TextStyle(fontSize: 10.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 10),

            // ─── Attendance table ─────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: .5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _row('Peratus Kehadiran', '${percentage.toStringAsFixed(0)}%',
                    bold: true),
                _row('Bilangan Sesi Tidak Hadir (T)', '$absentCount sesi'),
                _row('Tahap Amaran', tier.label),
              ],
            ),
            pw.SizedBox(height: 12),

            pw.Text(
              '3.  Kehadiran saudara/saudari berada di bawah tahap minimum '
              '80% yang ditetapkan oleh pihak Institut. '
              '${tier == AmaranTier.ketiga ? 'Ini merupakan amaran terakhir. Kegagalan memperbaiki kehadiran boleh menyebabkan saudara/saudari TIDAK LAYAK menduduki penilaian akhir dan boleh dikenakan tindakan tatatertib selanjutnya.' : tier == AmaranTier.kedua ? 'Sekiranya tiada penambahbaikan, surat amaran terakhir akan dikeluarkan dan perkara ini akan dipanjangkan kepada Ketua Program dan Ketua Jabatan.' : 'Saudara/saudari adalah dinasihatkan untuk memperbaiki kehadiran dengan kadar segera bagi mengelakkan tindakan susulan.'}',
              style: const pw.TextStyle(fontSize: 10.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '4.  Sebarang pertanyaan boleh diajukan terus kepada pensyarah '
              'subjek berkenaan.',
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Sekian, terima kasih.',
                style: const pw.TextStyle(fontSize: 10.5)),
            pw.SizedBox(height: 24),

            // ─── Signatures ───────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Dikeluarkan oleh:',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 36),
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                  top: pw.BorderSide(width: .8)))),
                      pw.SizedBox(height: 4),
                      pw.Text(lecturerName,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Pensyarah, $subjectCode',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Pengesahan penerimaan pelajar:',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 36),
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                  top: pw.BorderSide(width: .8)))),
                      pw.SizedBox(height: 4),
                      pw.Text(studentName,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Tarikh: ______________________',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400, thickness: .5),
            pw.Text(
              'Surat ini dijana secara automatik oleh sistem eHadir '
              'berdasarkan rekod kehadiran M1–M14.',
              style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.TableRow _row(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.TableRow(children: [
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: style)),
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: style)),
    ]);
  }
}

final suratAmaranServiceProvider =
    Provider<SuratAmaranService>((ref) => SuratAmaranService());
