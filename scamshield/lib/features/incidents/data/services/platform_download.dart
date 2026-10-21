import 'dart:typed_data';

import 'platform_download_stub.dart'
    if (dart.library.html) 'platform_download_web.dart' as platform;

/// Saves report bytes using the best mechanism available on the current build.
///
/// Keeping this behind a tiny adapter prevents browser-only APIs from leaking
/// into the PDF generation service and leaves room for mobile/desktop support.
Future<void> downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  return platform.downloadBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
