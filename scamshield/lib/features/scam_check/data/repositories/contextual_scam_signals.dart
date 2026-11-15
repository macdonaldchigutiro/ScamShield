import '../../domain/entities/scam_investigation.dart';

/// Transparent contextual patterns. These require combinations of signals,
/// not isolated words like "bank", "parcel" or "love".
///
/// These are heuristic warning signs, not proof of fraud or a calibrated
/// probability. Nothing is sent to a server.
class ContextualScamSignal {
  final String category;
  final String title;
  final String explanation;
  final String action;
  final int scoreBoost;

  const ContextualScamSignal({
    required this.category,
    required this.title,
    required this.explanation,
    required this.action,
    required this.scoreBoost,
  });

  InvestigationReason toReason() => InvestigationReason(
        title: title,
        explanation: explanation,
        severity: scoreBoost / 100,
      );
}

final _instructional = RegExp(
  r"\b(example of a scam|scam awareness|scam warning|how to spot scams|never share|never send|do not share|don't share|do not transfer|don't transfer|avoid sending|beware of|watch out for)\b",
  caseSensitive: false,
);

bool _has(String input, String pattern) =>
    RegExp(pattern, caseSensitive: false).hasMatch(input);

/// An educational warning should not be scored as an incoming demand.
List<ContextualScamSignal> contextualScamSignals(String text) {
  final input = text.replaceAll('’', "'").replaceAll('‘', "'");
  if (_instructional.hasMatch(input)) return const [];

  final result = <ContextualScamSignal>[];

  final bankClaim = _has(input,
      r'\b(bank|fraud (team|department)|security (team|department)|suspicious transaction|unauthori[sz]ed transaction)\b');
  final moveFunds = _has(input,
      r'\b(safe|secure|holding|temporary)\s+(bank\s+)?account\b|\btransfer\b.{0,65}\b(protect|secure|safeguard)\b.{0,25}\b(funds|money|account)\b');
  if (bankClaim && moveFunds) {
    result.add(const ContextualScamSignal(
      category: 'Bank impersonation',
      title: 'Bank/security claim asks you to move funds',
      explanation:
          'The message combines a bank or fraud-team claim with instructions to move money for safety. Verify through your bank independently.',
      action:
          'Do not move money. Contact your bank using the number on your card or its official app.',
      scoreBoost: 45,
    ));
  }

  final deliveryClaim = _has(input,
      r'\b(parcel|package|delivery|courier|shipment|redelivery)\b');
  final deliveryProblem = _has(input,
      r'\b(missed|failed|held|pending|unsuccessful|reschedule|re.?deliver|address (issue|incorrect|problem))\b');
  final deliveryDemand = _has(input,
      r'\b(pay|payment|fee|charge|confirm (your )?details|update (your )?details|click|tap|visit)\b');
  if (deliveryClaim && deliveryProblem && deliveryDemand) {
    result.add(const ContextualScamSignal(
      category: 'Delivery impersonation',
      title: 'Delivery problem linked to payment or details',
      explanation:
          'The message claims there is a parcel problem and asks you to pay, follow a link or supply details. Check directly with the courier.',
      action:
          'Do not use the message link. Check your order and delivery status in the retailer or courier app.',
      scoreBoost: 32,
    ));
  }

  final whatsAppClaim = _has(input,
      r'\b(whats\s?app|my (account|number)|registered (my|your) number)\b');
  final codeRequest = _has(input,
      r'\b(send|share|forward|tell|give|reply with|read out)\b.{0,65}\b(code|otp|pin|six.?digit|6.?digit)\b|\b(code|otp)\b.{0,50}\b(sent (by|to) (mistake|you)|by mistake)\b');
  if (whatsAppClaim && codeRequest) {
    result.add(const ContextualScamSignal(
      category: 'Account takeover',
      title: 'WhatsApp or account verification code requested',
      explanation:
          'Someone is asking for an account verification code. Giving it away can allow account takeover.',
      action:
          'Never share the code. Check your WhatsApp linked devices and enable two-step verification.',
      scoreBoost: 45,
    ));
  }

  final relationship = _has(input,
      r'\b(love you|my darling|sweetheart|babe|baby|my love|relationship|marry you|romantic)\b');
  final financialRequest = _has(input,
      r'\b(send|transfer|wire|lend|loan|pay|deposit|help me with)\b.{0,80}(?:\b(money|cash|funds|ticket|hospital|emergency|crypto|gift card|fee)\b|[£\$€]\s?\d+)');
  if (relationship && financialRequest) {
    result.add(const ContextualScamSignal(
      category: 'Romance-related money request',
      title: 'Romantic language combined with a money request',
      explanation:
          'Affection and an urgent request for funds appear together. This can occur in romance fraud, but context and independent verification matter.',
      action:
          'Pause any transfer. Verify the person independently and speak to someone you trust before sending money.',
      scoreBoost: 28,
    ));
  }

  final investment = _has(input,
      r'\b(invest|investment|trading|forex|crypto|bitcoin|token|returns?|profit|yield)\b');
  final promise = _has(input,
      r'\b(guaranteed|risk.?free|no risk|double your money|double (your )?investment|\d+\s?%\s*(daily|weekly|return|profit)|fixed high return|instant profit)\b');
  if (investment && promise) {
    result.add(const ContextualScamSignal(
      category: 'Investment fraud warning',
      title: 'Investment offer promises unrealistic or guaranteed returns',
      explanation:
          'The offer combines an investment pitch with guaranteed or unusually high returns. This is a common investment-fraud warning sign.',
      action:
          'Do not transfer money based on the promise. Check the firm independently using the relevant financial regulator.',
      scoreBoost: 40,
    ));
  }

  return result;
}
