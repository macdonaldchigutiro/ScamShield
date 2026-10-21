// ignore_for_file: deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

/// Uses the browser's native download flow for generated report bytes.
Future<void> downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final blob = html.Blob(<Object>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
