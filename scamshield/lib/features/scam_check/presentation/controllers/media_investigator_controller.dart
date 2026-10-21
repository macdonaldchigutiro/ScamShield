import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../incidents/presentation/controllers/incident_controller.dart';
import '../../data/services/media_scan_service.dart';
import '../../domain/entities/media_scan_result.dart';
import '../../domain/entities/scam_investigation.dart';
import '../../domain/use_cases/investigate_scam.dart';
import 'scam_investigator_controller.dart';

final mediaScanServiceProvider = Provider<MediaScanService>((ref) {
  return MediaScanService();
});

final mediaInvestigatorControllerProvider = StateNotifierProvider<
    MediaInvestigatorController, MediaInvestigatorState>((ref) {
  return MediaInvestigatorController(
    ref.watch(mediaScanServiceProvider),
    ref.watch(investigateScamProvider),
    ref.read(incidentControllerProvider.notifier),
  );
});

class MediaInvestigatorState {
  final bool isScanningImage;
  final bool isInvestigating;
  final MediaScanResult? media;
  final ScamInvestigation? investigation;
  final String? errorMessage;

  const MediaInvestigatorState({
    this.isScanningImage = false,
    this.isInvestigating = false,
    this.media,
    this.investigation,
    this.errorMessage,
  });
}

/// Coordinates screenshot/QR selection, local extraction and scam analysis.
///
/// Keeping this orchestration out of widgets makes it easy to unit-test and
/// lets future camera/share-sheet entry points reuse the same workflow.
class MediaInvestigatorController extends StateNotifier<MediaInvestigatorState> {
  final MediaScanService _mediaScanService;
  final InvestigateScam _investigateScam;
  final IncidentController _incidentController;

  MediaInvestigatorController(
    this._mediaScanService,
    this._investigateScam,
    this._incidentController,
  ) : super(const MediaInvestigatorState());

  Future<void> chooseImage() async {
    state = const MediaInvestigatorState(isScanningImage: true);

    try {
      final media = await _mediaScanService.pickAndScanImage();
      if (media == null) {
        state = const MediaInvestigatorState();
        return;
      }
      state = MediaInvestigatorState(media: media);
    } catch (error) {
      state = MediaInvestigatorState(errorMessage: error.toString());
    }
  }

  Future<void> investigateText({
    required String text,
    required bool preferQr,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      state = MediaInvestigatorState(
        media: state.media,
        errorMessage: 'There is no text or QR content to investigate yet.',
      );
      return;
    }

    state = MediaInvestigatorState(
      media: state.media,
      isInvestigating: true,
    );

    try {
      final looksLikeLink = Uri.tryParse(cleaned)?.hasScheme == true;
      final result = await _investigateScam(
        content: cleaned,
        inputType: looksLikeLink
            ? InvestigationInputType.link
            : InvestigationInputType.message,
        channel: InvestigationChannel.other,
        sender: preferQr ? 'QR code' : 'Screenshot',
      );

      if (result.verdict != InvestigationVerdict.lowRisk) {
        await _incidentController.saveInvestigation(
          investigation: result,
          content: cleaned,
          sourceLabel: preferQr ? 'QR code' : 'Screenshot',
          sender: preferQr ? 'QR code' : 'Screenshot',
        );
      }

      state = MediaInvestigatorState(
        media: state.media,
        investigation: result,
      );
    } catch (error) {
      state = MediaInvestigatorState(
        media: state.media,
        errorMessage: error.toString(),
      );
    }
  }

  void clear() {
    state = const MediaInvestigatorState();
  }
}
