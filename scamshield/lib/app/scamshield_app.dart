import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// Top-level application widget.
///
/// This class intentionally contains very little logic. App-wide state lives in
/// providers, navigation lives in [appRouterProvider], and styling lives in
/// [AppTheme]. That separation keeps the entry point easy to understand.
class ScamShieldApp extends ConsumerWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
