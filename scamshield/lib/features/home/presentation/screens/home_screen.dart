import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../check_screen.dart';
import '../../../../protect_screen.dart';
import '../../../../radar_view.dart';
import '../../../../sim.dart';
import '../../../../sos_screen.dart';
import '../../../../theme.dart';
import '../../../incidents/domain/entities/incident_record.dart';
import '../../../incidents/presentation/controllers/incident_controller.dart';

/// ScamShield's action-first Home dashboard.
///
/// The radar remains clearly labelled as simulated prototype intelligence,
/// while the Recent Investigations section is driven by the user's real local
/// Evidence Locker records. This keeps demo data and user data visibly separate.
class HomeScreen extends ConsumerWidget {
  final ThreatSim sim;

  const HomeScreen({super.key, required this.sim});

  void _open(BuildContext context, Widget page, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Palette.bg,
          appBar: AppBar(
            backgroundColor: const Color(0xFF070C1C),
            foregroundColor: Palette.text,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Palette.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          body: SafeArea(child: page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentState = ref.watch(incidentControllerProvider);
    final recent = incidentState.incidents.take(4).toList(growable: false);
    final threatColor = sim.threatLevel == 'HIGH'
        ? Palette.red
        : sim.threatLevel == 'ELEVATED'
            ? Palette.amber
            : Palette.green;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _HeroCard(
          onCheck: () => _open(context, const CheckScreen(), 'Check'),
        ),
        const SizedBox(height: 14),
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: Palette.cyan,
            letterSpacing: 2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth > 760;
            final actions = [
              _QuickAction(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Check a message',
                subtitle: 'SMS, WhatsApp, email or social message',
                color: Palette.cyan,
                onTap: () => _open(
                  context,
                  const CheckScreen(),
                  'Check a message',
                ),
              ),
              _QuickAction(
                icon: Icons.link_rounded,
                title: 'Check a suspicious link',
                subtitle: 'Inspect domains and common scam tricks',
                color: Palette.violet,
                onTap: () => _open(context, const CheckScreen(), 'Check a link'),
              ),
              _QuickAction(
                icon: Icons.health_and_safety_outlined,
                title: 'Improve my protection',
                subtitle: 'Harden WhatsApp, SIM, email and money accounts',
                color: Palette.green,
                onTap: () => _open(
                  context,
                  const ProtectScreen(),
                  'Protection',
                ),
              ),
              _QuickAction(
                icon: Icons.emergency_outlined,
                title: 'I think I have been scammed',
                subtitle: 'Get immediate recovery steps and damage control',
                color: Palette.red,
                onTap: () => _open(context, const SosScreen(), 'Get help'),
              ),
            ];

            if (!wide) {
              return Column(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    actions[index],
                    if (index != actions.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: actions[0]),
                    const SizedBox(width: 8),
                    Expanded(child: actions[1]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: actions[2]),
                    const SizedBox(width: 8),
                    Expanded(child: actions[3]),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMO THREAT MONITOR',
                          style: TextStyle(
                            color: Palette.cyan,
                            letterSpacing: 2,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Prototype simulation — not live external threat data',
                          style: TextStyle(color: Palette.dim, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Palette.amber.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Palette.amber),
                    ),
                    child: const Text(
                      'SIMULATED DATA',
                      style: TextStyle(
                        color: Palette.amber,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth > 820;
                  final radar = SizedBox(
                    height: 270,
                    child: ThreatRadar(sim: sim),
                  );
                  final summary = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Training view',
                        style: TextStyle(
                          color: Palette.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'This animation demonstrates how future threat intelligence could look. It does not represent live reports from users, banks or networks.',
                        style: TextStyle(
                          color: Palette.dim,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Metric(
                            value: '${sim.scanned}',
                            label: 'DEMO SCANS',
                            color: Palette.cyan,
                          ),
                          const SizedBox(width: 8),
                          _Metric(
                            value: '${sim.blocked}',
                            label: 'DEMO BLOCKED',
                            color: Palette.red,
                          ),
                          const SizedBox(width: 8),
                          _Metric(
                            value: '${sim.suspicious}',
                            label: 'DEMO REVIEW',
                            color: Palette.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: threatColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: threatColor.withOpacity(0.22)),
                        ),
                        child: Text(
                          'Simulation threat level: ${sim.threatLevel}',
                          style: TextStyle(
                            color: threatColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  );

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(flex: 5, child: radar),
                        const SizedBox(width: 18),
                        Expanded(flex: 5, child: summary),
                      ],
                    );
                  }

                  return Column(
                    children: [radar, const SizedBox(height: 8), summary],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'RECENT INVESTIGATIONS',
                style: TextStyle(
                  color: Palette.cyan,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/evidence'),
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: Palette.cyan,
                size: 17,
              ),
              label: const Text(
                'Evidence Locker',
                style: TextStyle(color: Palette.cyan, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (incidentState.isLoading)
          const GlassCard(
            child: Row(
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
                  'Loading your investigations…',
                  style: TextStyle(color: Palette.dim),
                ),
              ],
            ),
          )
        else if (recent.isEmpty)
          GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history_rounded, color: Palette.dim),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No saved investigations yet',
                        style: TextStyle(
                          color: Palette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Suspicious and high-risk checks will appear here automatically after ScamShield saves them to your Evidence Locker.',
                        style: TextStyle(
                          color: Palette.dim,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      TextButton(
                        onPressed: () => _open(
                          context,
                          const CheckScreen(),
                          'Check something suspicious',
                        ),
                        child: const Text(
                          'Run a check',
                          style: TextStyle(color: Palette.cyan),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          for (final incident in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecentInvestigationCard(
                incident: incident,
                onTap: () => context.push('/evidence'),
              ),
            ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onCheck;

  const _HeroCard({required this.onCheck});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: Palette.cyan.withOpacity(0.26),
      tint: const Color(0x1600E5FF),
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth > 850;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Palette.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Palette.green.withOpacity(0.32)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded,
                        color: Palette.green, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'SCAMSHIELD ACTIVE',
                      style: TextStyle(
                        color: Palette.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Something feels wrong?',
                style: TextStyle(
                  color: Palette.text,
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check it before you click, reply, pay or share a code.',
                style:
                    TextStyle(color: Palette.dim, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 18),
              GlowButton(
                label: 'CHECK SOMETHING SUSPICIOUS',
                icon: Icons.manage_search_rounded,
                onTap: onCheck,
              ),
            ],
          );

          final score = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Palette.violet.withOpacity(0.08),
              border: Border.all(color: Palette.violet.withOpacity(0.26)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_person_outlined,
                    color: Palette.green, size: 42),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private by design',
                        style: TextStyle(
                          color: Palette.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your local investigations stay available in the Evidence Locker on this device.',
                        style: TextStyle(
                          color: Palette.dim,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(flex: 6, child: intro),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: score),
              ],
            );
          }

          return Column(
            children: [intro, const SizedBox(height: 18), score],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withOpacity(0.14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Palette.dim,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.025),
          border: Border.all(color: Palette.glassBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Palette.dim,
                fontSize: 8.5,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInvestigationCard extends StatelessWidget {
  final IncidentRecord incident;
  final VoidCallback onTap;

  const _RecentInvestigationCard({
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(incident.verdict);
    final created = incident.createdAt.toLocal();
    final when =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')} '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderColor: color.withOpacity(0.32),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: color.withOpacity(0.12),
              ),
              child: Icon(_verdictIcon(incident.verdict), color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          incident.category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Palette.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        when,
                        style:
                            const TextStyle(color: Palette.dim, fontSize: 9.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    incident.content.isEmpty
                        ? incident.sourceLabel
                        : incident.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Palette.dim,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.sourceLabel,
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${incident.riskScore}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                const Text(
                  'RISK',
                  style: TextStyle(
                    color: Palette.dim,
                    fontSize: 8,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _verdictColor(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return Palette.red;
    case InvestigationVerdict.suspicious:
      return Palette.amber;
    case InvestigationVerdict.lowRisk:
      return Palette.green;
  }
}

IconData _verdictIcon(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return Icons.gpp_bad_rounded;
    case InvestigationVerdict.suspicious:
      return Icons.warning_amber_rounded;
    case InvestigationVerdict.lowRisk:
      return Icons.verified_user_rounded;
  }
}
