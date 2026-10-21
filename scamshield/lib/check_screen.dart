import 'package:flutter/material.dart';

import 'features/scam_check/presentation/screens/investigation_hub_screen.dart';

/// Compatibility entry point for older parts of the prototype.
///
/// Some Home quick actions still navigate to [CheckScreen]. Instead of keeping
/// two different scam-check experiences alive, this wrapper now forwards every
/// legacy entry point into the modern Investigation Hub.
///
/// Keeping this tiny adapter prevents stale navigation code from reopening the
/// retired message-only checker while we continue migrating the rest of the app.
class CheckScreen extends StatelessWidget {
  const CheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: InvestigationHubScreen(),
      ),
    );
  }
}
