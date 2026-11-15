#!/usr/bin/env bash
# Run on a Mac with Flutter and Xcode installed, from any directory.
# This prepares the native iOS runner. It does not sign, publish, or install it.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS builds require macOS and Xcode. Run this script on your Mac."
  exit 1
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not on PATH. See https://docs.flutter.dev/install"
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Xcode command-line tools are required. Install and select Xcode first."
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$APP_DIR"

echo "Checking Apple build tools..."
xcodebuild -version
flutter --version

if [[ ! -f ios/Runner.xcworkspace/contents.xcworkspacedata ]]; then
  echo "Generating missing Flutter iOS platform files..."
  flutter create --platforms=ios .
else
  echo "Existing iOS runner found; leaving its native settings intact."
fi

flutter pub get

echo
echo "iOS runner prepared. Next, on the Mac:"
echo "  1. Run: flutter doctor -v"
echo "  2. Run: flutter devices"
echo "  3. Open ios/Runner.xcworkspace in Xcode and set your Team and unique Bundle ID."
echo "  4. Connect and trust your iPhone, enable Developer Mode, then run:"
echo "       flutter run -d <iphone_device_id>"
echo
echo "Important: Android ACTION_SEND does NOT enable iOS share-sheet receiving."
echo "An iOS Share Extension and App Group must be configured in Xcode separately."
