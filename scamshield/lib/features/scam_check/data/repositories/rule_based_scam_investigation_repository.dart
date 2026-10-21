import '../../../../analyzer.dart' as legacy;
import '../../../../sim.dart';
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
  final ThreatSim? _prototypeThreatData;

  const RuleBasedScamInvestigationRepository({
    PhoneIntelligenceService phoneIntelligence =
        const PhoneIntelligenceService(),
    ThreatSim? prototypeThreatData,
  })  : _phoneIntelligence = phoneIntelligence,
        _prototypeThreatData = prototypeThreatData;

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

    var phones = _phoneIntelligence.inspect(
      content,
      directNumberCheck: inputType == InvestigationInputType.phoneNumber,
    );

    // During the prototype, Partner View already maintains a simulated list of
    // repeatedly flagged scam numbers. Reuse that exact data here so the app is
    // internally consistent. The source remains explicitly labelled SAMPLE DATA
    // and must be replaced by a real reputation repository before production.
    phones = [for (final phone in phones) _enrichFromPrototypeReputation(phone)];

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

    final highestReputationReports = phones
        .map((phone) => phone.reportCount)
        .fold<int>(0, (highest, value) => value > highest ? value : highest);

    // Repeated reputation reports are concrete evidence within the prototype.
    // Keep the thresholds simple and transparent so we can later replace them
    // with calibrated production scoring.
    if (highestReputationReports >= 8) {
      adjustedScore = adjustedScore < 85 ? 85 : adjustedScore;
    } else if (highestReputationReports >= 3) {
      adjustedScore = adjustedScore < 65 ? 65 : adjustedScore;
    } else if (highestReputationReports > 0) {
      adjustedScore = adjustedScore < 40 ? 40 : adjustedScore;
    }

    // A number-only lookup is neutral unless ScamShield has actual evidence.
    // A lack of reputation data is NOT a warning and must never create risk.
    if (inputType == InvestigationInputType.phoneNumber) {
      final phoneRisk = phones
          .map((phone) => (phone.risk * 100).round())
          .fold<int>(0, (highest, value) => value > highest ? value : highest);

      // Ignore text-rule noise caused by a bare phone number. Only concrete
      // number intelligence or actual reputation reports influence the score.
      if (highestReputationReports >= 8) {
        adjustedScore = 85;
      } else if (highestReputationReports >= 3) {
        adjustedScore = 65;
      } else if (highestReputationReports > 0) {
        adjustedScore = 40;
      } else {
        adjustedScore = phoneRisk;
      }
    }

    adjustedScore = adjustedScore.clamp(0, 100);

    final reasons = <InvestigationReason>[];

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
            'ScamShield extracted the number${phones.length == 1 ? '' : 's'} so its reputation can be assessed alongside the message wording.',
        severity: adjustedScore >= 60 ? 0.25 : 0.08,
      ));
    }

    for (final phone in phones.where((phone) => phone.reportCount > 0)) {
      reasons.add(InvestigationReason(
        title: 'Number has ${phone.reportCount} prototype scam reports',
        explanation:
            '${phone.normalized} appears in Partner View sample data as ${phone.reportedCategory ?? 'a reported scam number'}. This is simulated prototype reputation, not a live public database.',
        severity: phone.reportCount >= 8 ? 0.75 : 0.55,
      ));
    }

    if (inputType == InvestigationInputType.phoneNumber &&
        highestReputationReports == 0) {
      final hasConcreteWarning = phones.any((phone) => phone.risk > 0);
      reasons.add(InvestigationReason(
        title: hasConcreteWarning
            ? 'Local number warning found'
            : 'No negative evidence found locally',
        explanation: hasConcreteWarning
            ? 'ScamShield found a concrete number-range or formatting concern. This is not the same as a verified scam report.'
            : 'The number format itself did not show a known local warning and it is not in the current prototype report list. This still does not prove the caller is trustworthy.',
        severity: hasConcreteWarning ? 0.18 : 0.0,
      ));
    }

    reasons.sort((a, b) => b.severity.compareTo(a.severity));

    final verdict = adjustedScore >= 60
        ? InvestigationVerdict.highRisk
        : adjustedScore >= 25
            ? InvestigationVerdict.suspicious
            : InvestigationVerdict.lowRisk;

    final reportedPhone = phones.where((phone) => phone.reportCount > 0).firstOrNull;
    final category = inputType == InvestigationInputType.phoneNumber
        ? reportedPhone?.reportedCategory ??
            (adjustedScore == 0
                ? 'No negative evidence found'
                : 'Phone number intelligence')
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

  InvestigationPhoneNumber _enrichFromPrototypeReputation(
    InvestigationPhoneNumber phone,
  ) {
    final sim = _prototypeThreatData;
    if (sim == null) return phone;

    final wanted = _digitsOnly(phone.normalized);
    for (final entry in sim.senderCounts.entries) {
      if (_digitsOnly(entry.key) != wanted) continue;

      return phone.copyWith(
        reputationAvailable: true,
        reportCount: entry.value,
        reportedCategory: sim.senderType[entry.key],
        reputationSource: 'Partner View sample data',
      );
    }
    return phone;
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
