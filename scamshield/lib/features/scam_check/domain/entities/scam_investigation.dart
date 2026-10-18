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
  final List<InvestigationHighlight> highlights;
  final List<String> recommendedActions;

  const ScamInvestigation({
    required this.riskScore,
    required this.verdict,
    required this.category,
    required this.channel,
    required this.reasons,
    required this.links,
    required this.highlights,
    required this.recommendedActions,
  });
}
