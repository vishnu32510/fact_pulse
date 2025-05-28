import 'dart:html' as html; // only used when kIsWeb is true

Future<void> savePdfImp(List<int> bytes, String fileName) async {

    // Create a Blob and download it
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
