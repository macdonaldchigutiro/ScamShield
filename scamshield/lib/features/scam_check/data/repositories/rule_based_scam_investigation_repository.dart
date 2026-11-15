import '../../../../analyzer.dart' as legacy;
import '../../domain/entities/scam_investigation.dart';
import 'contextual_scam_signals.dart';
import '../../domain/repositories/scam_investigation_repository.dart';
import '../../domain/services/phone_intelligence_service.dart';

/// Adapter around ScamShield's existing transparent rules engine.
///
/// Keeping the old analyzer behind this repository means the UI and domain
/// layers no longer depend on legacy classes. We can later combine this with
/// machine learning, community reports or threat-intelligence APIs without
/// changing the investigator screen.
class RuleBasedScamInvestigationRepository
    implements ScamInvestigationRepository {
  final PhoneIntelligenceService _phoneIntelligence;

  const RuleBasedScamInvestigationRepository({
    PhoneIntelligenceService phoneIntelligence =
        const PhoneIntelligenceService(),
  }) : _phoneIntelligence = phoneIntelligence;

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

    final phones = _phoneIntelligence.inspect(
      content,
      directNumberCheck: inputType == InvestigationInputType.phoneNumber,
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

    final contextual = inputType == InvestigationInputType.phoneNumber
        ? const <ContextualScamSignal>[]
        : contextualScamSignals(content);

    var adjustedScore = analysis.score;
    if (hasMoneyRequest) adjustedScore += 15;
    if (hasSecrecy) adjustedScore += 10;
    if (hasFamilyImpersonation && hasMoneyRequest) adjustedScore += 15;
    if (hasUrgency && hasMoneyRequest) adjustedScore += 8;
    for (final signal in contextual) {
      adjustedScore += signal.scoreBoost;
    }

    // A number-only lookup is neutral unless ScamShield has actual evidence.
    // A lack of reputation data is NOT a warning and must never create risk.
    if (inputType == InvestigationInputType.phoneNumber) {
      final phoneRisk = phones
          .map((phone) => (phone.risk * 100).round())
          .fold<int>(0, (highest, value) => value > highest ? value : highest);

      // No sample reports are promoted to real consumer evidence.
      // Only concrete on-device number information affects this score.
      adjustedScore = phoneRisk;
    }

    adjustedScore = adjustedScore.clamp(0, 100);

    final reasons = <InvestigationReason>[
      for (final signal in contextual) signal.toReason(),
    ];

    // Bare phone-number checks should not inherit unrelated wording rules from
    // the legacy text analyzer. Message/screenshot checks still use them all.
    if (inputType != InvestigationInputType.phoneNumber) {
      reasons.addAll([
        for (final reason in analysis.reasons)
          InvestigationReason(
            title: reason.title,
            explanation: reason.detail,
            severity: reason.weight,
          ),
      ]);
    }

    if (inputType != InvestigationInputType.phoneNumber &&
        hasMoneyRequest &&
        !reasons.any((reason) => reason.title == 'Requests money')) {
      reasons.add(const InvestigationReason(
        title: 'Requests money',
        explanation:
            'A request to send money is a strong warning sign when the sender or situation cannot be independently verified.',
        severity: 0.35,
      ));
    }

    if (inputType != InvestigationInputType.phoneNumber &&
        hasSecrecy &&
        !reasons.any((reason) => reason.title == 'Asks you to keep it secret')) {
      reasons.add(const InvestigationReason(
        title: 'Asks you to keep it secret',
        explanation:
            'Scammers often isolate people so a friend or relative cannot challenge the story before money is sent.',
        severity: 0.30,
      ));
    }

    if (inputType != InvestigationInputType.phoneNumber &&
        hasFamilyImpersonation &&
        hasMoneyRequest) {
      reasons.add(const InvestigationReason(
        title: 'High-risk impersonation combination',
        explanation:
            'A new-number or family-impersonation story combined with a money request is a well-known fraud pattern.',
        severity: 0.55,
      ));
    }

    if (phones.isNotEmpty && inputType != InvestigationInputType.phoneNumber) {
      reasons.add(InvestigationReason(
        title: phones.length == 1
            ? 'Phone number found in the content'
            : '${phones.length} phone numbers found in the content',
        explanation:
            'ScamShield extracted the number${phones.length == 1 ? '' : 's'} for review. No live reputation lookup is available in this local check.',
        severity: adjustedScore >= 60 ? 0.25 : 0.08,
      ));
    }

    if (inputType == InvestigationInputType.phoneNumber) {
      final hasConcreteWarning = phones.any((phone) => phone.risk > 0);
      reasons.add(InvestigationReason(
        title: hasConcreteWarning
            ? 'Local number warning found'
            : 'No negative evidence found locally',
        explanation: hasConcreteWarning
            ? 'ScamShield found a local formatting or number-range concern. This is not a verified scam report.'
            : 'No local warning was found. ScamShield has not verified this number as trustworthy or checked a live reputation database.',
        severity: hasConcreteWarning ? 0.18 : 0.0,
      ));
    }

    reasons.sort((a, b) => b.severity.compareTo(a.severity));

    final verdict = adjustedScore >= 60
        ? InvestigationVerdict.highRisk
        : adjustedScore >= 25
            ? InvestigationVerdict.suspicious
            : InvestigationVerdict.lowRisk;

    // A legacy "no signs" category must never contradict a suspicious
    // or high-risk verdict derived from additional transparent rules.
    final legacyNoSigns = analysis.type.toLowerCase().contains('no scam signs') ||
        analysis.type.toLowerCase().contains('no suspicious');
    final category = inputType == InvestigationInputType.phoneNumber
        ? (adjustedScore == 0
            ? 'No negative evidence found'
            : 'Phone number intelligence')
        : contextual.isNotEmpty
            ? contextual.first.category
            : hasFamilyImpersonation && hasMoneyRequest
                ? 'Family impersonation'
                : verdict != InvestigationVerdict.lowRisk && legacyNoSigns
                    ? (hasMoneyRequest
                        ? 'Unverified money request'
                        : 'Suspicious message')
                    : analysis.type;

    final actions = inputType == InvestigationInputType.phoneNumber
        ? const [
            'Do not trust a caller only because the number looks familiar; caller ID can be spoofed.',
            'If the caller claims to be a bank, company or relative, end the call and contact them using a number you find independently.',
            'If the number appeared in a suspicious message, scan the full message or screenshot too so ScamShield can assess the context.',
          ]
        : [
            for (final signal in contextual) signal.action,
            if (verdict != InvestigationVerdict.lowRisk &&
                analysis.verdict == legacy.Verdict.safe) ...const [
              'Do not send money, share codes or use links until you independently verify the sender.',
              'Contact the person or organisation through a trusted existing number or official app.',
            ] else
              ...analysis.advice,
          ];

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
      phoneNumbers: phones,
      highlights: [
        for (final hit in analysis.hits)
          InvestigationHighlight(
            start: hit.start,
            end: hit.end,
            severity: hit.weight,
          ),
      ],
      recommendedActions: actions,
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

