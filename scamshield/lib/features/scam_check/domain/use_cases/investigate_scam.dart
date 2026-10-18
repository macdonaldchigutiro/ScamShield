import '../entities/scam_investigation.dart';
import '../repositories/scam_investigation_repository.dart';

/// Application use case for a single ScamShield investigation.
///
/// Validation lives here rather than in the UI so every future entry point
/// (paste, Share to ScamShield, screenshot extraction, deep link) behaves the
/// same way.
class InvestigateScam {
  final ScamInvestigationRepository repository;

  const InvestigateScam(this.repository);

  Future<ScamInvestigation> call({
    required String content,
    required InvestigationInputType inputType,
    required InvestigationChannel channel,
    String sender = '',
  }) {
    final cleaned = content.trim();
    if (cleaned.isEmpty) {
      throw const ScamInvestigationException(
        'Add something suspicious for ScamShield to investigate.',
      );
    }

    return repository.investigate(
      content: cleaned,
      inputType: inputType,
      channel: channel,
      sender: sender.trim(),
    );
  }
}

class ScamInvestigationException implements Exception {
  final String message;

  const ScamInvestigationException(this.message);

  @override
  String toString() => message;
}
