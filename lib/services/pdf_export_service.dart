import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  static Future<Uint8List> generateRecordPdf({
    required String title,
    required Map<String, dynamic> record,
    String logoAssetPath = 'assets/pasadaLogoUpdated_Black.png',
    String? postScript,
  }) async {
    final pdf = pw.Document();

    // Load logo
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load(logoAssetPath);
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // Build key-value rows
    List<pw.Widget> rows = [];
    record.forEach((key, value) {
      rows.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  _humanizeKey(key),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 7,
                child: pw.Text(value?.toString() ?? '—'),
              ),
            ],
          ),
        ),
      );
      rows.add(pw.Divider(height: 8, thickness: 0.2));
    });

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 60),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PASADA', style: pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
                pw.Text('Confidential - For Internal Use Only', style: pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Header with logo and title
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Center(
                  child: pw.Image(logo, height: 48),
                ),
              pw.SizedBox(height: 12),
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Generated: $formattedDate', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5),
            ],
          ),
          pw.SizedBox(height: 12),
          // Content table/rows
          pw.Column(children: rows),
          pw.SizedBox(height: 16),
          if (postScript != null && postScript.trim().isNotEmpty) ...[
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Text('Corporate Notice', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(postScript, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static String _humanizeKey(String key) {
    // Convert snake_case or lowerCamelCase to Title Case labels
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
        .replaceAll('_', ' ');
    return spaced.isEmpty
        ? key
        : spaced[0].toUpperCase() + spaced.substring(1);
  }
}


