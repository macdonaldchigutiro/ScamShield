import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield/features/incidents/domain/entities/incident_record.dart';
import 'package:scamshield/features/incidents/domain/services/evidence_integrity.dart';

void main() {
  final savedAt = DateTime.utc(2026, 11, 15, 10, 30);
  IncidentRecord incident({String content = 'Suspicious message'}) =>
      IncidentRecord(
        id: 'case-001',
        createdAt: savedAt,
        updatedAt: savedAt,
        sourceLabel: 'Message',
        content: content,
        sender: 'Unknown',
        riskScore: 65,
        verdict: InvestigationVerdict.highRisk,
        category: 'Impersonation',
        reasons: const [],
        recommendedActions: const ['Verify independently'],
        status: IncidentStatus.reviewing,
        notes: '',
      );

  test('saved incidents round-trip through JSON without losing evidence', () {
    final original = incident();
    final restored = IncidentRecord.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.content, original.content);
    expect(restored.riskScore, original.riskScore);
    expect(restored.verdict, original.verdict);
    expect(restored.status, original.status);
    expect(restored.createdAt, original.createdAt);
  });

  test('fingerprint is unaffected by editable recovery metadata', () {
    final original = incident();
    final edited = original.copyWith(
      notes: 'Reported to bank',
      status: IncidentStatus.reported,
      transactionReference: 'REF-123',
      amount: 450,
      updatedAt: savedAt.add(const Duration(days: 1)),
    );

    expect(evidenceFingerprint(edited), evidenceFingerprint(original));
    expect(evidenceFingerprint(incident(content: 'Different message')),
        isNot(evidenceFingerprint(original)));
    expect(evidenceFingerprint(original), hasLength(64));
  });
}
