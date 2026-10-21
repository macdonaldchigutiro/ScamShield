import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../incidents/presentation/controllers/incident_controller.dart';
import '../../data/repositories/rule_based_scam_investigation_repository.dart';
import '../../domain/entities/scam_investigation.dart';
import '../../domain/repositories/scam_investigation_repository.dart';
import '../../domain/use_cases/investigate_scam.dart';

final scamInvestigationRepositoryProvider =
    Provider<ScamInvestigationRepository>((ref) {
  // Reuse the same prototype threat source that powers Partner View. This keeps
  // number checks internally consistent: if Partner View says a number has been
  // flagged, the investigator can see the same sample reputation evidence.
  return RuleBasedScamInvestigationRepository(
    prototypeThreatData: ref.watch(threatSimProvider),
  );
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

      state = state.copyWith(
        isLoading: false,
        result: result,
        clearError: true,
      );

      // Preserve only concerning investigations. Low-risk checks should remain
      // lightweight and private instead of filling the Evidence Locker.
      if (result.verdict != InvestigationVerdict.lowRisk) {
        await _incidentController.saveInvestigation(
          sourceLabel: _sourceLabel(inputType, channel),
          content: content.trim(),
          sender: sender.trim(),
          investigation: result,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        clearResult: true,
        errorMessage:
            'ScamShield could not complete this check. Please try again.',
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
      case InvestigationInputType.message:
        return 'Message • ${_channelLabel(channel)}';
      case InvestigationInputType.link:
        return 'Suspicious link';
      case InvestigationInputType.phoneNumber:
        return 'Phone number';
    }
  }

  String _channelLabel(InvestigationChannel channel) {
    switch (channel) {
      case InvestigationChannel.sms:
        return 'SMS';
      case InvestigationChannel.whatsapp:
        return 'WhatsApp';
      case InvestigationChannel.facebook:
        return 'Facebook';
      case InvestigationChannel.email:
        return 'Email';
      case InvestigationChannel.phoneCall:
        return 'Call';
      case InvestigationChannel.other:
        return 'Other';
    }
  }
}
