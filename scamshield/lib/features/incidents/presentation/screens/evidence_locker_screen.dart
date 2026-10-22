import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../../data/services/incident_backup_export_service.dart';
import '../../data/services/incident_pdf_export_service.dart';
import '../../domain/entities/incident_record.dart';
import '../../domain/services/incident_report_formatter.dart';
import '../controllers/incident_controller.dart';

enum _LockerFilter { all, actionRequired, reported, resolved }

class EvidenceLockerScreen extends ConsumerStatefulWidget {
  const EvidenceLockerScreen({super.key});

  @override
  ConsumerState<EvidenceLockerScreen> createState() =>
      _EvidenceLockerScreenState();
}

class _EvidenceLockerScreenState extends ConsumerState<EvidenceLockerScreen> {
  _LockerFilter _filter = _LockerFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incidentControllerProvider);
    final filtered = _applyFilter(state.incidents);

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bgTop,
        foregroundColor: Palette.text,
        title: const Text(
          'Evidence Locker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (state.incidents.isNotEmpty)
            IconButton(
              tooltip: 'Export all evidence',
              onPressed: () => _exportAll(context, state.incidents),
              icon: const Icon(Icons.archive_outlined),
            ),
        ],
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
                        _LockerSummary(
                          incidents: state.incidents,
                          onExportAll: () => _exportAll(context, state.incidents),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'FIND AN INCIDENT',
                          style: TextStyle(
                            color: Palette.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'All',
                                selected: _filter == _LockerFilter.all,
                                onSelected: () => setState(
                                  () => _filter = _LockerFilter.all,
                                ),
                              ),
                              _FilterChip(
                                label: 'Action required',
                                selected: _filter == _LockerFilter.actionRequired,
                                onSelected: () => setState(
                                  () => _filter = _LockerFilter.actionRequired,
                                ),
                              ),
                              _FilterChip(
                                label: 'Reported',
                                selected: _filter == _LockerFilter.reported,
                                onSelected: () => setState(
                                  () => _filter = _LockerFilter.reported,
                                ),
                              ),
                              _FilterChip(
                                label: 'Resolved',
                                selected: _filter == _LockerFilter.resolved,
                                onSelected: () => setState(
                                  () => _filter = _LockerFilter.resolved,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'SAVED INCIDENTS',
                                style: TextStyle(
                                  color: Palette.cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Text(
                              '${filtered.length} shown',
                              style: const TextStyle(
                                color: Palette.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (filtered.isEmpty)
                          const GlassCard(
                            child: Row(
                              children: [
                                Icon(Icons.filter_alt_off_outlined, color: Palette.muted),
                                SizedBox(width: 10),
                                Text(
                                  'No incidents match this filter.',
                                  style: TextStyle(color: Palette.textSecondary),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final incident in filtered)
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

  List<IncidentRecord> _applyFilter(List<IncidentRecord> incidents) {
    switch (_filter) {
      case _LockerFilter.all:
        return incidents;
      case _LockerFilter.actionRequired:
        return incidents
            .where((item) => item.status == IncidentStatus.actionRequired)
            .toList();
      case _LockerFilter.reported:
        return incidents
            .where((item) => item.status == IncidentStatus.reported)
            .toList();
      case _LockerFilter.resolved:
        return incidents
            .where((item) => item.status == IncidentStatus.resolved)
            .toList();
    }
  }

  Future<void> _exportAll(
    BuildContext context,
    List<IncidentRecord> incidents,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export all evidence?'),
        content: const Text(
          'This creates a JSON backup containing the complete Evidence Locker, including private messages, numbers and notes. Store it somewhere secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final fileName = await const IncidentBackupExportService().exportAll(incidents);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName downloaded.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export backup: $error')),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        label: Text(label),
        showCheckmark: selected,
        selectedColor: Palette.cyan.withOpacity(.15),
        backgroundColor: Palette.surface,
        labelStyle: TextStyle(
          color: selected ? Palette.text : Palette.textSecondary,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? Palette.cyan : Palette.line,
        ),
      ),
    );
  }
}

class _LockerSummary extends StatelessWidget {
  final List<IncidentRecord> incidents;
  final VoidCallback onExportAll;

  const _LockerSummary({
    required this.incidents,
    required this.onExportAll,
  });

  @override
  Widget build(BuildContext context) {
    final actionRequired = incidents
        .where((item) => item.status == IncidentStatus.actionRequired)
        .length;
    final highRisk = incidents
        .where((item) => item.verdict.name == 'highRisk' && item.riskScore > 0)
        .length;

    return GlassCard(
      borderColor: Palette.cyan.withOpacity(0.38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Palette.cyan.withOpacity(.09),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Palette.cyan.withOpacity(.25)),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Palette.cyan),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence Locker',
                      style: TextStyle(
                        color: Palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Saved investigations and recovery cases on this device.',
                      style: TextStyle(color: Palette.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onExportAll,
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Export all'),
              ),
            ],
          ),
          const SizedBox(height: 15),
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
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
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
              color: Palette.textSecondary,
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
    final preview = _preview(incident.content);
    final statusColor = _statusStyle(incident.status).$2;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showIncidentSheet(context, ref, incident),
        child: GlassCard(
          padding: const EdgeInsets.all(15),
          borderColor: color.withOpacity(0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: color.withOpacity(0.34)),
                ),
                child: incident.riskScore == 0
                    ? const Text(
                        'CASE',
                        style: TextStyle(
                          color: Palette.cyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: .8,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            style: TextStyle(color: Palette.muted, fontSize: 8),
                          ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Palette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _friendlyDate(incident.createdAt),
                          style: const TextStyle(
                            color: Palette.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Palette.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _MiniPill(label: incident.sourceLabel, color: Palette.cyan),
                        if (incident.riskScore > 0)
                          _MiniPill(
                            label: _verdictLabel(incident),
                            color: color,
                          ),
                        _MiniPill(
                          label: _statusStyle(incident.status).$1,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 17),
                child: Icon(Icons.chevron_right_rounded, color: Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
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
    final (label, color) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassCard(
            borderColor: Palette.cyan.withOpacity(0.28),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, color: Palette.cyan, size: 44),
                SizedBox(height: 12),
                Text(
                  'Your Evidence Locker is empty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Suspicious and high-risk investigations, plus recovery cases you save, will appear here with their source, status and evidence preview.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.textSecondary, height: 1.45),
                ),
              ],
            ),
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
  var selectedStatus = incident.status;
  var hidePhoneNumbers = false;

  IncidentRecord currentDraft() {
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
      status: selectedStatus,
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
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.6,
            maxChildSize: 0.97,
            expand: false,
            builder: (_, scrollController) {
              final verdictColor = _verdictColor(incident);
              return Container(
                decoration: const BoxDecoration(
                  color: Palette.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(top: BorderSide(color: Palette.line)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Palette.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          button: true,
                          label: 'Close incident',
                          child: IconButton(
                            tooltip: 'Close incident',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: verdictColor.withOpacity(.38),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: verdictColor.withOpacity(.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: verdictColor.withOpacity(.32)),
                            ),
                            child: incident.riskScore == 0
                                ? const Text(
                                    'CASE',
                                    style: TextStyle(
                                      color: Palette.cyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${incident.riskScore}',
                                        style: TextStyle(
                                          color: verdictColor,
                                          fontSize: 25,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text(
                                        'RISK / 100',
                                        style: TextStyle(color: Palette.muted, fontSize: 7.5),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incident.category,
                                  style: const TextStyle(
                                    color: Palette.text,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 6,
                                  children: [
                                    _MiniPill(label: incident.sourceLabel, color: Palette.cyan),
                                    if (incident.riskScore > 0)
                                      _MiniPill(label: _verdictLabel(incident), color: verdictColor),
                                    _StatusPill(status: selectedStatus),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Saved ${_friendlyDate(incident.createdAt)}',
                                  style: const TextStyle(
                                    color: Palette.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Case ID: ${incident.id}',
                      style: const TextStyle(
                        color: Palette.muted,
                        fontSize: 10.5,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SheetLabel('EVIDENCE / CONTENT'),
                    const SizedBox(height: 7),
                    GlassCard(
                      child: SelectableText(
                        incident.content.isEmpty ? 'No text recorded.' : incident.content,
                        style: const TextStyle(
                          color: Palette.text,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (incident.reasons.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const _SheetLabel('WHY SCAMSHIELD FLAGGED IT'),
                      const SizedBox(height: 7),
                      for (final reason in incident.reasons.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
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
                                    color: Palette.textSecondary,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 13),
                    const _SheetLabel('INCIDENT DETAILS'),
                    const SizedBox(height: 7),
                    GlassCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount lost / requested (optional)',
                            ),
                          ),
                          TextField(
                            controller: referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Transaction / case reference (optional)',
                            ),
                          ),
                          TextField(
                            controller: notesController,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Notes / actions already taken',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SheetLabel('STATUS'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in IncidentStatus.values)
                          _StatusButton(
                            status: status,
                            selected: selectedStatus == status,
                            onPressed: () {
                              setSheetState(() => selectedStatus = status);
                              ref.read(incidentControllerProvider.notifier).updateIncident(
                                    id: incident.id,
                                    status: status,
                                  );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        await ref.read(incidentControllerProvider.notifier).updateIncident(
                              id: incident.id,
                              status: selectedStatus,
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
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('SAVE INCIDENT DETAILS'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Palette.cyan,
                        foregroundColor: Palette.bg,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Palette.line),
                      ),
                      child: SwitchListTile.adaptive(
                        value: hidePhoneNumbers,
                        onChanged: (value) => setSheetState(
                          () => hidePhoneNumbers = value,
                        ),
                        title: const Text(
                          'Hide phone numbers in PDF',
                          style: TextStyle(
                            color: Palette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Creates a share-safe copy while keeping the integrity fingerprint for the original evidence.',
                          style: TextStyle(color: Palette.textSecondary, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final fileName = await const IncidentPdfExportService().export(
                            currentDraft(),
                            hidePhoneNumbers: hidePhoneNumbers,
                          );
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
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('DOWNLOAD PDF REPORT'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: Palette.cyan,
                        side: const BorderSide(color: Palette.cyan),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () async {
                        final report = const IncidentReportFormatter().format(currentDraft());
                        await Clipboard.setData(ClipboardData(text: report));
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('Text report copied.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.content_copy_rounded),
                      label: const Text('Copy text report'),
                    ),
                    const Divider(height: 28),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: sheetContext,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete this incident?'),
                            content: const Text(
                              'This permanently removes the saved incident from this device. Export anything you need first.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Palette.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete permanently'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        await ref.read(incidentControllerProvider.notifier).deleteIncident(incident.id);
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
    },
  ).whenComplete(() {
    notesController.dispose();
    amountController.dispose();
    referenceController.dispose();
  });
}

class _StatusButton extends StatelessWidget {
  final IncidentStatus status;
  final bool selected;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.status,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle(status);
    return selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.check_rounded, size: 17),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Palette.bg,
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(.55)),
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

(String, Color) _statusStyle(IncidentStatus status) {
  return switch (status) {
    IncidentStatus.reviewing => ('REVIEWING', Palette.cyan),
    IncidentStatus.actionRequired => ('ACTION REQUIRED', Palette.amber),
    IncidentStatus.reported => ('REPORTED', Palette.violet),
    IncidentStatus.resolved => ('RESOLVED', Palette.green),
  };
}

Color _verdictColor(IncidentRecord incident) {
  if (incident.riskScore == 0) return Palette.cyan;
  switch (incident.verdict.name) {
    case 'highRisk':
      return Palette.red;
    case 'suspicious':
      return Palette.amber;
    default:
      return Palette.green;
  }
}

String _verdictLabel(IncidentRecord incident) {
  if (incident.riskScore == 0) return 'CASE';
  switch (incident.verdict.name) {
    case 'highRisk':
      return 'HIGH RISK';
    case 'suspicious':
      return 'SUSPICIOUS';
    default:
      return 'LOW RISK';
  }
}

String _preview(String content) {
  return content.replaceAll(RegExp(r'\s+'), ' ').trim();
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
  return '${local.day} ${months[local.month - 1]} ${local.year}, ${clock(local)}';
}
