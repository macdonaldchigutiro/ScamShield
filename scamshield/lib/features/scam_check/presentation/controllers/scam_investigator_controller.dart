import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../incidents/presentation/controllers/incident_controller.dart';
import '../../data/repositories/rule_based_scam_investigation_repository.dart';
import '../../domain/entities/scam_investigation.dart';
import '../../domain/repositories/scam_investigation_repository.dart';
import '../../domain/use_cases/investigate_scam.dart';

final scamInvestigationRepositoryProvider =
    Provider<ScamInvestigationRepository>((ref) {
  return const RuleBasedScamInvestigationRepository();
});

final investigateScamProvider = Provider<InvestigateScam>((ref) {
  return InvestigateScam(ref.watch(scamInvestigationRepositoryProvider));
});

final scamInvestigatorControllerProvider = StateNotifierProvider<
    ScamInvestigatorController, ScamInvestigatorState>((ref) {
  return ScamInvestigatorController(
    ref.watch(investigateScamProvider),
    ref.read(incidentControllerProvider.notifier),
  );
});

class ScamInvestigatorState {
  final bool isLoading;
  final ScamInvestigation? result;
  final String? errorMessage;

  const ScamInvestigatorState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  ScamInvestigatorState copyWith({
    bool? isLoading,
    ScamInvestigation? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScamInvestigatorState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Coordinates one investigation request for the presentation layer.
///
/// The controller knows about use cases, not widgets. Concerning investigations
/// are also preserved in the Evidence Locker so users do not lose important
/// context after leaving the Check screen.
class ScamInvestigatorController extends StateNotifier<ScamInvestigatorState> {
  final InvestigateScam _investigateScam;
  final IncidentController _incidentController;

  ScamInvestigatorController(
    this._investigateScam,
    this._incidentController,
  ) : super(const ScamInvestigatorState());

  Future<void> investigate({
    required String content,
    required InvestigationInputType inputType,
    required InvestigationChannel channel,
    String sender = '',
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearResult: true,
      clearError: true,
    );

    try {
      final result = await _investigateScam(
        content: content,
        inputType: inputType,
        channel: channel,
        sender: sender,
      );

      // Low-risk checks are intentionally not stored. Suspicious/high-risk
      // results are preserved automatically so evidence is not lost by mistake.
      if (result.verdict != InvestigationVerdict.lowRisk) {
        await _incidentController.saveInvestigation(
          investigation: result,
          content: content,
          sourceLabel: _sourceLabel(inputType, channel),
          sender: sender,
        );
      }

      state = state.copyWith(isLoading: false, result: result);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clear() {
    state = const ScamInvestigatorState();
  }

  String _sourceLabel(
    InvestigationInputType inputType,
    InvestigationChannel channel,
  ) {
    switch (inputType) {
      case InvestigationInputType.link:
        return 'Suspicious link';
      case InvestigationInputType.phoneNumber:
        return 'Phone / caller details';
      case InvestigationInputType.message:
        return _channelLabel(channel);
    }
  }

  String _channelLabel(InvestigationChannel channel) {
    switch (channel) {
      case InvestigationChannel.sms:
        return 'SMS message';
      case InvestigationChannel.whatsapp:
        return 'WhatsApp message';
      case InvestigationChannel.facebook:
        return 'Facebook message';
      case InvestigationChannel.email:
        return 'Email';
      case InvestigationChannel.phoneCall:
        return 'Phone call';
      case InvestigationChannel.other:
        return 'Message';
    }
  }
}
