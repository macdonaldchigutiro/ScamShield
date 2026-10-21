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

    // Start with the transparent legacy-rule score, then add context-aware
    // boosts when several warning signs appear together. A request for money
    // from a "new number", combined with urgency or secrecy, is materially
    // more dangerous than any one phrase on its own.
    final normalized = content
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'");

    final hasFamilyImpersonation = analysis.reasons.any(
      (reason) => reason.type == 'Family impersonation',
    );
    final hasUrgency = analysis.reasons.any(
      (reason) => reason.title.toLowerCase().contains('urgency'),
    );

    final hasMoneyRequest = RegExp(
      r"\b(send|transfer|pay|deposit|lend|loan)\b[\s\S]{0,35}(£|\$|usd|gbp|eur|zig|zwl|\d{2,})",
      caseSensitive: false,
    ).hasMatch(normalized);

    final hasSecrecy = RegExp(
      r"(don't tell|do not tell|tell no one|keep (this|it) (a )?(secret|private)|between us)",
      caseSensitive: false,
    ).hasMatch(normalized);

    var adjustedScore = analysis.score;
    if (hasMoneyRequest) adjustedScore += 15;
    if (hasSecrecy) adjustedScore += 10;
    if (hasFamilyImpersonation && hasMoneyRequest) adjustedScore += 15;
    if (hasUrgency && hasMoneyRequest) adjustedScore += 8;
    adjustedScore = adjustedScore.clamp(0, 100);

    final reasons = <InvestigationReason>[
      for (final reason in analysis.reasons)
        InvestigationReason(
          title: reason.title,
          explanation: reason.detail,
          severity: reason.weight,
        ),
    ];

    // Add human-readable reasons for contextual signals that the older engine
    // may miss, especially pound-denominated money requests and curly apostrophes.
    if (hasMoneyRequest &&
        !reasons.any((reason) => reason.title == 'Requests money')) {
      reasons.add(const InvestigationReason(
        title: 'Requests money',
        explanation:
            'A request to send money is a strong warning sign when the sender or situation cannot be independently verified.',
        severity: 0.35,
      ));
    }

    if (hasSecrecy &&
        !reasons.any((reason) => reason.title == 'Asks you to keep it secret')) {
      reasons.add(const InvestigationReason(
        title: 'Asks you to keep it secret',
        explanation:
            'Scammers often isolate people so a friend or relative cannot challenge the story before money is sent.',
        severity: 0.30,
      ));
    }

    if (hasFamilyImpersonation && hasMoneyRequest) {
      reasons.add(const InvestigationReason(
        title: 'High-risk impersonation combination',
        explanation:
            'A new-number or family-impersonation story combined with a money request is a well-known fraud pattern.',
        severity: 0.55,
      ));
    }

    reasons.sort((a, b) => b.severity.compareTo(a.severity));

    final verdict = adjustedScore >= 60
        ? InvestigationVerdict.highRisk
        : adjustedScore >= 25
            ? InvestigationVerdict.suspicious
            : InvestigationVerdict.lowRisk;

    final category = hasFamilyImpersonation && hasMoneyRequest
        ? 'Family impersonation'
        : analysis.type;

    return ScamInvestigation(
      riskScore: adjustedScore,
      verdict: verdict,
      category: category,
      channel: channel,
      reasons: reasons,
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
}
