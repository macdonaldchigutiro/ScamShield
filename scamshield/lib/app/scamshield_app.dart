import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sharing/share_intent_bridge.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

/// Top-level application widget.
///
/// App-wide state lives in providers, navigation lives in [appRouterProvider],
/// and styling lives in [AppTheme]. The share bridge is initialized here so
/// Android can deliver text whether the app starts from a share or is already
/// running.
class ScamShieldApp extends ConsumerWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the native share bridge alive for the lifetime of the application.
    ref.watch(shareIntentBridgeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
