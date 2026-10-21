import 'dart:typed_data';

/// The platform-neutral result of scanning an uploaded screenshot or QR image.
///
/// Raw image bytes are kept in memory only for previewing during the current
/// session. Nothing in this model implies persistence or cloud upload.
class MediaScanResult {
  final Uint8List imageBytes;
  final String fileName;
  final String extractedText;
  final String? qrContent;
  final bool ocrAvailable;
  final String? ocrNotice;

  const MediaScanResult({
    required this.imageBytes,
    required this.fileName,
    required this.extractedText,
    required this.qrContent,
    required this.ocrAvailable,
    this.ocrNotice,
  });

  bool get hasText => extractedText.trim().isNotEmpty;
  bool get hasQr => qrContent?.trim().isNotEmpty == true;
}
