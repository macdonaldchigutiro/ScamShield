import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../../data/services/incident_pdf_export_service.dart';
import '../../domain/entities/incident_record.dart';
import '../../domain/services/incident_report_formatter.dart';
import '../controllers/incident_controller.dart';

/// Main Evidence Locker view.
///
/// Suspicious and high-risk investigations are preserved here so users can
/// review evidence, add recovery details and export a portable incident report.
class EvidenceLockerScreen extends ConsumerWidget {
  const EvidenceLockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentControllerProvider);

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bgTop,
        foregroundColor: Palette.text,
        title: const Text(
          'Evidence Locker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          top: false,
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Palette.cyan),
                )
              : state.incidents.isEmpty
                  ? const _EmptyLocker()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        _LockerSummary(incidents: state.incidents),
                        const SizedBox(height: 16),
                        const Text(
                          'SAVED INCIDENTS',
                          style: TextStyle(
                            color: Palette.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final incident in state.incidents)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _IncidentCard(incident: incident),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _LockerSummary extends StatelessWidget {
  final List<IncidentRecord> incidents;

  const _LockerSummary({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final actionRequired = incidents
        .where((item) => item.status == IncidentStatus.actionRequired)
        .length;
    final highRisk = incidents
        .where((item) => item.verdict.name == 'highRisk')
        .length;

    return GlassCard(
      borderColor: Palette.violet.withOpacity(0.45),
      tint: const Color(0x127C5CFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Palette.violet),
              SizedBox(width: 9),
              Text(
                'YOUR EVIDENCE LOCKER',
                style: TextStyle(
                  color: Palette.violet,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Keep suspicious investigations together so you can act, report and explain what happened without rebuilding the story later.',
            style: TextStyle(color: Palette.dim, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  value: '${incidents.length}',
                  label: 'INCIDENTS',
                  color: Palette.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  value: '$highRisk',
                  label: 'HIGH RISK',
                  color: Palette.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  value: '$actionRequired',
                  label: 'ACTION NEEDED',
                  color: Palette.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
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
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends ConsumerWidget {
  final IncidentRecord incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _verdictColor(incident);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showIncidentSheet(context, ref, incident),
      child: GlassCard(
        borderColor: color.withOpacity(0.38),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.45), width: 2),
              ),
              child: Text(
                '${incident.riskScore}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.category,
                    style: const TextStyle(
                      color: Palette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${incident.id}  •  ${incident.sourceLabel}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Palette.dim, fontSize: 10.5),
                  ),
                  const SizedBox(height: 5),
                  _StatusPill(status: incident.status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Palette.dim),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IncidentStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      IncidentStatus.reviewing => ('REVIEWING', Palette.cyan),
      IncidentStatus.actionRequired => ('ACTION REQUIRED', Palette.amber),
      IncidentStatus.reported => ('REPORTED', Palette.violet),
      IncidentStatus.resolved => ('RESOLVED', Palette.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _EmptyLocker extends StatelessWidget {
  const _EmptyLocker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassCard(
          borderColor: Palette.green.withOpacity(0.3),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, color: Palette.green, size: 42),
              SizedBox(height: 12),
              Text(
                'Nothing in your Evidence Locker',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Palette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Suspicious and high-risk investigations will appear here automatically so important evidence is not lost.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.dim, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showIncidentSheet(
  BuildContext context,
  WidgetRef ref,
  IncidentRecord incident,
) {
  final notesController = TextEditingController(text: incident.notes);
  final amountController = TextEditingController(
    text: incident.amount?.toString() ?? '',
  );
  final referenceController = TextEditingController(
    text: incident.transactionReference ?? '',
  );

  IncidentRecord currentDraft() {
    // Build a fresh record instead of relying on copyWith so clearing optional
    // amount/reference fields is represented accurately in exported reports.
    return IncidentRecord(
      id: incident.id,
      createdAt: incident.createdAt,
      updatedAt: DateTime.now(),
      sourceLabel: incident.sourceLabel,
      content: incident.content,
      sender: incident.sender,
      riskScore: incident.riskScore,
      verdict: incident.verdict,
      category: incident.category,
      reasons: incident.reasons,
      recommendedActions: incident.recommendedActions,
      status: incident.status,
      notes: notesController.text.trim(),
      amount: double.tryParse(amountController.text.trim()),
      transactionReference: referenceController.text.trim().isEmpty
          ? null
          : referenceController.text.trim(),
    );
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A1226),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Palette.glassBorder)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Palette.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  incident.id,
                  style: const TextStyle(
                    color: Palette.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  incident.category,
                  style: const TextStyle(
                    color: Palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusPill(status: incident.status),
                const SizedBox(height: 16),
                GlassCard(
                  borderColor: _verdictColor(incident).withOpacity(0.45),
                  child: Row(
                    children: [
                      Text(
                        '${incident.riskScore}',
                        style: TextStyle(
                          color: _verdictColor(incident),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'RISK SCORE\nSaved from ScamShield investigation',
                          style: TextStyle(
                            color: Palette.dim,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _SheetLabel('EVIDENCE / CONTENT'),
                const SizedBox(height: 7),
                GlassCard(
                  child: SelectableText(
                    incident.content.isEmpty ? 'No text recorded.' : incident.content,
                    style: const TextStyle(color: Palette.text, height: 1.45),
                  ),
                ),
                if (incident.reasons.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const _SheetLabel('WHY IT WAS FLAGGED'),
                  const SizedBox(height: 7),
                  for (final reason in incident.reasons.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: GlassCard(
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reason.title,
                              style: const TextStyle(
                                color: Palette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              reason.explanation,
                              style: const TextStyle(
                                color: Palette.dim,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                const _SheetLabel('INCIDENT DETAILS'),
                const SizedBox(height: 7),
                GlassCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Palette.text),
                        decoration: const InputDecoration(
                          labelText: 'Amount lost / requested (optional)',
                          labelStyle: TextStyle(color: Palette.dim),
                        ),
                      ),
                      TextField(
                        controller: referenceController,
                        style: const TextStyle(color: Palette.text),
                        decoration: const InputDecoration(
                          labelText: 'Transaction / case reference (optional)',
                          labelStyle: TextStyle(color: Palette.dim),
                        ),
                      ),
                      TextField(
                        controller: notesController,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(color: Palette.text),
                        decoration: const InputDecoration(
                          labelText: 'Notes / actions already taken',
                          labelStyle: TextStyle(color: Palette.dim),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusButton(
                      label: 'REVIEWING',
                      status: IncidentStatus.reviewing,
                      incident: incident,
                    ),
                    _StatusButton(
                      label: 'REPORTED',
                      status: IncidentStatus.reported,
                      incident: incident,
                    ),
                    _StatusButton(
                      label: 'RESOLVED',
                      status: IncidentStatus.resolved,
                      incident: incident,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlowButton(
                  label: 'SAVE INCIDENT DETAILS',
                  icon: Icons.save_outlined,
                  onTap: () async {
                    await ref.read(incidentControllerProvider.notifier).updateIncident(
                          id: incident.id,
                          notes: notesController.text.trim(),
                          amount: double.tryParse(amountController.text.trim()),
                          transactionReference: referenceController.text.trim(),
                        );
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Incident details saved.'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 9),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final fileName = await const IncidentPdfExportService()
                          .export(currentDraft());
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('$fileName downloaded.'),
                          ),
                        );
                      }
                    } catch (error) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Could not download report: $error'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('DOWNLOAD PDF REPORT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.cyan,
                    foregroundColor: Palette.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: () async {
                    final report = const IncidentReportFormatter().format(
                      currentDraft(),
                    );
                    await Clipboard.setData(ClipboardData(text: report));
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Text report copied. You can paste it into an email, bank chat or fraud report.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('COPY TEXT REPORT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.cyan,
                    side: const BorderSide(color: Palette.cyan),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 9),
                TextButton.icon(
                  onPressed: () async {
                    await ref
                        .read(incidentControllerProvider.notifier)
                        .deleteIncident(incident.id);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Palette.red),
                  label: const Text(
                    'Delete incident',
                    style: TextStyle(color: Palette.red),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _StatusButton extends ConsumerWidget {
  final String label;
  final IncidentStatus status;
  final IncidentRecord incident;

  const _StatusButton({
    required this.label,
    required this.status,
    required this.incident,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () => ref
          .read(incidentControllerProvider.notifier)
          .updateIncident(id: incident.id, status: status),
      style: OutlinedButton.styleFrom(
        foregroundColor: incident.status == status ? Palette.green : Palette.dim,
        side: BorderSide(
          color: incident.status == status ? Palette.green : Palette.glassBorder,
        ),
      ),
      child: Text(label),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;

  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Palette.cyan,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      ),
    );
  }
}

Color _verdictColor(IncidentRecord incident) {
  switch (incident.verdict.name) {
    case 'highRisk':
      return Palette.red;
    case 'suspicious':
      return Palette.amber;
    default:
      return Palette.green;
  }
}
