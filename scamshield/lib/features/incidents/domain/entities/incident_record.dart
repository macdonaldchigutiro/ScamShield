import '../../../scam_check/domain/entities/scam_investigation.dart';
export '../../../scam_check/domain/entities/scam_investigation.dart'
    show InvestigationVerdict;

/// Lifecycle state for an incident in the Evidence Locker.
enum IncidentStatus { reviewing, actionRequired, reported, resolved }

/// A structured fraud incident saved from a ScamShield investigation.
///
/// This model intentionally stores the investigation evidence and recovery
/// status, but not raw screenshot bytes. Large/sensitive media attachments will
/// move to encrypted file storage in a later phase.
class IncidentRecord {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sourceLabel;
  final String content;
  final String sender;
  final int riskScore;
  final InvestigationVerdict verdict;
  final String category;
  final List<InvestigationReason> reasons;
  final List<String> recommendedActions;
  final IncidentStatus status;
  final String notes;
  final double? amount;
  final String? transactionReference;

  const IncidentRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceLabel,
    required this.content,
    required this.sender,
    required this.riskScore,
    required this.verdict,
    required this.category,
    required this.reasons,
    required this.recommendedActions,
    required this.status,
    required this.notes,
    this.amount,
    this.transactionReference,
  });

  IncidentRecord copyWith({
    DateTime? updatedAt,
    IncidentStatus? status,
    String? notes,
    double? amount,
    String? transactionReference,
  }) {
    return IncidentRecord(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceLabel: sourceLabel,
      content: content,
      sender: sender,
      riskScore: riskScore,
      verdict: verdict,
      category: category,
      reasons: reasons,
      recommendedActions: recommendedActions,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      transactionReference: transactionReference ?? this.transactionReference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sourceLabel': sourceLabel,
      'content': content,
      'sender': sender,
      'riskScore': riskScore,
      'verdict': verdict.name,
      'category': category,
      'reasons': reasons
          .map((reason) => {
                'title': reason.title,
                'explanation': reason.explanation,
                'severity': reason.severity,
              })
          .toList(),
      'recommendedActions': recommendedActions,
      'status': status.name,
      'notes': notes,
      'amount': amount,
      'transactionReference': transactionReference,
    };
  }

  factory IncidentRecord.fromJson(Map<String, dynamic> json) {
    InvestigationVerdict parseVerdict(String? value) {
      return InvestigationVerdict.values.firstWhere(
        (item) => item.name == value,
        orElse: () => InvestigationVerdict.suspicious,
      );
    }

    IncidentStatus parseStatus(String? value) {
      return IncidentStatus.values.firstWhere(
        (item) => item.name == value,
        orElse: () => IncidentStatus.reviewing,
      );
    }

    return IncidentRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sourceLabel: (json['sourceLabel'] as String?) ?? 'Investigation',
      content: (json['content'] as String?) ?? '',
      sender: (json['sender'] as String?) ?? '',
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 0,
      verdict: parseVerdict(json['verdict'] as String?),
      category: (json['category'] as String?) ?? 'Unknown',
      reasons: ((json['reasons'] as List?) ?? const [])
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return InvestigationReason(
              title: (map['title'] as String?) ?? '',
              explanation: (map['explanation'] as String?) ?? '',
              severity: (map['severity'] as num?)?.toDouble() ?? 0,
            );
          })
          .toList(),
      recommendedActions:
          List<String>.from((json['recommendedActions'] as List?) ?? const []),
      status: parseStatus(json['status'] as String?),
      notes: (json['notes'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      transactionReference: json['transactionReference'] as String?,
    );
  }
}
