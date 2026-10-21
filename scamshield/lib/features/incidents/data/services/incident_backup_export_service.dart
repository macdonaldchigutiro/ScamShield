import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/incident_record.dart';
import '../../domain/services/evidence_integrity.dart';
import 'platform_download.dart';

/// Exports the complete Evidence Locker as a portable JSON backup.
///
/// This is intentionally a transparent format rather than a proprietary file so
/// users are not locked in. It contains sensitive evidence, so the UI warns the
/// user before download.
class IncidentBackupExportService {
  const IncidentBackupExportService();

  Future<String> exportAll(List<IncidentRecord> incidents) async {
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'format': 'ScamShield Evidence Locker Backup',
      'version': 1,
      'exportedAt': now.toIso8601String(),
      'incidentCount': incidents.length,
      'incidents': [
        for (final incident in incidents)
          {
            ...incident.toJson(),
            'evidenceSha256': evidenceFingerprint(incident),
          },
      ],
    };

    final pretty = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = Uint8List.fromList(utf8.encode(pretty));
    final fileName =
        'ScamShield_Evidence_Backup_${_dateStamp(now)}.json';

    await downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/json',
    );
    return fileName;
  }

  String _dateStamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
