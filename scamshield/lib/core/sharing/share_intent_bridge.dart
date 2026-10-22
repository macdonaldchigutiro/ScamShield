import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Holds text explicitly shared to ScamShield from another application.
///
/// The payload is kept only long enough for the Check screen to consume it.
/// ScamShield does not automatically analyse or upload shared text.
final sharedTextProvider = StateProvider<String?>((ref) => null);

final shareIntentBridgeProvider = Provider<ShareIntentBridge>((ref) {
  final bridge = ShareIntentBridge(ref);
  ref.onDispose(bridge.dispose);
  return bridge;
});

class ShareIntentBridge {
  static const _channel = MethodChannel('scamshield/share');
  final Ref _ref;

  ShareIntentBridge(this._ref) {
    _channel.setMethodCallHandler(_handleNativeCall);
    _loadInitialShare();
  }

  Future<void> _loadInitialShare() async {
    try {
      final text = await _channel.invokeMethod<String>('getInitialSharedText');
      _accept(text);
    } on MissingPluginException {
      // Expected on platforms that do not implement Android sharing.
    } on PlatformException {
      // Sharing must never prevent ScamShield from starting.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'sharedText') {
      _accept(call.arguments as String?);
    }
  }

  void _accept(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;

    _ref.read(sharedTextProvider.notifier).state = text;
    // The Check area is tab index 1 in the persistent shell.
    _ref.read(selectedHomeTabProvider.notifier).state = 1;
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
