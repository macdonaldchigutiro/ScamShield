import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branding/scamshield_brand_logo.dart';
import '../core/providers/app_providers.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/incidents/presentation/screens/evidence_locker_screen.dart';
import '../features/intelligence/presentation/screens/threat_intelligence_screen.dart';
import '../features/privacy/presentation/screens/privacy_screen.dart';
import '../features/protection/presentation/controllers/protection_controller.dart';
import '../features/scam_check/presentation/screens/investigation_hub_screen.dart';
import '../learn_screen.dart';
import '../partner_screen.dart';
import '../protect_screen.dart';
import '../sos_screen.dart';
import '../theme.dart';

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

    void openIntelligence() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ThreatIntelligenceScreen()),
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
                  protectionCompleted: protection.completedCount,
                  protectionTotal: protection.totalCount,
                  onProtectionPressed: () => selectTab(2),
                  onEvidencePressed: openEvidence,
                  onPartnerPressed: openPartner,
                  onPrivacyPressed: openPrivacy,
                  onIntelligencePressed: openIntelligence,
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

enum _MoreAction { intelligence, partner, privacy, help }

class _AppHeader extends StatelessWidget {
  final bool desktop;
  final int protectionCompleted;
  final int protectionTotal;
  final VoidCallback onProtectionPressed;
  final VoidCallback onEvidencePressed;
  final VoidCallback onPartnerPressed;
  final VoidCallback onPrivacyPressed;
  final VoidCallback onIntelligencePressed;
  final VoidCallback onEmergencyPressed;
  final VoidCallback onHelpPressed;

  const _AppHeader({
    required this.desktop,
    required this.protectionCompleted,
    required this.protectionTotal,
    required this.onProtectionPressed,
    required this.onEvidencePressed,
    required this.onPartnerPressed,
    required this.onPrivacyPressed,
    required this.onIntelligencePressed,
    required this.onEmergencyPressed,
    required this.onHelpPressed,
  });

  void _handleMore(_MoreAction action) {
    switch (action) {
      case _MoreAction.intelligence:
        onIntelligencePressed();
      case _MoreAction.partner:
        onPartnerPressed();
      case _MoreAction.privacy:
        onPrivacyPressed();
      case _MoreAction.help:
        onHelpPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(desktop ? 24 : 16, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Palette.bgTop,
        border: Border(bottom: BorderSide(color: Palette.line)),
      ),
      child: Row(
        children: [
          ScamShieldBrandLogo(size: desktop ? 58 : 50),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  style: TextStyle(color: Palette.dim, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (desktop) ...[
            _HeaderAction(
              icon: Icons.verified_user_outlined,
              label: 'Protection $protectionCompleted/$protectionTotal',
              onPressed: onProtectionPressed,
            ),
            _HeaderAction(
              icon: Icons.inventory_2_outlined,
              label: 'Evidence',
              onPressed: onEvidencePressed,
            ),
            _EmergencyAction(onPressed: onEmergencyPressed),
            const SizedBox(width: 6),
            PopupMenuButton<_MoreAction>(
              tooltip: 'More',
              onSelected: _handleMore,
              color: Palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Palette.line),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MoreAction.intelligence,
                  child: _MoreItem(
                    icon: Icons.radar_rounded,
                    label: 'Threat intelligence',
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.partner,
                  child: _MoreItem(
                    icon: Icons.business_center_outlined,
                    label: 'Partner view',
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.privacy,
                  child: _MoreItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy & analysis',
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.help,
                  child: _MoreItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help',
                  ),
                ),
              ],
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: Palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Palette.line),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.more_horiz_rounded, color: Palette.dim, size: 20),
                    SizedBox(width: 7),
                    Text(
                      'More',
                      style: TextStyle(
                        color: Palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Evidence Locker',
              onPressed: onEvidencePressed,
              color: Palette.cyan,
              icon: const Icon(Icons.inventory_2_outlined),
            ),
            PopupMenuButton<_MoreAction>(
              tooltip: 'More',
              onSelected: _handleMore,
              color: Palette.surface,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MoreAction.intelligence,
                  child: _MoreItem(
                    icon: Icons.radar_rounded,
                    label: 'Threat intelligence',
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.partner,
                  child: _MoreItem(
                    icon: Icons.business_center_outlined,
                    label: 'Partner view',
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.privacy,
                  child: _MoreItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy & analysis',
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.help,
                  child: _MoreItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help',
                  ),
                ),
              ],
              icon: const Icon(Icons.more_horiz_rounded, color: Palette.dim),
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
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const SizedBox.shrink(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Palette.cyan),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
        style: TextButton.styleFrom(
          foregroundColor: Palette.text,
          backgroundColor: Palette.surface,
          side: const BorderSide(color: Palette.line),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _EmergencyAction extends StatelessWidget {
  final VoidCallback onPressed;
  const _EmergencyAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.emergency_rounded, size: 18),
        label: const Text("I've been scammed"),
        style: FilledButton.styleFrom(
          backgroundColor: Palette.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MoreItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Palette.cyan),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Palette.text)),
      ],
    );
  }
}
