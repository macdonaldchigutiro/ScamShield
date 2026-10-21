import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/incidents/presentation/screens/evidence_locker_screen.dart';
import '../features/privacy/presentation/screens/privacy_screen.dart';
import '../features/protection/presentation/controllers/protection_controller.dart';
import '../features/scam_check/presentation/screens/investigation_hub_screen.dart';
import '../learn_screen.dart';
import '../partner_screen.dart';
import '../protect_screen.dart';
import '../sos_screen.dart';
import '../theme.dart';

/// Persistent application shell.
///
/// Desktop uses a labelled navigation rail and capped content width. Mobile
/// keeps a familiar bottom bar. The shell owns navigation only; Home owns its
/// own content hierarchy, including protection status and recent activity.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sim = ref.watch(threatSimProvider);
    final selectedTab = ref.watch(selectedHomeTabProvider);
    final protection = ref.watch(protectionControllerProvider);

    void selectTab(int index) {
      ref.read(selectedHomeTabProvider.notifier).state = index;
    }

    void openEvidence() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EvidenceLockerScreen()),
      );
    }

    void openPartner() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PartnerScreen(sim: sim)),
      );
    }

    void openPrivacy() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrivacyScreen()),
      );
    }

    final pages = <Widget>[
      const HomeScreen(),
      const InvestigationHubScreen(),
      const ProtectScreen(),
      const SosScreen(),
      const LearnScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1000;

        final content = CyberBackground(
          child: SafeArea(
            child: Column(
              children: [
                _AppHeader(
                  desktop: desktop,
                  protectionPercentage: protection.percentage,
                  onProtectionPressed: () => selectTab(2),
                  onEvidencePressed: openEvidence,
                  onPartnerPressed: openPartner,
                  onPrivacyPressed: openPrivacy,
                  onEmergencyPressed: () => selectTab(3),
                  onHelpPressed: () => selectTab(3),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: IndexedStack(
                        index: selectedTab,
                        children: pages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                _DesktopNavigation(
                  selectedIndex: selectedTab,
                  onSelected: selectTab,
                ),
                const VerticalDivider(width: 1, color: Palette.line),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedTab,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: selectTab,
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
                selectedIcon: Icon(Icons.verified_user_rounded),
                label: 'Protect',
              ),
              NavigationDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent),
                label: 'Help',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Learn',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DesktopNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      minWidth: 96,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.manage_search_outlined),
          selectedIcon: Icon(Icons.manage_search_rounded),
          label: Text('Check'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.verified_user_outlined),
          selectedIcon: Icon(Icons.verified_user_rounded),
          label: Text('Protect'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: Text('Help'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Learn'),
        ),
      ],
    );
  }
}

/// Brand header with plainly labelled high-priority actions.
class _AppHeader extends StatelessWidget {
  final bool desktop;
  final int protectionPercentage;
  final VoidCallback onProtectionPressed;
  final VoidCallback onEvidencePressed;
  final VoidCallback onPartnerPressed;
  final VoidCallback onPrivacyPressed;
  final VoidCallback onEmergencyPressed;
  final VoidCallback onHelpPressed;

  const _AppHeader({
    required this.desktop,
    required this.protectionPercentage,
    required this.onProtectionPressed,
    required this.onEvidencePressed,
    required this.onPartnerPressed,
    required this.onPrivacyPressed,
    required this.onEmergencyPressed,
    required this.onHelpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final protectionColor = protectionPercentage >= 80
        ? Palette.green
        : protectionPercentage >= 40
            ? Palette.amber
            : Palette.cyan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Palette.cyan, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ScamShield',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Digital fraud defence',
                  style: TextStyle(color: Palette.dim, fontSize: 12),
                ),
              ],
            ),
          ),
          if (desktop) ...[
            _HeaderAction(
              icon: Icons.verified_user_outlined,
              label: 'Protection $protectionPercentage%',
              color: protectionColor,
              onPressed: onProtectionPressed,
            ),
            _HeaderAction(
              icon: Icons.inventory_2_outlined,
              label: 'Evidence',
              color: Palette.cyan,
              onPressed: onEvidencePressed,
            ),
            _HeaderAction(
              icon: Icons.business_center_outlined,
              label: 'Partners',
              color: Palette.violet,
              onPressed: onPartnerPressed,
            ),
            _HeaderAction(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy',
              color: Palette.green,
              onPressed: onPrivacyPressed,
            ),
            _HeaderAction(
              icon: Icons.emergency_rounded,
              label: "I've been scammed",
              color: Palette.red,
              filled: true,
              onPressed: onEmergencyPressed,
            ),
            IconButton(
              tooltip: 'Help',
              onPressed: onHelpPressed,
              color: Palette.dim,
              icon: const Icon(Icons.help_outline),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Privacy & analysis',
              onPressed: onPrivacyPressed,
              color: Palette.green,
              icon: const Icon(Icons.privacy_tip_outlined),
            ),
            IconButton(
              tooltip: 'Evidence Locker',
              onPressed: onEvidencePressed,
              color: Palette.cyan,
              icon: const Icon(Icons.inventory_2_outlined),
            ),
            FilledButton(
              onPressed: onEmergencyPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Palette.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Icon(Icons.emergency_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: filled ? Colors.white : color,
          backgroundColor: filled ? color : Colors.transparent,
          side: BorderSide(color: filled ? color : Palette.line),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
