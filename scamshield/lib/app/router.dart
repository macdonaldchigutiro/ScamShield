import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../features/incidents/presentation/screens/evidence_locker_entry_screen.dart';
import '../partner_screen.dart';
import 'app_shell.dart';

/// Central navigation table for ScamShield.
///
/// Keeping routes in one place makes navigation easier to test and prepares the
/// app for deep links such as opening a shared scam report directly from email,
/// SMS or another application.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/evidence',
        name: 'evidence',
        builder: (context, state) => const EvidenceLockerEntryScreen(),
      ),
      GoRoute(
        path: '/partner',
        name: 'partner',
        builder: (context, state) {
          final sim = ref.read(threatSimProvider);
          return PartnerScreen(sim: sim);
        },
      ),
    ],
  );
});
