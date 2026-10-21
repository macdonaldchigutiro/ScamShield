import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stable IDs for protection actions that contribute to the user's score.
///
/// The score is deliberately based only on actions the user explicitly marks as
/// complete. ScamShield never invents protection points or infers settings it
/// cannot actually verify on the device.
const protectionStepIds = <String>[
  '2sv',
  'passkey',
  'linked',
  'privacy',
  'other2sv',
  'pin',
  'simid',
  'line',
  'mail2sv',
  'unique',
  'recovery',
  'family',
  'safeword',
  'callfirst',
];

final protectionControllerProvider =
    StateNotifierProvider<ProtectionController, ProtectionState>((ref) {
  return ProtectionController();
});

class ProtectionState {
  final bool isLoading;
  final Set<String> completedStepIds;

  const ProtectionState({
    this.isLoading = false,
    this.completedStepIds = const <String>{},
  });

  int get completedCount => completedStepIds.length;
  int get totalCount => protectionStepIds.length;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
  int get percentage => (progress * 100).round();
}

/// Owns protection progress and persists it locally between app sessions.
class ProtectionController extends StateNotifier<ProtectionState> {
  static const _storageKey = 'scamshield.protection.completed_steps.v1';

  ProtectionController() : super(const ProtectionState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? const <String>[];
    final valid = stored.where(protectionStepIds.contains).toSet();
    state = ProtectionState(completedStepIds: valid);
  }

  Future<void> toggle(String stepId) async {
    if (!protectionStepIds.contains(stepId)) return;

    final updated = <String>{...state.completedStepIds};
    if (!updated.add(stepId)) updated.remove(stepId);

    state = ProtectionState(completedStepIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated.toList()..sort());
  }
}
