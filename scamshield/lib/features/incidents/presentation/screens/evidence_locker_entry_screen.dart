import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../theme.dart';
import '../controllers/incident_controller.dart';
import 'evidence_locker_screen.dart';

/// Route-level entry point for the Evidence Locker.
///
/// Keeps the full locker unchanged when evidence exists, while giving a user
/// with an empty locker an obvious next step instead of a dead-end screen.
class EvidenceLockerEntryScreen extends ConsumerWidget {
  const EvidenceLockerEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentControllerProvider);

    if (state.isLoading || state.incidents.isNotEmpty) {
      return const EvidenceLockerScreen();
    }

    void openCheck() {
      ref.read(selectedHomeTabProvider.notifier).state = 1;
      context.go('/');
    }

    void openHome() {
      ref.read(selectedHomeTabProvider.notifier).state = 0;
      context.go('/');
    }

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bgTop,
        foregroundColor: Palette.text,
        title: const Text(
          'Evidence Locker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: Palette.cyan.withOpacity(.30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Palette.cyan.withOpacity(.09),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Palette.cyan.withOpacity(.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Palette.cyan,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Evidence Locker is empty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Palette.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Suspicious and high-risk checks you save will appear here automatically with their source, status and evidence preview.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Palette.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: openCheck,
                          icon: const Icon(Icons.manage_search_rounded),
                          label: const Text('Check a message'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Palette.cyan,
                            foregroundColor: Palette.bg,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: openHome,
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Home'),
                        style: TextButton.styleFrom(
                          foregroundColor: Palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
