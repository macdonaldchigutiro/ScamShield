import '../../domain/entities/scam_investigation.dart';
import '../../domain/repositories/scam_investigation_repository.dart';
import 'cloud_scam_investigation_repository.dart';

/// Runs the fast local rules first and escalates only ambiguous checks.
///
/// Cloud analysis is optional and consent-controlled. If the cloud request
/// fails, ScamShield keeps the local result rather than blocking the user.
class HybridScamInvestigationRepository
    implements ScamInvestigationRepository {
  final ScamInvestigationRepository local;
  final CloudScamInvestigationRepository cloud;
  final bool cloudConsentEnabled;

  const HybridScamInvestigationRepository({
    required this.local,
    required this.cloud,
    required this.cloudConsentEnabled,
  });

  @override
  Future<ScamInvestigation> investigate({
    required String content,
    required InvestigationInputType inputType,
    required InvestigationChannel channel,
    String sender = '',
  }) async {
    final localResult = await local.investigate(
      content: content,
      inputType: inputType,
      channel: channel,
      sender: sender,
    );

    final canEscalate = cloudConsentEnabled &&
        cloud.isConfigured &&
        inputType != InvestigationInputType.phoneNumber &&
        localResult.verdict == InvestigationVerdict.suspicious;

    if (!canEscalate) return localResult;

    try {
      return await cloud.investigate(
        content: content,
        inputType: inputType,
        channel: channel,
        sender: sender,
      );
    } catch (_) {
      return localResult;
    }
  }
}
