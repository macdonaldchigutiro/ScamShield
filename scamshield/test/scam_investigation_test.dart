import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield/features/scam_check/data/repositories/rule_based_scam_investigation_repository.dart';
import 'package:scamshield/features/scam_check/domain/entities/scam_investigation.dart';

void main() {
  const repository = RuleBasedScamInvestigationRepository();

  group('Local scam investigation', () {
    test('flags a new-number impersonation with urgent money request', () async {
      final result = await repository.investigate(
        content: "Hi Mum, this is my new number. Please send £450 urgently. Don't tell anyone.",
        inputType: InvestigationInputType.message,
        channel: InvestigationChannel.whatsapp,
      );

      expect(result.riskScore, inInclusiveRange(0, 100));
      expect(result.verdict, InvestigationVerdict.highRisk);
      expect(result.reasons, isNotEmpty);
      expect(result.recommendedActions, isNotEmpty);
    });

    test('ordinary phone number has no fabricated report count', () async {
      final result = await repository.investigate(
        content: '+44 7700 900123',
        inputType: InvestigationInputType.phoneNumber,
        channel: InvestigationChannel.phoneCall,
      );

      expect(result.riskScore, inInclusiveRange(0, 100));
      expect(result.phoneNumbers.every((number) => number.reportCount == 0), isTrue);
      expect(result.phoneNumbers.every((number) => !number.reputationAvailable), isTrue);
    });
  });
}
