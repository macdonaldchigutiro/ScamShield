import '../entities/incident_record.dart';

/// Storage contract for ScamShield evidence incidents.
///
/// Presentation code depends on this abstraction rather than local storage.
/// A future encrypted database or cloud-sync implementation can replace the
/// current repository without rewriting screens or controllers.
abstract class IncidentRepository {
  Future<List<IncidentRecord>> loadIncidents();

  Future<void> saveIncidents(List<IncidentRecord> incidents);
}
