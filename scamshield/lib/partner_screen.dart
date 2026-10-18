import 'package:flutter/material.dart';

import 'analysis_view.dart';
import 'analyzer.dart';
import 'sim.dart';
import 'theme.dart';

/// A view for telcos, banks and police. Prototype with sample data.
class PartnerScreen extends StatelessWidget {
  final ThreatSim sim;
  const PartnerScreen({super.key, required this.sim});

  Widget _tile(String label, String value, Color color) {
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
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Palette.dim, fontSize: 9, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  void _send(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('$what (simulated)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: sim,
            builder: (context, _) {
              final senders = sim.topSenders;
              final maxS = senders.isEmpty ? 1 : senders.first.value;
              final channels = Channel.values
                  .where((c) => (sim.byChannel[c] ?? 0) > 0)
                  .toList()
                ..sort((a, b) =>
                    (sim.byChannel[b] ?? 0).compareTo(sim.byChannel[a] ?? 0));
              final maxC = channels.isEmpty ? 1 : (sim.byChannel[channels.first] ?? 1);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Palette.text),
                      ),
                      const Expanded(
                        child: Text('PARTNER VIEW',
                            style: TextStyle(
                                color: Palette.cyan,
                                letterSpacing: 3,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Palette.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Palette.amber),
                        ),
                        child: const Text('SAMPLE DATA',
                            style: TextStyle(
                                color: Palette.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'For mobile networks, banks, mobile money providers and police. Spot scam campaigns early and act together.',
                      style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _tile('NUMBERS FLAGGED', '${sim.senderCounts.length}', Palette.red),
                      const SizedBox(width: 8),
                      _tile('SCAMS CAUGHT', '${sim.blocked}', Palette.amber),
                      const SizedBox(width: 8),
                      _tile('TAKEOVER ATTEMPTS', '${sim.takeoverBlocked}', Palette.violet),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('MOST ACTIVE SCAM NUMBERS',
                      style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: senders.isEmpty
                        ? const Text('Nothing flagged yet.',
                            style: TextStyle(color: Palette.dim))
                        : Column(
                            children: [
                              for (final e in senders)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(e.key,
                                                style: const TextStyle(
                                                    color: Palette.text,
                                                    fontFamily: 'monospace',
                                                    fontSize: 13)),
                                          ),
                                          Text('${e.value} scams',
                                              style: const TextStyle(
                                                  color: Palette.red,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      Text(sim.senderType[e.key] ?? '',
                                          style: const TextStyle(
                                              color: Palette.dim, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: e.value / maxS,
                                          minHeight: 5,
                                          color: Palette.red,
                                          backgroundColor: Palette.glassBorder,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Text('SCAMS BY CHANNEL',
                      style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      children: [
                        for (final c in channels)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(channelIcon(c), color: Palette.violet, size: 18),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 78,
                                  child: Text(channelLabel(c),
                                      style: const TextStyle(
                                          color: Palette.text, fontSize: 12)),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: (sim.byChannel[c] ?? 0) / maxC,
                                      minHeight: 6,
                                      color: Palette.violet,
                                      backgroundColor: Palette.glassBorder,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Text('${sim.byChannel[c] ?? 0}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          color: Palette.text,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('RECOMMENDED ACTIONS',
                      style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
                  const SizedBox(height: 8),
                  _action(context, Icons.block, Palette.red,
                      'Block the top ${senders.length} numbers',
                      'These numbers keep sending scams. Networks can block or rate-limit them.',
                      'SEND TO NETWORK', 'Block request sent'),
                  _action(context, Icons.campaign_outlined, Palette.amber,
                      'Warn customers about code theft',
                      'Send an SMS and WhatsApp notice: never share a 6-digit code, even with a friend.',
                      'SEND PUBLIC WARNING', 'Warning scheduled'),
                  _action(context, Icons.local_police_outlined, Palette.violet,
                      'Pass repeat offenders to police',
                      'Share the numbers, times and message types so cases can be linked together.',
                      'SEND TO POLICE', 'Case file shared'),
                  const SizedBox(height: 10),
                  const GlassCard(
                    child: Text(
                      'Privacy: partners see reported numbers and scam types, not people\'s private messages. A real version needs signed agreements and clear safeguards. All data here is simulated.',
                      style: TextStyle(color: Palette.dim, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, Color color, String title,
      String body, String button, String done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderColor: color.withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Palette.text, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(body,
                style: const TextStyle(color: Palette.dim, fontSize: 12, height: 1.35)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _send(context, done),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color),
                ),
                child: Text(button,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
