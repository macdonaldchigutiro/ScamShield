import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../check_screen.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../sos_screen.dart';
import '../../../../theme.dart';
import '../../../incidents/domain/entities/incident_record.dart';
import '../../../incidents/presentation/controllers/incident_controller.dart';
import '../../../protection/presentation/controllers/protection_controller.dart';
import '../../../scam_check/presentation/screens/media_investigator_screen.dart';

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
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
          onOpenProtect: () =>
              ref.read(selectedHomeTabProvider.notifier).state = 2,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 30),
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
              const SizedBox(height: 18),
              const _PrivacyStrip(),
              const SizedBox(height: 24),
              _RecentHeader(onEvidence: () => context.push('/evidence')),
              const SizedBox(height: 10),
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
                onTap: () => _open(context, const SosScreen(), 'Emergency help'),
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
    return Stack(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(26),
          borderColor: Palette.cyan.withOpacity(.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AfricanAccent(width: 82),
              const SizedBox(height: 14),
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
                  color: Palette.textSecondary,
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
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Palette.cyan.withOpacity(.32)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.content_paste_go_rounded, color: Palette.cyan),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Paste a message, link or number',
                            style: TextStyle(color: Palette.textSecondary, fontSize: 17),
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
                  color: Palette.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _CheckChip(icon: Icons.chat_bubble_outline_rounded, label: 'Message', onTap: onMessage),
                  _CheckChip(icon: Icons.link_rounded, label: 'Link', onTap: onLink),
                  _CheckChip(icon: Icons.phone_outlined, label: 'Phone number', onTap: onNumber),
                  _CheckChip(icon: Icons.image_outlined, label: 'Screenshot', onTap: onScreenshot),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          right: 18,
          top: 18,
          child: IgnorePointer(
            child: Opacity(
              opacity: .055,
              child: _AfricanPatternMark(size: 126),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CheckChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 19, color: Palette.cyan),
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

  const _ProtectionCard({required this.state, required this.onOpenProtect});

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
      padding: const EdgeInsets.all(22),
      borderColor: Palette.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR PROTECTION',
                  style: TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _AfricanAccent(width: 62, color: color),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: Palette.cyan),
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CustomPaint(
                    painter: RingPainter(progress, color, thickness: 10),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.completedCount}/${state.totalCount}',
                            style: const TextStyle(
                              color: Palette.text,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'STEPS',
                            style: TextStyle(
                              color: Palette.muted,
                              fontSize: 8,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.completedCount} of ${state.totalCount} safety steps completed',
                        style: const TextStyle(
                          color: Palette.textSecondary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: color,
              backgroundColor: Palette.line,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenProtect,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Improve my protection'),
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.cyan.withOpacity(.16),
                  foregroundColor: Palette.violet,
                  side: BorderSide(color: Palette.cyan.withOpacity(.45)),
                  minimumSize: const Size(48, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacyStrip extends StatelessWidget {
  const _PrivacyStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Palette.green.withOpacity(.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.green.withOpacity(.24)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_person_outlined, color: Palette.green, size: 24),
          SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Palette.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Private by design. ',
                    style: TextStyle(
                      color: Palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Saved investigations stay on this device unless you choose a feature that explicitly sends data elsewhere.',
                  ),
                ],
              ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your recent investigations',
                style: TextStyle(
                  color: Palette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'The latest cases saved to your Evidence Locker.',
                style: TextStyle(color: Palette.textSecondary, fontSize: 12.5),
              ),
            ],
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
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Palette.cyan.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.cyan.withOpacity(.22)),
            ),
            child: const Icon(Icons.history_rounded, color: Palette.cyan),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No investigations saved yet',
                  style: TextStyle(color: Palette.text, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Suspicious and high-risk checks will appear here with their source, status and evidence preview.',
                  style: TextStyle(color: Palette.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onStart,
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.text,
              side: const BorderSide(color: Palette.line),
              minimumSize: const Size(48, 46),
            ),
            child: const Text('Start a check'),
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
        color: Palette.red.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.red.withOpacity(.42)),
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
                  style: TextStyle(color: Palette.text, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'Open the emergency recovery guide for step-by-step help.',
                  style: TextStyle(color: Palette.textSecondary, fontSize: 14),
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
            child: const Text("I've been scammed", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _RecentInvestigationCard extends StatelessWidget {
  final IncidentRecord incident;
  final VoidCallback onTap;

  const _RecentInvestigationCard({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = incident.riskScore == 0 ? Palette.cyan : _verdictColor(incident.verdict);
    final preview = incident.content.replaceAll(RegExp(r'\s+'), ' ').trim();
    final statusColor = _statusColor(incident.status);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassCard(
          padding: const EdgeInsets.all(15),
          borderColor: color.withOpacity(.28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: color.withOpacity(.1),
                  border: Border.all(color: color.withOpacity(.3)),
                ),
                child: incident.riskScore == 0
                    ? const Text(
                        'CASE',
                        style: TextStyle(
                          color: Palette.cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${incident.riskScore}',
                            style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900),
                          ),
                          const Text('RISK', style: TextStyle(color: Palette.muted, fontSize: 8)),
                        ],
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            incident.category,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Palette.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _friendlyDate(incident.createdAt),
                          style: const TextStyle(color: Palette.muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Palette.textSecondary, fontSize: 13, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _MiniBadge(label: incident.sourceLabel, color: Palette.cyan),
                        if (incident.riskScore != 0)
                          _MiniBadge(label: _verdictLabel(incident.verdict), color: color),
                        _MiniBadge(label: _statusLabel(incident.status), color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Icon(Icons.chevron_right_rounded, color: Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AfricanAccent extends StatelessWidget {
  final double width;
  final Color color;

  const _AfricanAccent({this.width = 72, this.color = Palette.cyan});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 10,
      child: CustomPaint(painter: _AfricanAccentPainter(color)),
    );
  }
}

class _AfricanPatternMark extends StatelessWidget {
  final double size;
  const _AfricanPatternMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _AfricanPatternPainter()),
    );
  }
}

class _AfricanAccentPainter extends CustomPainter {
  final Color color;
  const _AfricanAccentPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final segment = size.width / 6;
    for (var i = 0; i < 6; i++) {
      final left = i * segment;
      final path = Path()
        ..moveTo(left, size.height)
        ..lineTo(left + segment / 2, 1)
        ..lineTo(left + segment, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AfricanAccentPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AfricanPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const rows = 4;
    const cols = 4;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final left = x * cellW;
        final top = y * cellH;
        final path = Path()
          ..moveTo(left + cellW * .1, top + cellH * .8)
          ..lineTo(left + cellW * .5, top + cellH * .15)
          ..lineTo(left + cellW * .9, top + cellH * .8)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

String _verdictLabel(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return 'High risk';
    case InvestigationVerdict.suspicious:
      return 'Suspicious';
    case InvestigationVerdict.lowRisk:
      return 'Low risk';
  }
}

Color _statusColor(IncidentStatus status) {
  switch (status) {
    case IncidentStatus.reviewing:
      return Palette.cyan;
    case IncidentStatus.actionRequired:
      return Palette.amber;
    case IncidentStatus.reported:
      return Palette.violet;
    case IncidentStatus.resolved:
      return Palette.green;
  }
}

String _statusLabel(IncidentStatus status) {
  switch (status) {
    case IncidentStatus.reviewing:
      return 'Reviewing';
    case IncidentStatus.actionRequired:
      return 'Action required';
    case IncidentStatus.reported:
      return 'Reported';
    case IncidentStatus.resolved:
      return 'Resolved';
  }
}

String _friendlyDate(DateTime value) {
  final now = DateTime.now();
  final local = value.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final difference = today.difference(date).inDays;

  String clock(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  if (difference == 0) return 'Today, ${clock(local)}';
  if (difference == 1) return 'Yesterday, ${clock(local)}';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]}';
}
