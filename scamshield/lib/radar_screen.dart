import 'package:flutter/material.dart';

import 'analysis_view.dart';
import 'analyzer.dart';
import 'check_screen.dart';
import 'protect_screen.dart';
import 'radar_view.dart';
import 'sim.dart';
import 'sos_screen.dart';
import 'theme.dart';

class RadarScreen extends StatelessWidget {
  final ThreatSim sim;
  const RadarScreen({super.key, required this.sim});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
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
                  Text(title,
                      style: const TextStyle(
                          color: Palette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Palette.dim, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: color.withOpacity(0.9), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.025),
          border: Border.all(color: Palette.glassBorder),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Palette.dim, fontSize: 9, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = sim.threatLevel;
    final levelColor = level == 'HIGH'
        ? Palette.red
        : (level == 'ELEVATED' ? Palette.amber : Palette.green);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        GlassCard(
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Palette.green.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Palette.green.withOpacity(0.32)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: Palette.green, size: 14),
                        SizedBox(width: 6),
                        Text('SCAMSHIELD ACTIVE',
                            style: TextStyle(
                                color: Palette.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4)),
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
                    style: TextStyle(
                        color: Palette.dim, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  GlowButton(
                    label: 'CHECK SOMETHING SUSPICIOUS',
                    icon: Icons.manage_search_rounded,
                    onTap: () => _open(context, const CheckScreen()),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Palette.dim, size: 15),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Private by design • analysis stays on this device in the prototype',
                          style: TextStyle(color: Palette.dim, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final score = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Palette.violet.withOpacity(0.16),
                      Palette.cyan.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(color: Palette.violet.withOpacity(0.26)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 94,
                      height: 94,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size.square(94),
                            painter: RingPainter(0.82, Palette.green, thickness: 8),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('82',
                                  style: TextStyle(
                                      color: Palette.text,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900)),
                              Text('PROTECTED',
                                  style: TextStyle(
                                      color: Palette.dim,
                                      fontSize: 8,
                                      letterSpacing: 1.0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your protection score',
                              style: TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          SizedBox(height: 6),
                          Text(
                            'Strong start. Two account-safety actions can make you harder to scam.',
                            style: TextStyle(
                                color: Palette.dim, fontSize: 11, height: 1.35),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 7, color: Palette.amber),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text('2 actions recommended',
                                    style: TextStyle(
                                        color: Palette.amber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
        const SizedBox(height: 14),
        const Text('QUICK ACTIONS',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth > 760;
            final actions = [
              _quickAction(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Check a message',
                subtitle: 'SMS, WhatsApp, email or social message',
                color: Palette.cyan,
                onTap: () => _open(context, const CheckScreen()),
              ),
              _quickAction(
                context,
                icon: Icons.link_rounded,
                title: 'Check a suspicious link',
                subtitle: 'Inspect wording, domains and common scam tricks',
                color: Palette.violet,
                onTap: () => _open(context, const CheckScreen()),
              ),
              _quickAction(
                context,
                icon: Icons.health_and_safety_outlined,
                title: 'Improve my protection',
                subtitle: 'Harden WhatsApp, SIM, email and money accounts',
                color: Palette.green,
                onTap: () => _open(context, const ProtectScreen()),
              ),
              _quickAction(
                context,
                icon: Icons.emergency_outlined,
                title: 'I think I have been scammed',
                subtitle: 'Get immediate recovery steps and damage control',
                color: Palette.red,
                onTap: () => _open(context, const SosScreen()),
              ),
            ];

            if (!wide) {
              return Column(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    actions[i],
                    if (i != actions.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Column(
              children: [
                Row(children: [Expanded(child: actions[0]), const SizedBox(width: 8), Expanded(child: actions[1])]),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: actions[2]), const SizedBox(width: 8), Expanded(child: actions[3])]),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THREAT PULSE',
                          style: TextStyle(
                              color: Palette.cyan,
                              letterSpacing: 2,
                              fontSize: 11)),
                      SizedBox(height: 3),
                      Text('Prototype intelligence feed',
                          style: TextStyle(color: Palette.dim, fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: levelColor.withOpacity(0.7)),
                    ),
                    child: Text('THREAT $level',
                        style: TextStyle(
                            color: levelColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
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
                      const Text('What ScamShield is seeing',
                          style: TextStyle(
                              color: Palette.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'Account takeover, code theft and payment redirection are the strongest signals in this simulated feed.',
                        style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _metric('${sim.scanned}', 'SCANNED', Palette.cyan),
                          const SizedBox(width: 8),
                          _metric('${sim.blocked}', 'BLOCKED', Palette.red),
                          const SizedBox(width: 8),
                          _metric('${sim.suspicious}', 'SUSPICIOUS', Palette.amber),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Palette.red.withOpacity(0.06),
                          border: Border.all(color: Palette.red.withOpacity(0.22)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phonelink_lock_rounded,
                                color: Palette.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${sim.takeoverBlocked} account takeover attempts identified in the simulation',
                                style: const TextStyle(
                                    color: Palette.text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
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
                  return Column(children: [radar, const SizedBox(height: 8), summary]);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('RECENT SIGNALS',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        for (final m in sim.feed.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showAnalysisSheet(context, m.text, m.a, sender: m.sender),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                borderColor: verdictColor(m.a.verdict).withOpacity(0.28),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: verdictColor(m.a.verdict).withOpacity(0.12),
                      ),
                      child: Icon(verdictIcon(m.a.verdict),
                          color: verdictColor(m.a.verdict), size: 21),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.sender} • ${channelLabel(m.a.channel)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(m.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Palette.dim, fontSize: 11, height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${m.a.score}',
                            style: TextStyle(
                                color: verdictColor(m.a.verdict),
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                        const Text('RISK',
                            style: TextStyle(
                                color: Palette.dim,
                                fontSize: 8,
                                letterSpacing: 1.0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
