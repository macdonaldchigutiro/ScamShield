import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../features/incidents/presentation/screens/evidence_locker_screen.dart';
import '../features/scam_check/presentation/screens/investigation_hub_screen.dart';
import '../learn_screen.dart';
import '../partner_screen.dart';
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
              _AppHeader(
                onEvidencePressed: () {
                  // Use the local Navigator for these utility pages so the user
                  // always gets a predictable in-app Back path on web/mobile.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EvidenceLockerScreen(),
                    ),
                  );
                },
                onPartnerPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PartnerScreen(sim: sim),
                    ),
                  );
                },
                onHelpPressed: () {
                  // Help is a primary tab, so switch tabs instead of stacking a
                  // second page. This preserves the user's place in the shell.
                  ref.read(selectedHomeTabProvider.notifier).state = 3;
                },
              ),
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
                      const InvestigationHubScreen(),
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
  final VoidCallback onEvidencePressed;
  final VoidCallback onPartnerPressed;
  final VoidCallback onHelpPressed;

  const _AppHeader({
    required this.onEvidencePressed,
    required this.onPartnerPressed,
    required this.onHelpPressed,
  });

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
            tooltip: 'Evidence Locker',
            onPressed: onEvidencePressed,
            icon: const Icon(
              Icons.inventory_2_outlined,
              color: Palette.cyan,
            ),
          ),
          IconButton(
            tooltip: 'Partner View',
            onPressed: onPartnerPressed,
            icon: const Icon(
              Icons.business_center_outlined,
              color: Palette.violet,
            ),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: onHelpPressed,
            icon: const Icon(Icons.help_outline, color: Palette.dim),
          ),
        ],
      ),
    );
  }
}
