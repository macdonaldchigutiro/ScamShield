/// Domain models used by ScamShield's investigation experience.
///
/// These classes deliberately contain no Flutter or legacy-analyzer types.
/// Keeping the domain layer framework-independent makes the investigation
/// logic easy to test and lets us replace the current rules engine later
/// without rewriting the user interface.
enum InvestigationInputType { message, link, phoneNumber }

enum InvestigationChannel {
  sms,
  whatsapp,
  facebook,
  email,
  phoneCall,
  other,
}

enum InvestigationVerdict { lowRisk, suspicious, highRisk }

class InvestigationReason {
  final String title;
  final String explanation;
  final double severity;

  const InvestigationReason({
    required this.title,
    required this.explanation,
    required this.severity,
  });
}

class InvestigationLink {
  final String url;
  final String domain;
  final List<String> warnings;
  final double risk;

  const InvestigationLink({
    required this.url,
    required this.domain,
    required this.warnings,
    required this.risk,
  });
}

/// Normalised phone-number intelligence found during an investigation.
///
/// `warnings` describes only facts ScamShield can infer locally. We do not
/// claim that a number has been reported unless a real reputation source has
/// supplied that data.
class InvestigationPhoneNumber {
  final String raw;
  final String normalized;
  final String countryHint;
  final String typeHint;
  final List<String> warnings;
  final double risk;
  final bool reputationAvailable;

  const InvestigationPhoneNumber({
    required this.raw,
    required this.normalized,
    required this.countryHint,
    required this.typeHint,
    required this.warnings,
    required this.risk,
    this.reputationAvailable = false,
  });
}

class InvestigationHighlight {
  final int start;
  final int end;
  final double severity;

  const InvestigationHighlight({
    required this.start,
    required this.end,
    required this.severity,
  });
}

class ScamInvestigation {
  final int riskScore;
  final InvestigationVerdict verdict;
  final String category;
  final InvestigationChannel channel;
  final List<InvestigationReason> reasons;
  final List<InvestigationLink> links;
  final List<InvestigationPhoneNumber> phoneNumbers;
  final List<InvestigationHighlight> highlights;
  final List<String> recommendedActions;

  const ScamInvestigation({
    required this.riskScore,
    required this.verdict,
    required this.category,
    required this.channel,
    required this.reasons,
    required this.links,
    this.phoneNumbers = const [],
    required this.highlights,
    required this.recommendedActions,
  });

  /// Short plain-English description suitable for compact result cards.
  String get summary {
    switch (verdict) {
      case InvestigationVerdict.highRisk:
        return 'Strong warning signs were found. Likely category: $category.';
      case InvestigationVerdict.suspicious:
        return 'Some warning signs were found. Treat this carefully.';
      case InvestigationVerdict.lowRisk:
        return 'No strong scam pattern was found, but verify important requests independently.';
    }
  }
}
