# ScamShield — iPhone preparation and acceptance checklist

**Development branch:** `upgrade/home-dashboard-v1`. Do not merge `main` without approval.

## What is ready now

The Flutter UI, local rules-based investigation, protection checklist, Evidence Locker and PDF reporting are designed to be cross-platform. The shared-message review UI is Flutter code and can be reused for a future iOS Share Extension. The Android share target is native Android code and **does not** register ScamShield in the iOS Share sheet.

**Not yet verified on iOS:** compilation, dependencies (particularly OCR/Tesseract), file export, notifications/permissions, layout, device performance or a working Share Extension. Do not describe these as tested.

## When a Mac is available

1. Install Flutter and the Xcode version compatible with that Mac/macOS. Run `flutter doctor -v` and resolve iOS issues. Follow https://docs.flutter.dev/platform-integration/ios/setup.
2. Check out this branch and enter the Flutter app:
   ```bash
   git clone -b upgrade/home-dashboard-v1 https://github.com/macdonaldchigutiro/ScamShield.git
   cd ScamShield/scamshield
   bash tool/prepare_ios.sh
   ```
3. Open `ios/Runner.xcworkspace` in Xcode. Choose **Runner > Signing & Capabilities**, select your development Team, and use a unique app Bundle Identifier (do not assume the Android example package is an acceptable production ID).
4. Connect and trust your iPhone, enable **Developer Mode**, and run `flutter devices` then `flutter run -d <device-id>`.
5. Run `flutter analyze` and `flutter test`. Fix build errors before attempting any App Store distribution.

## Manual iPhone acceptance checks

- [ ] Launch on device, navigate Home / Check / Protect / Evidence / Help
- [ ] Check a suspicious message, a URL, and a phone number
- [ ] Verify that each risk score is backed by the local rules, not invented reputation data
- [ ] Check screenshot/QR and local OCR only where supported by the iOS plugin
- [ ] Restart and confirm Protection progress and saved evidence persist
- [ ] Export a PDF and a JSON backup and verify the iOS share/file workflow
- [ ] Verify emergency/recovery flow and delete confirmation
- [ ] Verify narrow-screen layout, keyboard dismissal, VoiceOver and text scaling
- [ ] Verify cloud analysis remains off without explicit consent and a real configured endpoint
- [ ] Confirm real-device release build and signing before distribution

## iOS Share-to-ScamShield — separate future native integration

After generating the iOS runner on the Mac, create an **iOS Share Extension** target in Xcode. Configure the extension activation rules for plain text / URLs and enable the **same App Group** for the main app and the extension. Store only user-initiated incoming text in that shared container and securely pass it to the Flutter `sharedTextProvider` / shared review screen when the app becomes active. Ensure the received data is not uploaded or analysed until the user explicitly chooses Investigate. Review Apple's extension launch/host-app restrictions before designing the handoff; do **not** assume the extension may force-launch the containing app.

Do not add hard-coded Team IDs, signing certificates, App Group names or Bundle IDs here. Those must be selected in the real Xcode project under the user's Apple development team.

## Android without a physical Android phone

On Windows, Android Studio's emulator can validate Android installation, share intents and screen behaviour. It cannot replace final testing on a physical phone (especially third-party app sharing). Follow https://docs.flutter.dev/platform-integration/android/setup.
