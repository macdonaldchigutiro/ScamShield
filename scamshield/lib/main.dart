import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/scamshield_app.dart';
import 'theme.dart';

/// ScamShield application entry point.
///
/// The bootstrap file should stay deliberately small. Application features,
/// navigation and state belong in their own modules so startup remains easy to
/// understand and safe to change.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Match the operating-system chrome to ScamShield's dark visual identity.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Palette.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ProviderScope is Riverpod's dependency container. Every provider used by
  // the app is created, cached and disposed through this single root scope.
  runApp(
    const ProviderScope(
      child: ScamShieldApp(),
    ),
  );
}
