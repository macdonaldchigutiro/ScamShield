import '../../../../analyzer.dart' as legacy;
import '../../domain/entities/scam_investigation.dart';
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

    var adjustedScore = analysis.score;
    if (hasMoneyRequest) adjustedScore += 15;
    if (hasSecrecy) adjustedScore += 10;
    if (hasFamilyImpersonation && hasMoneyRequest) adjustedScore += 15;
    if (hasUrgency && hasMoneyRequest) adjustedScore += 8;

    // Number-only checks must not manufacture a scam score. Formatting can
    // reveal a premium/service range, but a normal-looking mobile number can
    // still be spoofed or abused. We therefore expose local number intelligence
    // while keeping the overall verdict cautious until reputation data exists.
    if (inputType == InvestigationInputType.phoneNumber && phones.isNotEmpty) {
      final phoneRisk = phones
          .map((phone) => (phone.risk * 100).round())
          .fold<int>(0, (highest, value) => value > highest ? value : highest);
      if (phoneRisk > adjustedScore) adjustedScore = phoneRisk;
    }

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

    if (phones.isNotEmpty && inputType != InvestigationInputType.phoneNumber) {
      reasons.add(InvestigationReason(
        title: phones.length == 1
            ? 'Phone number found in the content'
            : '${phones.length} phone numbers found in the content',
        explanation:
            'ScamShield extracted the number${phones.length == 1 ? '' : 's'} so you can inspect the sender/contact details separately from the message wording.',
        severity: adjustedScore >= 60 ? 0.25 : 0.08,
      ));
    }

    if (inputType == InvestigationInputType.phoneNumber) {
      reasons.add(const InvestigationReason(
        title: 'Number checked locally',
        explanation:
            'ScamShield has normalised the number and checked its format and known high-cost/service ranges. Live community or carrier reputation is not connected yet, so a normal-looking number must not be treated as verified.',
        severity: 0.08,
      ));
    }

    reasons.sort((a, b) => b.severity.compareTo(a.severity));

    final verdict = adjustedScore >= 60
        ? InvestigationVerdict.highRisk
        : adjustedScore >= 25
            ? InvestigationVerdict.suspicious
            : InvestigationVerdict.lowRisk;

    final category = inputType == InvestigationInputType.phoneNumber
        ? 'Phone number intelligence'
        : hasFamilyImpersonation && hasMoneyRequest
            ? 'Family impersonation'
            : analysis.type;

    final actions = inputType == InvestigationInputType.phoneNumber
        ? const [
            'Do not trust a caller only because the number looks familiar; caller ID can be spoofed.',
            'If the caller claims to be a bank, company or relative, end the call and contact them using a number you find independently.',
            'If the number appeared in a suspicious message, scan the full message or screenshot too so ScamShield can assess the context.',
          ]
        : analysis.advice;

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
