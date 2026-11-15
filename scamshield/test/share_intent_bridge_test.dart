import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield/core/providers/app_providers.dart';
import 'package:scamshield/core/sharing/share_intent_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('scamshield/share');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('shared text opens Check for manual review without modification', () async {
    const message = 'Please check this suspicious message before I reply.';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getInitialSharedText') return message;
      return null;
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(selectedHomeTabProvider), 0);
    container.read(shareIntentBridgeProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sharedTextProvider), message);
    expect(container.read(selectedHomeTabProvider), 1);
  });

  test('empty initial share leaves app unchanged', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getInitialSharedText') return '  ';
      return null;
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(shareIntentBridgeProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sharedTextProvider), isNull);
    expect(container.read(selectedHomeTabProvider), 0);
  });
}
