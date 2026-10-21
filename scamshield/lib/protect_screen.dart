import 'package:flutter/material.dart';

import 'features/protection/presentation/screens/protection_screen.dart';

/// Backward-compatible entry point used by existing navigation.
///
/// Keeping this wrapper avoids scattering migration changes through the app
/// while the real implementation lives in the feature-first protection module.
class ProtectScreen extends StatelessWidget {
  const ProtectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProtectionScreen();
  }
}
