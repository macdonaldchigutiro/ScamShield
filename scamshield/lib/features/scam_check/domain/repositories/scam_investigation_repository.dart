import '../entities/scam_investigation.dart';

/// Contract for anything capable of investigating suspicious content.
///
/// The presentation layer depends on this interface rather than on a specific
/// rules engine, API or machine-learning model. That keeps future upgrades
/// isolated to the data layer.
abstract class ScamInvestigationRepository {
  Future<ScamInvestigation> investigate({
    required String content,
    required InvestigationInputType inputType,
    required InvestigationChannel channel,
    String sender = '',
  });
}
