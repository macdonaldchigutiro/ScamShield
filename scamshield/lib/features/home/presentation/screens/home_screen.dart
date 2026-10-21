import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../check_screen.dart';
import '../../../../sos_screen.dart';
import '../../../../theme.dart';
import '../../../incidents/domain/entities/incident_record.dart';
import '../../../incidents/presentation/controllers/incident_controller.dart';
import '../../../protection/presentation/controllers/protection_controller.dart';
import '../../../scam_check/presentation/screens/media_investigator_screen.dart';

/// Friendly, action-first Home screen.
///
/// The screen deliberately avoids invented threat statistics. Its personal
/// status and recent activity are derived from persistent protection actions
/// and real investigations stored in the Evidence Locker.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget page, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Palette.bg,
          appBar: AppBar(
            backgroundColor: Palette.bg,
            foregroundColor: Palette.text,
            elevation: 0,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(child: page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentControllerProvider);
    final protection = ref.watch(protectionControllerProvider);
    final recent = incidents.incidents.take(4).toList(growable: false);

    void openCheck() => _open(context, const CheckScreen(), 'Check');
    void openScreenshot() => _open(
          context,
          const MediaInvestigatorScreen(),
          'Check screenshot or QR',
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        final padding = wide ? 28.0 : 16.0;

        final checkCard = _CheckCard(
          onMessage: openCheck,
          onLink: openCheck,
          onNumber: openCheck,
          onScreenshot: openScreenshot,
        );

        final protectionCard = _ProtectionCard(
          state: protection,
          onOpenProtect: () {
            // The shell owns the primary Protect tab. This event lets Home ask
            // the shell to switch without duplicating another navigation stack.
            ref.read(selectedHomeTabProvider.notifier).state = 2;
          },
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: checkCard),
                    const SizedBox(width: 22),
                    Expanded(flex: 2, child: protectionCard),
                  ],
                )
              else ...[
                checkCard,
                const SizedBox(height: 18),
                protectionCard,
              ],
              const SizedBox(height: 22),
              _PrivacyCard(),
              const SizedBox(height: 22),
              _RecentHeader(onEvidence: () => context.push('/evidence')),
              const SizedBox(height: 8),
              if (incidents.isLoading)
                const _LoadingCard()
              else if (recent.isEmpty)
                _EmptyRecent(onStart: openCheck)
              else
                for (final incident in recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentInvestigationCard(
                      incident: incident,
                      onTap: () => context.push('/evidence'),
                    ),
                  ),
              const SizedBox(height: 14),
              _EmergencyCard(
                onTap: () => _open(
                  context,
                  const SosScreen(),
                  'Emergency help',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckCard extends StatelessWidget {
  final VoidCallback onMessage;
  final VoidCallback onLink;
  final VoidCallback onNumber;
  final VoidCallback onScreenshot;

  const _CheckCard({
    required this.onMessage,
    required this.onLink,
    required this.onNumber,
    required this.onScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: Palette.cyan.withOpacity(.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Got a message that feels off?',
            style: TextStyle(
              color: Palette.text,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Check it before you click, reply, pay or share a code.',
            style: TextStyle(
              color: Palette.dim,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: Palette.surfaceHi,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onMessage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 66),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Palette.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.content_paste_go_rounded, color: Palette.cyan),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste a message, link or number',
                        style: TextStyle(color: Palette.dim, fontSize: 17),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Palette.cyan),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Or check something else',
            style: TextStyle(
              color: Palette.dim,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _CheckChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                onTap: onMessage,
              ),
              _CheckChip(
                icon: Icons.link_rounded,
                label: 'Link',
                onTap: onLink,
              ),
              _CheckChip(
                icon: Icons.phone_outlined,
                label: 'Phone number',
                onTap: onNumber,
              ),
              _CheckChip(
                icon: Icons.image_outlined,
                label: 'Screenshot',
                onTap: onScreenshot,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CheckChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 19, color: Palette.text),
      label: Text(
        label,
        style: const TextStyle(
          color: Palette.text,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Palette.surfaceHi,
      side: const BorderSide(color: Palette.line),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  final ProtectionState state;
  final VoidCallback onOpenProtect;

  const _ProtectionCard({
    required this.state,
    required this.onOpenProtect,
  });

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final color = state.percentage >= 80
        ? Palette.green
        : state.percentage >= 40
            ? Palette.amber
            : Palette.cyan;
    final label = state.percentage >= 80
        ? 'Strong protection'
        : state.percentage >= 40
            ? 'Partly protected'
            : 'Build your protection';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PROTECTION',
            style: TextStyle(
              color: Palette.dim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(26),
                child: CircularProgressIndicator(color: Palette.cyan),
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CustomPaint(
                    painter: RingPainter(progress, color, thickness: 9),
                    child: Center(
                      child: Text(
                        '${state.completedCount}/${state.totalCount}',
                        style: const TextStyle(
                          color: Palette.text,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.percentage}% based only on safety steps you have confirmed.',
                        style: const TextStyle(
                          color: Palette.dim,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: color,
              backgroundColor: Palette.line,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenProtect,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Improve my protection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.text,
                  side: const BorderSide(color: Palette.line),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_person_outlined, color: Palette.green, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by design',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your saved investigations and protection progress are stored locally on this device. ScamShield does not claim a message was uploaded unless a feature explicitly says it sends data elsewhere.',
                  style: TextStyle(
                    color: Palette.dim,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  final VoidCallback onEvidence;

  const _RecentHeader({required this.onEvidence});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your recent investigations',
            style: TextStyle(
              color: Palette.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onEvidence,
          icon: const Icon(Icons.inventory_2_outlined, size: 19),
          label: const Text('Evidence Locker'),
          style: TextButton.styleFrom(foregroundColor: Palette.cyan),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading your investigations…'),
        ],
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyRecent({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nothing saved yet',
            style: TextStyle(
              color: Palette.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Suspicious and high-risk checks are saved on this device so you can review them later or export a report.',
            style: TextStyle(
              color: Palette.dim,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onStart,
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.text,
              side: const BorderSide(color: Palette.line),
              minimumSize: const Size(48, 48),
            ),
            child: const Text('Check your first message'),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmergencyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Palette.red.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.red.withOpacity(.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: Palette.red, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Already sent money, shared a code or lost an account?',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Open the emergency recovery guide for step-by-step help.',
                  style: TextStyle(color: Palette.dim, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Palette.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            child: const Text(
              "I've been scammed",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          borderColor: color.withOpacity(.28),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withOpacity(.12),
                ),
                child: Icon(_verdictIcon(incident.verdict), color: color),
              ),
              const SizedBox(width: 12),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          when,
                          style: const TextStyle(
                            color: Palette.dim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.content.isEmpty
                          ? incident.sourceLabel
                          : incident.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Palette.dim,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      incident.sourceLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '${incident.riskScore}',
                    style: TextStyle(
                      color: color,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'RISK',
                    style: TextStyle(color: Palette.dim, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
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
