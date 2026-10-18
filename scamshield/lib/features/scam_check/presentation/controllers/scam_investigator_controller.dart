import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return ScamInvestigatorController(ref.watch(investigateScamProvider));
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
/// The controller knows about the use case, but not about widgets. That keeps
/// loading/error/result behaviour testable and reusable by future entry points.
class ScamInvestigatorController extends StateNotifier<ScamInvestigatorState> {
  final InvestigateScam _investigateScam;

  ScamInvestigatorController(this._investigateScam)
      : super(const ScamInvestigatorState());

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
}
