import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../../domain/entities/scam_investigation.dart';
import '../controllers/media_investigator_controller.dart';

/// Investigates screenshots and QR images while keeping the user in control.
///
/// OCR text is editable before analysis. That matters because OCR can confuse
/// phone numbers, domains and currency amounts, which are security-sensitive.
class MediaInvestigatorScreen extends ConsumerStatefulWidget {
  const MediaInvestigatorScreen({super.key});

  @override
  ConsumerState<MediaInvestigatorScreen> createState() =>
      _MediaInvestigatorScreenState();
}

class _MediaInvestigatorScreenState
    extends ConsumerState<MediaInvestigatorScreen> {
  final TextEditingController _extractedTextController = TextEditingController();

  @override
  void dispose() {
    _extractedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaInvestigatorControllerProvider);

    ref.listen<MediaInvestigatorState>(
      mediaInvestigatorControllerProvider,
      (previous, next) {
        if (next.media != null && next.media != previous?.media) {
          _extractedTextController.text = next.media!.extractedText;
        }
        if (next.errorMessage != null &&
            next.errorMessage != previous?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(next.errorMessage!),
            ),
          );
        }
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        GlassCard(
          borderColor: Palette.violet.withOpacity(0.45),
          tint: const Color(0x127C5CFF),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.image_search_rounded, color: Palette.violet, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCREENSHOT + QR INVESTIGATOR',
                      style: TextStyle(
                        color: Palette.violet,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.7,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Upload what you received. ScamShield will inspect it before you trust it.',
                      style: TextStyle(
                        color: Palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Screenshots stay in this session. Extracted text can be corrected before investigation.',
                      style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlowButton(
          label: state.isScanningImage ? 'READING IMAGE…' : 'CHOOSE SCREENSHOT OR QR',
          icon: Icons.add_photo_alternate_outlined,
          onTap: state.isScanningImage
              ? null
              : () => ref
                  .read(mediaInvestigatorControllerProvider.notifier)
                  .chooseImage(),
        ),
        if (state.isScanningImage) ...[
          const SizedBox(height: 14),
          const LinearProgressIndicator(
            color: Palette.cyan,
            backgroundColor: Palette.glassBorder,
          ),
        ],
        if (state.media != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border.all(color: Palette.glassBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.memory(
                state.media!.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.media!.hasQr)
            _QrDetectedCard(qrContent: state.media!.qrContent!),
          if (state.media!.ocrNotice != null) ...[
            const SizedBox(height: 10),
            GlassCard(
              borderColor: Palette.amber.withOpacity(0.45),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Palette.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.media!.ocrNotice!,
                      style: const TextStyle(
                        color: Palette.dim,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'TEXT FOUND IN THE SCREENSHOT',
            style: TextStyle(
              color: Palette.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: TextField(
              controller: _extractedTextController,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(color: Palette.text, height: 1.45),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText:
                    'ScamShield will place OCR text here. You can correct or paste the visible message before investigating.',
                hintStyle: TextStyle(color: Palette.dim),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.media!.hasQr
                      ? () => ref
                          .read(mediaInvestigatorControllerProvider.notifier)
                          .investigateText(
                            text: state.media!.qrContent!,
                            preferQr: true,
                          )
                      : null,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('INVESTIGATE QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.violet,
                    side: const BorderSide(color: Palette.violet),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isInvestigating
                      ? null
                      : () => ref
                          .read(mediaInvestigatorControllerProvider.notifier)
                          .investigateText(
                            text: _extractedTextController.text,
                            preferQr: false,
                          ),
                  icon: const Icon(Icons.shield_outlined),
                  label: Text(state.isInvestigating ? 'CHECKING…' : 'CHECK TEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.cyan,
                    foregroundColor: Palette.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (state.investigation != null) ...[
          const SizedBox(height: 18),
          _MediaInvestigationResult(result: state.investigation!),
        ],
        if (state.media != null) ...[
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _extractedTextController.clear();
                ref.read(mediaInvestigatorControllerProvider.notifier).clear();
              },
              icon: const Icon(Icons.refresh_rounded, color: Palette.dim),
              label: const Text(
                'Start another scan',
                style: TextStyle(color: Palette.dim),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QrDetectedCard extends StatelessWidget {
  final String qrContent;
  const _QrDetectedCard({required this.qrContent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.green.withOpacity(0.45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.qr_code_2_rounded, color: Palette.green, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR CODE DETECTED',
                  style: TextStyle(
                    color: Palette.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  qrContent,
                  style: const TextStyle(
                    color: Palette.text,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaInvestigationResult extends StatelessWidget {
  final ScamInvestigation result;
  const _MediaInvestigationResult({required this.result});

  Color get _color {
    switch (result.verdict) {
      case InvestigationVerdict.highRisk:
        return Palette.red;
      case InvestigationVerdict.suspicious:
        return Palette.amber;
      case InvestigationVerdict.lowRisk:
        return Palette.green;
    }
  }

  String get _label {
    switch (result.verdict) {
      case InvestigationVerdict.highRisk:
        return 'HIGH RISK';
      case InvestigationVerdict.suspicious:
        return 'SUSPICIOUS';
      case InvestigationVerdict.lowRisk:
        return 'LOW RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return GlassCard(
      borderColor: color.withOpacity(0.65),
      tint: color.withOpacity(0.055),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  color: color.withOpacity(0.08),
                ),
                child: Text(
                  '${result.riskScore}',
                  style: TextStyle(
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.summary,
                      style: const TextStyle(
                        color: Palette.text,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.phoneNumbers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'PHONE INTELLIGENCE',
              style: TextStyle(
                color: Palette.cyan,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            for (final phone in result.phoneNumbers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Palette.cyan.withOpacity(0.05),
                    border: Border.all(color: Palette.cyan.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              color: Palette.cyan, size: 18),
                          const SizedBox(width: 7),
                          Expanded(
                            child: SelectableText(
                              phone.normalized,
                              style: const TextStyle(
                                color: Palette.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${phone.countryHint} • ${phone.typeHint}',
                        style: const TextStyle(
                          color: Palette.dim,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        phone.reputationAvailable
                            ? 'Live reputation data available.'
                            : 'Live reputation is not connected yet. Caller ID can be spoofed, so verify the caller independently.',
                        style: const TextStyle(
                          color: Palette.amber,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      if (phone.warnings.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        for (final warning in phone.warnings)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '• $warning',
                              style: const TextStyle(
                                color: Palette.dim,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'WHY',
              style: TextStyle(
                color: Palette.dim,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 7),
            for (final reason in result.reasons.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag_outlined, color: color, size: 17),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        reason.title,
                        style: const TextStyle(
                          color: Palette.text,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (result.recommendedActions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              result.recommendedActions.first,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
