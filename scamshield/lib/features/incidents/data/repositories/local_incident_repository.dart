import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/incident_record.dart';
import '../../domain/repositories/incident_repository.dart';

/// Persists Evidence Locker metadata on the current device/browser.
///
/// Only structured incident data is stored here. Screenshot bytes are excluded
/// deliberately because browser preferences are not an appropriate encrypted
/// attachment store.
class LocalIncidentRepository implements IncidentRepository {
  static const _storageKey = 'scamshield_incidents_v1';

  const LocalIncidentRepository();

  @override
  Future<List<IncidentRecord>> loadIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => IncidentRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      // Corrupt local storage should not stop ScamShield opening. Returning an
      // empty locker is safer than crashing the whole protection experience.
      return const [];
    }
  }

  @override
  Future<void> saveIncidents(List<IncidentRecord> incidents) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      incidents.map((incident) => incident.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
