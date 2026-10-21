import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:zxing2/qrcode.dart';

import '../../domain/entities/media_scan_result.dart';

/// Reads screenshots and QR images without sending them to a ScamShield server.
///
/// The service deliberately owns image/OCR/QR dependencies so the presentation
/// layer remains simple. A future OCR provider can replace this class without
/// changing the investigation screens or domain rules.
class MediaScanService {
  final ImagePicker _picker;

  MediaScanService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<MediaScanResult?> pickAndScanImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final qrContent = _tryDecodeQr(bytes);

    String extractedText = '';
    bool ocrAvailable = true;
    String? ocrNotice;

    try {
      // Tesseract runs locally on supported platforms. The user can edit the
      // extracted text before investigation because OCR is never perfect.
      extractedText = await FlutterTesseractOcr.extractText(
        picked.path,
        language: 'eng',
        args: const {
          'preserve_interword_spaces': '1',
        },
      );
    } catch (_) {
      // OCR setup differs slightly by platform, particularly Flutter Web. A QR
      // can still be decoded and the user may paste/correct screenshot text.
      ocrAvailable = false;
      ocrNotice =
          'Automatic text extraction is not available in this build yet. '
          'You can still type or paste the visible text below.';
    }

    return MediaScanResult(
      imageBytes: bytes,
      fileName: picked.name,
      extractedText: extractedText.trim(),
      qrContent: qrContent,
      ocrAvailable: ocrAvailable,
      ocrNotice: ocrNotice,
    );
  }

  String? _tryDecodeQr(List<int> bytes) {
    try {
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      final rgbaBytes = decodedImage
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.abgr)
          .buffer
          .asInt32List();

      final source = RGBLuminanceSource(
        decodedImage.width,
        decodedImage.height,
        rgbaBytes,
      );
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      return QRCodeReader().decode(bitmap).text.trim();
    } catch (_) {
      // No QR code is a normal outcome for an ordinary screenshot.
      return null;
    }
  }
}
