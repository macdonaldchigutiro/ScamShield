import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/incident_record.dart';

/// Creates a stable SHA-256 fingerprint for the saved evidence content.
///
/// The fingerprint is based on immutable evidence fields: the incident ID,
/// original saved timestamp and original content/sender/source. It is intended
/// as an integrity aid for exported reports, not as a legal certification.
class IncidentIntegrityService {
  const IncidentIntegrityService();

  String sha256Hex(IncidentRecord incident) {
    final payload = [
      'id=${incident.id}',
      'createdAt=${incident.createdAt.toUtc().toIso8601String()}',
      'source=${incident.sourceLabel}',
      'sender=${incident.sender}',
      'content=${incident.content}',
    ].join('\n');

    return sha256.convert(utf8.encode(payload)).toString();
  }
}
