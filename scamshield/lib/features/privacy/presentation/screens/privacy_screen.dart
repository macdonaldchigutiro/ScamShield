import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/privacy/cloud_analysis_consent_controller.dart';
import '../../../../theme.dart';

/// Explains ScamShield's privacy model and gives the user direct control over
/// optional cloud analysis.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(cloudAnalysisConsentProvider);

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bg,
        foregroundColor: Palette.text,
        title: const Text(
          'Privacy & analysis',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const Text(
                  'Your messages are private by default',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ScamShield checks suspicious content locally first. Cloud analysis is optional and is never enabled automatically.',
                  style: TextStyle(
                    color: Palette.dim,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                const _PrivacyPoint(
                  icon: Icons.phone_android_outlined,
                  title: 'Local checks stay on your device',
                  body:
                      'The rules engine, local phone-number checks and supported screenshot/QR processing run on the device.',
                ),
                const SizedBox(height: 10),
                const _PrivacyPoint(
                  icon: Icons.inventory_2_outlined,
                  title: 'Evidence Locker is local',
                  body:
                      'Saved incident summaries are stored locally on this device unless you choose to export or share them.',
                ),
                const SizedBox(height: 10),
                const _PrivacyPoint(
                  icon: Icons.cloud_outlined,
                  title: 'Cloud analysis is for ambiguous checks only',
                  body:
                      'When enabled and a backend is configured, ScamShield may send an ambiguous message or link for a second opinion. High-confidence local results are not uploaded for this purpose.',
                ),
                const SizedBox(height: 20),
                GlassCard(
                  borderColor: Palette.cyan.withOpacity(.35),
                  child: consent.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Palette.cyan,
                            ),
                          ),
                        )
                      : SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: consent.cloudAnalysisEnabled,
                          activeColor: Palette.green,
                          title: const Text(
                            'Allow optional cloud analysis',
                            style: TextStyle(
                              color: Palette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'If enabled, only ambiguous message/link checks may be sent to ScamShield’s configured analysis service. You can turn this off at any time.',
                              style: TextStyle(
                                color: Palette.dim,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(cloudAnalysisConsentProvider.notifier)
                                .setCloudAnalysisEnabled(value);
                          },
                        ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Palette.amber.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Palette.amber.withOpacity(.35)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Palette.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Turning this on does not make cloud analysis available by itself. The app must also be connected to a configured ScamShield backend. Until then, all checks continue locally.',
                          style: TextStyle(
                            color: Palette.text,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Palette.cyan.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Palette.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Palette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Palette.dim,
                    fontSize: 13,
                    height: 1.4,
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
