import 'package:flutter/material.dart';

import 'analysis_view.dart';
import 'analyzer.dart';
import 'radar_view.dart';
import 'sim.dart';
import 'theme.dart';

class RadarScreen extends StatelessWidget {
  final ThreatSim sim;
  const RadarScreen({super.key, required this.sim});

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Palette.dim, fontSize: 9, letterSpacing: 1.5)),
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
    final types = sim.topTypes;
    final maxCount = types.isEmpty ? 1 : types.first.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('LIVE THREAT RADAR',
                      style: TextStyle(
                          color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: levelColor),
                    ),
                    child: Text('THREAT $level',
                        style: TextStyle(
                            color: levelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
              ThreatRadar(sim: sim),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(Palette.green, 'Safe'),
                  SizedBox(width: 16),
                  _Dot(Palette.amber, 'Suspicious'),
                  SizedBox(width: 16),
                  _Dot(Palette.red, 'Scam'),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat('SCANNED', '${sim.scanned}', Palette.cyan),
            const SizedBox(width: 8),
            _stat('SCAMS BLOCKED', '${sim.blocked}', Palette.red),
            const SizedBox(width: 8),
            _stat('SUSPICIOUS', '${sim.suspicious}', Palette.amber),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          borderColor: Palette.red.withOpacity(0.5),
          child: Row(
            children: [
              const Icon(Icons.phonelink_lock, color: Palette.red, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${sim.takeoverBlocked}',
                        style: const TextStyle(
                            color: Palette.red,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const Text(
                      'account takeover attempts caught: code theft, SIM swap, fake login pages',
                      style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: Palette.green, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$${sim.amountBlocked.round()}',
                        style: const TextStyle(
                            color: Palette.green,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const Text(
                      'asked for in the scams blocked so far (simulated)',
                      style: TextStyle(color: Palette.dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('WHERE SCAMS COME FROM',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final c in [Channel.whatsapp, Channel.sms, Channel.facebook, Channel.email, Channel.call])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Icon(channelIcon(c), color: Palette.violet, size: 20),
                        const SizedBox(height: 4),
                        Text('${sim.byChannel[c] ?? 0}',
                            style: const TextStyle(
                                color: Palette.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        Text(channelLabel(c) == 'Phone call' ? 'Calls' : channelLabel(c),
                            style: const TextStyle(
                                color: Palette.dim, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('SCAMS BY TYPE',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        GlassCard(
          child: types.isEmpty
              ? const Text('No scams blocked yet.',
                  style: TextStyle(color: Palette.dim))
              : Column(
                  children: [
                    for (final e in types)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 118,
                              child: Text(e.key,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Palette.text, fontSize: 12)),
                            ),
                            Expanded(
                              child: LayoutBuilder(builder: (context, box) {
                                final w = box.maxWidth * e.value / maxCount;
                                return Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Palette.glassBorder,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      width: w,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: dangerGradient,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Palette.red.withOpacity(0.5),
                                              blurRadius: 8)
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            SizedBox(
                              width: 30,
                              child: Text('${e.value}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: Palette.red,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        const Text('LIVE MESSAGES  (TAP ONE TO SEE WHY)',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        for (final m in sim.feed.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => showAnalysisSheet(context, m.text, m.a, sender: m.sender),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                borderColor: verdictColor(m.a.verdict).withOpacity(0.35),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: verdictColor(m.a.verdict).withOpacity(0.15),
                      ),
                      child: Icon(verdictIcon(m.a.verdict),
                          color: verdictColor(m.a.verdict), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.sender}  •  ${channelLabel(m.a.channel)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          Text(m.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Palette.dim, fontSize: 12, height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${m.a.score}',
                        style: TextStyle(
                            color: verdictColor(m.a.verdict),
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Palette.dim, fontSize: 11)),
      ],
    );
  }
}
