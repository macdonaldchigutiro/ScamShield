import 'dart:typed_data';

/// Non-web fallback for builds where a native saver has not been wired yet.
///
/// Chrome/web is the current supported export target. Mobile/desktop can later
/// provide their own implementation behind the same adapter without changing
/// report generation.
Future<void> downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError(
    'PDF download is currently available in the web build.',
  );
}
