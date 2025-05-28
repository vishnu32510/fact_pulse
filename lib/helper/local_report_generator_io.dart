import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fact_pulse/models/perplexity_response_model.dart';

Future<File> generateAndSaveReportLocally({
  required String itemId,
  required List<Claims> claims,
}) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('Fact-Check Report', style: pw.TextStyle(fontSize: 24))),
        pw.Paragraph(text: 'Report ID: $itemId'),
        pw.SizedBox(height: 16),
        ...claims.map((c) {
          final list = <pw.Widget>[];
          list.add(pw.Text('Claim:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          list.add(pw.Text(c.claim ?? ''));
          list.add(pw.SizedBox(height: 4));
          list.add(
            pw.Text('Rating: ${c.rating}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
          );
          list.add(pw.SizedBox(height: 4));
          list.add(pw.Text('Explanation: ${c.explanation}'));
          if ((c.sources ?? []).isNotEmpty) {
            list.add(pw.SizedBox(height: 4));
            list.add(
              pw.Text(
                'Sources: ${c.sources!.join(', ')}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.blue),
              ),
            );
          }
          list.add(pw.Divider());
          return pw.Column(children: list);
        }),
      ],
    ),);
  final bytes = await pdf.save();
  final docDir = await getApplicationDocumentsDirectory();
  final file = File('${docDir.path}/report_$itemId.pdf');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
