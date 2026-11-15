# OCR migration review — do not migrate blindly

## Current status
- Existing package: `flutter_tesseract_ocr ^0.4.31` (discontinued), used by `MediaScanService`.
- The current scanner reads picked image bytes for local QR detection, then calls
  `FlutterTesseractOcr.extractText(picked.path, language: 'eng', args: ...)`.
- On unsupported platforms or extraction errors it displays an honest notice
  and lets the user type/correct text. QR decoding remains independent.
- No OCR data is intentionally sent to a ScamShield backend.

## Candidate
`tesseract_ocr` is the maintained successor (see https://pub.dev/packages/tesseract_ocr).
Its OCR API is `TesseractOcr.extractText(path, config: OCRConfig(...))`.
The package documentation describes iOS Vision, Tesseract on Android and Web
(Tesseract.js), and platform-specific asset/setup requirements.

**Important:** This is a candidate assessment, not a compatibility certification.
New releases, platform implementation, language assets, and minimum SDK/toolchain
requirements must be checked against ScamShield's actual Flutter SDK on a Mac.

## Safe migration sequence
1. Keep this branch working. Create a separate OCR migration branch or PR.
2. Add the maintained dependency and replace only the OCR adapter calls.
3. Add the required language assets and `pubspec.yaml` asset entries per the
   exact chosen plugin version; verify license and app-size impact.
4. Validate image-picker paths on Windows Chrome, Android emulator, and iOS
   simulator/device. Check the plugin's Web worker/CDN/privacy setup. For
   privacy-first shipping, prefer self-hosted assets over a third-party CDN.
5. Test clear, rotated, low-light and multilingual screenshots with known
   expected text; assess false substitutions of URLs, phone numbers and amounts.
6. Test QR-only images and OCR-unavailable/error fallback.
7. Run `flutter analyze`, `flutter test`, web build, Android build, and
   iOS simulator/device builds. Only remove the old package once these pass.

## Release gate
Do not claim screenshot OCR works on iPhone, or that analysis stays fully
offline in Web, until verified on that actual platform and build.
