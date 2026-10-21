import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scam_check/domain/entities/scam_investigation.dart';
import '../../data/repositories/local_incident_repository.dart';
import '../../domain/entities/incident_record.dart';
import '../../domain/repositories/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return const LocalIncidentRepository();
});

final incidentControllerProvider =
    StateNotifierProvider<IncidentController, IncidentState>((ref) {
  return IncidentController(ref.watch(incidentRepositoryProvider));
});

class IncidentState {
  final bool isLoading;
  final List<IncidentRecord> incidents;
  final String? errorMessage;

  const IncidentState({
    this.isLoading = false,
    this.incidents = const [],
    this.errorMessage,
  });
}

/// Coordinates local Evidence Locker operations.
///
/// The controller owns persistence and incident lifecycle decisions. Screens do
/// not write SharedPreferences directly, which keeps storage replaceable later.
class IncidentController extends StateNotifier<IncidentState> {
  final IncidentRepository _repository;

  IncidentController(this._repository)
      : super(const IncidentState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final incidents = await _repository.loadIncidents();
      state = IncidentState(incidents: incidents);
    } catch (error) {
      state = IncidentState(errorMessage: error.toString());
    }
  }

  /// Saves a concerning investigation as structured evidence.
  Future<IncidentRecord> saveInvestigation({
    required ScamInvestigation investigation,
    required String content,
    required String sourceLabel,
    String sender = '',
  }) async {
    final now = DateTime.now();
    final incident = IncidentRecord(
      id: _buildIncidentId(now),
      createdAt: now,
      updatedAt: now,
      sourceLabel: sourceLabel,
      content: content.trim(),
      sender: sender.trim(),
      riskScore: investigation.riskScore,
      verdict: investigation.verdict,
      category: investigation.category,
      reasons: investigation.reasons,
      recommendedActions: investigation.recommendedActions,
      status: investigation.verdict == InvestigationVerdict.highRisk
          ? IncidentStatus.actionRequired
          : IncidentStatus.reviewing,
      notes: '',
    );

    final updated = [incident, ...state.incidents];
    await _persist(updated);
    return incident;
  }

  Future<void> updateIncident({
    required String id,
    IncidentStatus? status,
    String? notes,
    double? amount,
    String? transactionReference,
  }) async {
    final updated = state.incidents.map((incident) {
      if (incident.id != id) return incident;
      return incident.copyWith(
        updatedAt: DateTime.now(),
        status: status,
        notes: notes,
        amount: amount,
        transactionReference: transactionReference,
      );
    }).toList();
    await _persist(updated);
  }

  Future<void> deleteIncident(String id) async {
    final updated = state.incidents.where((item) => item.id != id).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<IncidentRecord> incidents) async {
    try {
      await _repository.saveIncidents(incidents);
      state = IncidentState(incidents: incidents);
    } catch (error) {
      state = IncidentState(
        incidents: state.incidents,
        errorMessage: error.toString(),
      );
    }
  }

  String _buildIncidentId(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'SS-${time.year}${two(time.month)}${two(time.day)}-'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
