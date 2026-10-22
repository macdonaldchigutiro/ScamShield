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
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.manage_search_outlined), selectedIcon: Icon(Icons.manage_search_rounded), label: 'Check'),
              NavigationDestination(icon: Icon(Icons.verified_user_outlined), selectedIcon: Icon(Icons.verified_user_rounded), label: 'Protect'),
              NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Help'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Learn'),
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

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.manage_search_outlined, Icons.manage_search_rounded, 'Check'),
    (Icons.verified_user_outlined, Icons.verified_user_rounded, 'Protect'),
    (Icons.support_agent_outlined, Icons.support_agent, 'Help'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      color: Palette.bgTop,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
        children: [
          for (var index = 0; index < _items.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavItem(
                icon: selectedIndex == index ? _items[index].$2 : _items[index].$1,
                label: _items[index].$3,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 72,
          decoration: BoxDecoration(
            color: selected ? Palette.cyan.withOpacity(.09) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: selected ? Palette.cyan : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 25,
                color: selected ? Palette.cyan : Palette.textSecondary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Palette.text : Palette.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
      minHeight: desktop ? 88 : 76,
      padding: EdgeInsets.fromLTRB(desktop ? 26 : 16, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Palette.bgTop,
        border: Border(bottom: BorderSide(color: Palette.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScamShieldBrandLogo(size: desktop ? 62 : 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ScamShield',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: desktop ? 23 : 20,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Digital fraud defence',
                  style: TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 12.5,
                    height: 1.0,
                  ),
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
            _MoreMenu(onSelected: _handleMore),
          ] else ...[
            IconButton(
              tooltip: 'Evidence Locker',
              onPressed: onEvidencePressed,
              color: Palette.cyan,
              icon: const Icon(Icons.inventory_2_outlined),
            ),
            _MoreMenu(onSelected: _handleMore, compact: true),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: onEmergencyPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Palette.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(46, 46),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Icon(Icons.emergency_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final ValueChanged<_MoreAction> onSelected;
  final bool compact;

  const _MoreMenu({required this.onSelected, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MoreAction>(
      tooltip: 'More',
      onSelected: onSelected,
      color: Palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Palette.line),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: _MoreAction.intelligence, child: _MoreItem(icon: Icons.radar_rounded, label: 'Threat intelligence')),
        PopupMenuItem(value: _MoreAction.partner, child: _MoreItem(icon: Icons.business_center_outlined, label: 'Partner view')),
        PopupMenuItem(value: _MoreAction.privacy, child: _MoreItem(icon: Icons.privacy_tip_outlined, label: 'Privacy & analysis')),
        PopupMenuItem(value: _MoreAction.help, child: _MoreItem(icon: Icons.help_outline_rounded, label: 'Help')),
      ],
      child: compact
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.more_horiz_rounded, color: Palette.textSecondary),
            )
          : Container(
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
                  Icon(Icons.more_horiz_rounded, color: Palette.textSecondary, size: 20),
                  SizedBox(width: 7),
                  Text('More', style: TextStyle(color: Palette.text, fontWeight: FontWeight.w700)),
                ],
              ),
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
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Palette.text,
          backgroundColor: Palette.surface,
          side: const BorderSide(color: Palette.line),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Palette.cyan),
            const SizedBox(width: 7),
            Text(label),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
