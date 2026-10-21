import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/scam_investigation.dart';
import '../../domain/repositories/scam_investigation_repository.dart';

/// Calls ScamShield's optional backend analysis endpoint.
///
/// The endpoint is supplied at build/run time with:
/// --dart-define=SCAMSHIELD_ANALYSIS_URL=https://example.com/analyse
///
/// No API secret is stored in the app. Production authentication, rate limits
/// and model credentials must remain server-side.
class CloudScamInvestigationRepository
    implements ScamInvestigationRepository {
  final String endpoint;
  final http.Client _client;

  CloudScamInvestigationRepository({
    required this.endpoint,
    http.Client? client,
  }) : _client = client ?? http.Client();

  bool get isConfigured => endpoint.trim().isNotEmpty;

  @override
  Future<ScamInvestigation> investigate({
    required String content,
    required InvestigationInputType inputType,
    required InvestigationChannel channel,
    String sender = '',
  }) async {
    if (!isConfigured) {
      throw StateError('Cloud analysis endpoint is not configured.');
    }

    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'content': content,
            'inputType': inputType.name,
            'channel': channel.name,
            'sender': sender,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Cloud analysis failed (${response.statusCode}).');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final score = ((json['riskScore'] as num?)?.toInt() ?? 0).clamp(0, 100);
    final verdict = score >= 60
        ? InvestigationVerdict.highRisk
        : score >= 25
            ? InvestigationVerdict.suspicious
            : InvestigationVerdict.lowRisk;

    final reasons = <InvestigationReason>[
      const InvestigationReason(
        title: 'Optional cloud analysis used',
        explanation:
            'You enabled cloud analysis, so this ambiguous check was also reviewed by ScamShield\'s remote analysis service.',
        severity: 0.05,
      ),
      for (final item in (json['reasons'] as List? ?? const []))
        InvestigationReason(
          title: ((item as Map)['title'] as String?) ?? 'Cloud warning',
          explanation: (item['explanation'] as String?) ?? '',
          severity: (item['severity'] as num?)?.toDouble() ?? 0.3,
        ),
    ];

    return ScamInvestigation(
      riskScore: score,
      verdict: verdict,
      category: (json['category'] as String?) ?? 'Cloud analysis',
      channel: channel,
      reasons: reasons,
      links: const [],
      phoneNumbers: const [],
      highlights: const [],
      recommendedActions: List<String>.from(
        (json['recommendedActions'] as List?) ?? const <String>[],
      ),
    );
  }
}
