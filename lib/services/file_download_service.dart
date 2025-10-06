import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class FileDownloadService {
  // Saves bytes as a file. On web, triggers a browser download. On other platforms, no-op by default.
  static Future<void> saveBytesAsFile({
    required Uint8List bytes,
    required String filename,
    String mimeType = 'application/pdf',
  }) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = filename;
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return;
    }
    return;
  }
}

 