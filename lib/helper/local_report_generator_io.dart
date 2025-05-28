// save_pdf.dart
import 'dart:io' show File;
import 'package:path_provider/path_provider.dart';

Future<File?> savePdfImp(List<int> bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
}