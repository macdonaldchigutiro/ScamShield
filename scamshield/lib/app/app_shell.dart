import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/incidents/presentation/screens/evidence_locker_screen.dart';
import '../features/protection/presentation/controllers/protection_controller.dart';
import '../features/scam_check/presentation/screens/investigation_hub_screen.dart';
import '../learn_screen.dart';
import '../partner_screen.dart';
import '../protect_screen.dart';
import '../sos_screen.dart';
import '../theme.dart';

/// Persistent application shell for ScamShield.
///
/// Mobile keeps familiar bottom navigation. Wider screens switch to a side rail
/// and capped content width so the interface does not stretch like a phone UI
/// across a desktop monitor.
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

    final pages = <Widget>[
      _HomeWithProtection(
        protection: protection,
        onImproveProtection: () => selectTab(2),
        child: HomeScreen(sim: sim),
      ),
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
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFF070C1C),
            indicatorColor: Palette.cyan.withOpacity(0.18),
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
      },
    );
  }
}

/// Home-only protection status built from user-confirmed safety actions.
class _HomeWithProtection extends StatelessWidget {
  final ProtectionState protection;
  final VoidCallback onImproveProtection;
  final Widget child;

  const _HomeWithProtection({
    required this.protection,
    required this.onImproveProtection,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = protection.percentage >= 80
        ? Palette.green
        : protection.percentage >= 50
            ? Palette.amber
            : Palette.red;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            borderColor: color.withOpacity(.36),
            child: protection.isLoading
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Palette.cyan,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading your protection status…',
                        style: TextStyle(color: Palette.dim),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(.12),
                          border: Border.all(color: color.withOpacity(.45)),
                        ),
                        child: Text(
                          '${protection.percentage}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR PROTECTION STATUS',
                              style: TextStyle(
                                color: Palette.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${protection.completedCount} of ${protection.totalCount} safety steps confirmed. This score comes only from actions you mark complete.',
                              style: const TextStyle(
                                color: Palette.dim,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: onImproveProtection,
                        icon: const Icon(Icons.verified_user_outlined, size: 17),
                        label: const Text('Improve'),
                        style: TextButton.styleFrom(foregroundColor: color),
                      ),
                    ],
                  ),
          ),
        ),
        Expanded(child: child),
      ],
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
      backgroundColor: const Color(0xFF070C1C),
      indicatorColor: Palette.cyan.withOpacity(.16),
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      minWidth: 92,
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
          icon: Icon(Icons.support_agent),
          label: Text('Help'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: Text('Learn'),
        ),
      ],
    );
  }
}

/// Shared brand header and high-priority utility actions.
class _AppHeader extends StatelessWidget {
  final bool desktop;
  final int protectionPercentage;
  final VoidCallback onProtectionPressed;
  final VoidCallback onEvidencePressed;
  final VoidCallback onPartnerPressed;
  final VoidCallback onEmergencyPressed;
  final VoidCallback onHelpPressed;

  const _AppHeader({
    required this.desktop,
    required this.protectionPercentage,
    required this.onProtectionPressed,
    required this.onEvidencePressed,
    required this.onPartnerPressed,
    required this.onEmergencyPressed,
    required this.onHelpPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 8),
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
                    fontSize: 10.5,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          if (desktop) ...[
            _HeaderAction(
              icon: Icons.verified_user_outlined,
              label: 'Protection $protectionPercentage%',
              color: protectionPercentage >= 80
                  ? Palette.green
                  : protectionPercentage >= 50
                      ? Palette.amber
                      : Palette.red,
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
              icon: Icons.emergency_rounded,
              label: 'EMERGENCY',
              color: Palette.red,
              filled: true,
              onPressed: onEmergencyPressed,
            ),
            _HeaderAction(
              icon: Icons.help_outline,
              label: 'Help',
              color: Palette.dim,
              onPressed: onHelpPressed,
            ),
          ] else ...[
            IconButton(
              tooltip: 'Evidence Locker',
              onPressed: onEvidencePressed,
              icon: const Icon(Icons.inventory_2_outlined, color: Palette.cyan),
            ),
            IconButton(
              tooltip: 'Emergency help',
              onPressed: onEmergencyPressed,
              icon: const Icon(Icons.emergency_rounded, color: Palette.red),
            ),
            IconButton(
              tooltip: 'Help',
              onPressed: onHelpPressed,
              icon: const Icon(Icons.help_outline, color: Palette.dim),
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
        icon: Icon(icon, color: filled ? Colors.white : color, size: 18),
        label: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : color,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: filled ? color : color.withOpacity(.06),
          side: BorderSide(color: color.withOpacity(filled ? .9 : .28)),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
