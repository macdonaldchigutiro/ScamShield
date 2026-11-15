import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield/features/scam_check/data/repositories/contextual_scam_signals.dart';
import 'package:scamshield/features/scam_check/data/repositories/rule_based_scam_investigation_repository.dart';
import 'package:scamshield/features/scam_check/domain/entities/scam_investigation.dart';

void main() {
  const repository = RuleBasedScamInvestigationRepository();

  group('Evidence-backed contextual warnings', () {
    final examples = <(String, String)>[
      (
        'This is your bank fraud department. Move your savings into a safe account immediately.',
        'Bank impersonation',
      ),
      (
        'Your parcel delivery failed. Pay the redelivery fee at the link to reschedule.',
        'Delivery impersonation',
      ),
      (
        'WhatsApp support here. Share the six digit verification code we sent you.',
        'Account takeover',
      ),
      (
        'My darling, we met online and I have an emergency. Please send money for my hospital fee.',
        'Romance-related money request',
      ),
      (
        'Invest in crypto today with guaranteed 25% weekly returns.',
        'Investment fraud warning',
      ),
    ];

    for (final example in examples) {
      test('detects ${example.$2} with a specific reason and action', () async {
        final signals = contextualScamSignals(example.$1);
        expect(signals.map((signal) => signal.category), contains(example.$2));
        expect(signals.every((signal) => signal.explanation.isNotEmpty), isTrue);
        expect(signals.every((signal) => signal.action.isNotEmpty), isTrue);

        final result = await repository.investigate(
          content: example.$1,
          inputType: InvestigationInputType.message,
          channel: InvestigationChannel.other,
        );
        expect(result.verdict, isNot(InvestigationVerdict.lowRisk));
        expect(result.reasons.any((reason) =>
            reason.title == signals.first.title), isTrue);
        expect(result.recommendedActions, contains(signals.first.action));
        expect(result.riskScore, inInclusiveRange(0, 100));
      });
    }

    test('does not confuse isolated context with a combined scam pattern', () {
      expect(contextualScamSignals('My parcel arrived this morning.'), isEmpty);
      expect(contextualScamSignals('I love you, baby. Please pay the electricity bill.'), isEmpty);
      expect(contextualScamSignals('My bank statement is ready.'), isEmpty);
      expect(contextualScamSignals('I work in investment research.'), isEmpty);
    });

    test('does not classify educational messages as a fraud demand', () {
      expect(
        contextualScamSignals('Scam warning: never share a WhatsApp code or transfer money to a safe account.'),
        isEmpty,
      );
    });

    test('phishing links keep an explanatory warning', () async {
      final result = await repository.investigate(
        content: 'Your account will be suspended. Verify at https://paypal-secure-login.example.com/verify',
        inputType: InvestigationInputType.link,
        channel: InvestigationChannel.email,
      );
      expect(result.verdict, isNot(InvestigationVerdict.lowRisk));
      expect(result.links, isNotEmpty);
      expect(result.reasons, isNotEmpty);
    });

    test('additional money-request score does not retain safe advice', () async {
      final result = await repository.investigate(
        content: 'Please transfer \$30 000 into my account now',
        inputType: InvestigationInputType.message,
        channel: InvestigationChannel.other,
      );
      if (result.verdict != InvestigationVerdict.lowRisk) {
        expect(result.category.toLowerCase(), isNot(contains('no scam signs')));
        expect(result.recommendedActions.join(' ').toLowerCase(),
            isNot(contains('no common scam signs found')));
      }
    });

    test('phone-only checks do not use contextual message patterns', () async {
      final result = await repository.investigate(
        content: '+44 7700 900123',
        inputType: InvestigationInputType.phoneNumber,
        channel: InvestigationChannel.phoneCall,
      );
      expect(result.category, isNot('Bank impersonation'));
      expect(result.phoneNumbers.every((phone) => phone.reportCount == 0), isTrue);
    });
  });
}
