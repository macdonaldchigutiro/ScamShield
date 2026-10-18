import '../../../../analyzer.dart' as legacy;
import '../../domain/entities/scam_investigation.dart';
import '../../domain/repositories/scam_investigation_repository.dart';

/// Adapter around ScamShield's existing transparent rules engine.
///
/// Keeping the old analyzer behind this repository means the UI and domain
/// layers no longer depend on legacy classes. We can later combine this with
/// machine learning, community reports or threat-intelligence APIs without
/// changing the investigator screen.
class RuleBasedScamInvestigationRepository
    implements ScamInvestigationRepository {
  const RuleBasedScamInvestigationRepository();

  @override
  Future<ScamInvestigation> investigate({
    required String content,
    required InvestigationInputType inputType,
    required InvestigationChannel channel,
    String sender = '',
  }) async {
    final analysis = legacy.analyze(
      content,
      sender: sender,
      channel: _toLegacyChannel(channel),
    );

    return ScamInvestigation(
      riskScore: analysis.score,
      verdict: _toDomainVerdict(analysis.verdict),
      category: analysis.type,
      channel: channel,
      reasons: [
        for (final reason in analysis.reasons)
          InvestigationReason(
            title: reason.title,
            explanation: reason.detail,
            severity: reason.weight,
          ),
      ],
      links: [
        for (final link in analysis.links)
          InvestigationLink(
            url: link.url,
            domain: link.domain,
            warnings: link.flags,
            risk: link.risk,
          ),
      ],
      highlights: [
        for (final hit in analysis.hits)
          InvestigationHighlight(
            start: hit.start,
            end: hit.end,
            severity: hit.weight,
          ),
      ],
      recommendedActions: analysis.advice,
    );
  }

  legacy.Channel _toLegacyChannel(InvestigationChannel channel) {
    switch (channel) {
      case InvestigationChannel.sms:
        return legacy.Channel.sms;
      case InvestigationChannel.whatsapp:
        return legacy.Channel.whatsapp;
      case InvestigationChannel.facebook:
        return legacy.Channel.facebook;
      case InvestigationChannel.email:
        return legacy.Channel.email;
      case InvestigationChannel.phoneCall:
        return legacy.Channel.call;
      case InvestigationChannel.other:
        return legacy.Channel.other;
    }
  }

  InvestigationVerdict _toDomainVerdict(legacy.Verdict verdict) {
    switch (verdict) {
      case legacy.Verdict.safe:
        return InvestigationVerdict.lowRisk;
      case legacy.Verdict.suspicious:
        return InvestigationVerdict.suspicious;
      case legacy.Verdict.scam:
        return InvestigationVerdict.highRisk;
    }
  }
}
