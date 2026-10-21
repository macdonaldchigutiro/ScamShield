import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/incident_record.dart';

/// Produces a stable SHA-256 fingerprint for the original saved evidence.
///
/// Editable recovery metadata such as notes, amount, status and transaction
/// references are deliberately excluded. That means the fingerprint continues
/// to identify the original evidence even when the user later adds case notes.
String evidenceFingerprint(IncidentRecord incident) {
  final canonical = [
    incident.id,
    incident.createdAt.toUtc().toIso8601String(),
    incident.sourceLabel,
    incident.sender,
    incident.content,
  ].join('\n');

  return sha256.convert(utf8.encode(canonical)).toString();
}
