import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-controlled privacy setting for optional cloud/AI analysis.
///
/// ScamShield stays local-only by default. The setting is persisted only after
/// the user explicitly changes it in the Privacy screen.
final cloudAnalysisConsentProvider = StateNotifierProvider<
    CloudAnalysisConsentController, CloudAnalysisConsentState>((ref) {
  return CloudAnalysisConsentController();
});

class CloudAnalysisConsentState {
  final bool isLoading;
  final bool cloudAnalysisEnabled;

  const CloudAnalysisConsentState({
    this.isLoading = false,
    this.cloudAnalysisEnabled = false,
  });
}

class CloudAnalysisConsentController
    extends StateNotifier<CloudAnalysisConsentState> {
  static const _storageKey = 'scamshield.privacy.cloud_analysis_enabled.v1';

  CloudAnalysisConsentController()
      : super(const CloudAnalysisConsentState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = CloudAnalysisConsentState(
      cloudAnalysisEnabled: prefs.getBool(_storageKey) ?? false,
    );
  }

  Future<void> setCloudAnalysisEnabled(bool enabled) async {
    state = CloudAnalysisConsentState(cloudAnalysisEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, enabled);
  }
}
