import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../../../incidents/domain/entities/incident_record.dart';
import '../../../incidents/presentation/controllers/incident_controller.dart';

/// Lightweight threat-intelligence view built only from saved ScamShield cases.
///
/// No external reputation or simulated data is mixed into this screen. It is
/// intentionally labelled local evidence so users and reviewers can understand
/// exactly where every count comes from.
class ThreatIntelligenceScreen extends ConsumerWidget {
  const ThreatIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentControllerProvider);
    final incidents = state.incidents;
    final categories = _count(incidents.map((e) => e.category));
    final sources = _count(incidents.map((e) => e.sourceLabel));
    final senders = _count(
      incidents.map((e) => e.sender.trim()).where((e) => e.isNotEmpty),
    );
    final domains = _count(
      incidents.expand((e) => _domainsFrom(e.content)),
    );

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bgTop,
        foregroundColor: Palette.text,
        title: const Text(
          'Threat Intelligence',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CyberBackground(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Palette.cyan),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  GlassCard(
                    borderColor: Palette.violet.withOpacity(.45),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.radar_rounded, color: Palette.violet),
                            SizedBox(width: 8),
                            Text(
                              'LOCAL EVIDENCE INTELLIGENCE',
                              style: TextStyle(
                                color: Palette.violet,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This view summarises only incidents saved in this device\'s Evidence Locker. It is not a live national threat feed and does not invent report counts.',
                          style: TextStyle(
                            color: Palette.dim,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _overview(incidents),
                  const SizedBox(height: 14),
                  _responseLifecycle(incidents),
                  const SizedBox(height: 14),
                  _section('Top scam categories', categories, Icons.category_outlined),
                  const SizedBox(height: 12),
                  _section('Investigation sources', sources, Icons.source_outlined),
                  const SizedBox(height: 12),
                  _section('Repeated senders / accounts', senders, Icons.person_search_outlined),
                  const SizedBox(height: 12),
                  _section('Domains seen in saved evidence', domains, Icons.language_outlined),
                ],
              ),
      ),
    );
  }

  Widget _overview(List<IncidentRecord> incidents) {
    final actionRequired = incidents
        .where((e) => e.status == IncidentStatus.actionRequired)
        .length;
    final reported =
        incidents.where((e) => e.status == IncidentStatus.reported).length;
    final resolved =
        incidents.where((e) => e.status == IncidentStatus.resolved).length;
    final highRisk = incidents.where((e) => e.verdict.name == 'highRisk').length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metric('Saved cases', incidents.length, Palette.cyan),
        _metric('High risk', highRisk, Palette.red),
        _metric('Action needed', actionRequired, Palette.amber),
        _metric('Reported', reported, Palette.violet),
        _metric('Resolved', resolved, Palette.green),
      ],
    );
  }

  Widget _responseLifecycle(List<IncidentRecord> incidents) {
    final reviewing =
        incidents.where((e) => e.status == IncidentStatus.reviewing).length;
    final containment = incidents
        .where((e) => e.status == IncidentStatus.actionRequired)
        .length;
    final reported =
        incidents.where((e) => e.status == IncidentStatus.reported).length;
    final recovered =
        incidents.where((e) => e.status == IncidentStatus.resolved).length;

    final stages = [
      ('Detection / triage', reviewing, Palette.cyan, Icons.search_rounded),
      ('Containment', containment, Palette.amber, Icons.gpp_maybe_outlined),
      ('Reported / escalation', reported, Palette.violet, Icons.outgoing_mail),
      ('Recovery / resolved', recovered, Palette.green, Icons.task_alt_rounded),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INCIDENT RESPONSE LIFECYCLE',
            style: TextStyle(
              color: Palette.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'A SOC-style view of where saved cases currently sit. Counts come from the Evidence Locker status, not simulated events or invented timestamps.',
            style: TextStyle(color: Palette.dim, height: 1.4, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < stages.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stages[i].$3.withOpacity(.11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: stages[i].$3.withOpacity(.35)),
                  ),
                  child: Icon(stages[i].$4, color: stages[i].$3, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stages[i].$1,
                    style: const TextStyle(
                      color: Palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${stages[i].$2}',
                  style: TextStyle(
                    color: stages[i].$3,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (i != stages.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 18),
                width: 2,
                height: 12,
                color: Palette.line,
              ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Palette.dim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    Map<String, int> values,
    IconData icon,
  ) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Palette.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Palette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text(
              'No local evidence yet.',
              style: TextStyle(color: Palette.dim),
            )
          else
            for (final entry in entries.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Palette.text, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Palette.cyan.withOpacity(.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Palette.cyan.withOpacity(.28)),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Palette.cyan,
                          fontWeight: FontWeight.w800,
                        ),
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

Map<String, int> _count(Iterable<String> values) {
  final counts = <String, int>{};
  for (final raw in values) {
    final value = raw.trim();
    if (value.isEmpty) continue;
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

Iterable<String> _domainsFrom(String content) sync* {
  final matches = RegExp(
    r'https?://(?:www\.)?([A-Z0-9.-]+\.[A-Z]{2,})',
    caseSensitive: false,
  ).allMatches(content);
  for (final match in matches) {
    final domain = match.group(1)?.toLowerCase();
    if (domain != null && domain.isNotEmpty) yield domain;
  }
}
