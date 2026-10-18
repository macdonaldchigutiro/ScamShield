import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../features/scam_check/presentation/screens/scam_investigator_screen.dart';
import '../learn_screen.dart';
import '../protect_screen.dart';
import '../radar_screen.dart';
import '../sos_screen.dart';
import '../theme.dart';

/// The persistent application shell shown after ScamShield starts.
///
/// It owns only top-level presentation concerns: the brand header, primary
/// navigation and the five major product areas. Feature logic remains inside
/// each feature screen instead of accumulating here.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sim = ref.watch(threatSimProvider);
    final selectedTab = ref.watch(selectedHomeTabProvider);

    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AppHeader(onHelpPressed: () => _showAboutSheet(context)),
              Expanded(
                child: AnimatedBuilder(
                  // ThreatSim is currently a ChangeNotifier. AnimatedBuilder
                  // keeps the existing live prototype behaviour while its
                  // future replacement can be introduced behind the provider.
                  animation: sim,
                  builder: (context, _) => IndexedStack(
                    index: selectedTab,
                    children: [
                      RadarScreen(sim: sim),
                      const ScamInvestigatorScreen(),
                      const ProtectScreen(),
                      const SosScreen(),
                      const LearnScreen(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF070C1C),
        indicatorColor: Palette.cyan.withOpacity(0.18),
        selectedIndex: selectedTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          ref.read(selectedHomeTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Check',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Protect',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent),
            label: 'Help',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}

/// Brand header shared by the main product areas.
class _AppHeader extends StatelessWidget {
  final VoidCallback onHelpPressed;

  const _AppHeader({required this.onHelpPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: shieldGradient.createShader,
                  child: const Text(
                    'SCAMSHIELD',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'DIGITAL FRAUD DEFENCE',
                  style: TextStyle(
                    color: Palette.dim,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Partner intelligence',
            // go_router keeps route changes declarative and deep-link ready.
            onPressed: () => context.push('/partner'),
            icon: const Icon(
              Icons.business_center_outlined,
              color: Palette.violet,
            ),
          ),
          IconButton(
            tooltip: 'How ScamShield works',
            onPressed: onHelpPressed,
            icon: const Icon(Icons.help_outline, color: Palette.dim),
          ),
        ],
      ),
    );
  }
}

/// Explains the product in plain language without taking users away from their
/// current task.
void _showAboutSheet(BuildContext context) {
  Widget point(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Palette.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  body,
                  style: const TextStyle(
                    color: Palette.dim,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1226),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Palette.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW SCAMSHIELD WORKS',
            style: TextStyle(
              color: Palette.cyan,
              letterSpacing: 3,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          point(
            Icons.shield_outlined,
            'Four layers of defence',
            'Check suspicious activity, strengthen your accounts, recover quickly and learn common scam tactics.',
          ),
          point(
            Icons.hub_outlined,
            'All major channels',
            'SMS, WhatsApp, social media, email, phone calls, links, QR codes and SIM-swap warning signs.',
          ),
          point(
            Icons.lock_outline,
            'Privacy by design',
            'Where possible, checks happen on your device. Cloud services will be clearly disclosed when introduced.',
          ),
          point(
            Icons.info_outline,
            'Decision support, not blind trust',
            'ScamShield explains why something looks risky and tells you the safest next action.',
          ),
        ],
      ),
    ),
  );
}
