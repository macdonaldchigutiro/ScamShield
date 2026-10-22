import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sharing/share_intent_bridge.dart';
import '../../../../theme.dart';
import '../../domain/entities/scam_investigation.dart';
import '../controllers/scam_investigator_controller.dart';

/// Review surface shown when text is explicitly shared to ScamShield from
/// Android. The user can edit the text before choosing to investigate it.
class SharedMessageReviewScreen extends ConsumerStatefulWidget {
  final String sharedText;

  const SharedMessageReviewScreen({
    super.key,
    required this.sharedText,
  });

  @override
  ConsumerState<SharedMessageReviewScreen> createState() =>
      _SharedMessageReviewScreenState();
}

class _SharedMessageReviewScreenState
    extends ConsumerState<SharedMessageReviewScreen> {
  late final TextEditingController _controller;
  InvestigationChannel _channel = InvestigationChannel.whatsapp;
  String _checkedText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.sharedText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scamInvestigatorControllerProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    ref.read(sharedTextProvider.notifier).state = null;
    ref.read(scamInvestigatorControllerProvider.notifier).clear();
  }

  Future<void> _investigate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _checkedText = text);
    await ref.read(scamInvestigatorControllerProvider.notifier).investigate(
          content: text,
          inputType: InvestigationInputType.message,
          channel: _channel,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scamInvestigatorControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        GlassCard(
          borderColor: Palette.cyan.withOpacity(.42),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Palette.cyan.withOpacity(.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Palette.cyan.withOpacity(.3)),
                ),
                child: const Icon(Icons.share_rounded, color: Palette.cyan),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared to ScamShield',
                      style: TextStyle(
                        color: Palette.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review the text below, choose where it came from, then investigate when you are ready.',
                      style: TextStyle(
                        color: Palette.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cancel shared check',
                onPressed: _dismiss,
                icon: const Icon(Icons.close_rounded, color: Palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'WHERE DID IT COME FROM?',
          style: TextStyle(
            color: Palette.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final channel in InvestigationChannel.values)
              ChoiceChip(
                selected: _channel == channel,
                onSelected: (_) => setState(() => _channel = channel),
                label: Text(_channelLabel(channel)),
                selectedColor: Palette.cyan.withOpacity(.18),
                backgroundColor: Palette.surface,
                side: BorderSide(
                  color: _channel == channel ? Palette.cyan : Palette.line,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(color: Palette.text, height: 1.45),
            decoration: const InputDecoration(
              labelText: 'Shared message',
              alignLabelWithHint: true,
              hintText: 'Shared text appears here',
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: state.isLoading ? null : _investigate,
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.manage_search_rounded),
          label: Text(state.isLoading ? 'INVESTIGATING…' : 'INVESTIGATE NOW'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Palette.cyan,
            foregroundColor: Palette.bg,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sharing a message to ScamShield does not analyse it automatically. Analysis starts only when you press Investigate now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.muted, fontSize: 11.5, height: 1.35),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: Palette.red),
          ),
        ],
        if (state.result != null && !state.isLoading) ...[
          const SizedBox(height: 18),
          _SharedResult(
            result: state.result!,
            checkedText: _checkedText,
          ),
        ],
      ],
    );
  }
}

class _SharedResult extends StatelessWidget {
  final ScamInvestigation result;
  final String checkedText;

  const _SharedResult({required this.result, required this.checkedText});

  @override
  Widget build(BuildContext context) {
    final color = switch (result.verdict) {
      InvestigationVerdict.highRisk => Palette.red,
      InvestigationVerdict.suspicious => Palette.amber,
      InvestigationVerdict.lowRisk => Palette.green,
    };
    final label = switch (result.verdict) {
      InvestigationVerdict.highRisk => 'HIGH RISK',
      InvestigationVerdict.suspicious => 'SUSPICIOUS',
      InvestigationVerdict.lowRisk => 'LOW RISK',
    };

    return GlassCard(
      borderColor: color.withOpacity(.48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(.38), width: 2),
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
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.summary,
                      style: const TextStyle(
                        color: Palette.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'WHY SCAMSHIELD FLAGGED IT',
              style: TextStyle(
                color: Palette.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final reason in result.reasons.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '• ${reason.title}: ${reason.explanation}',
                  style: const TextStyle(
                    color: Palette.text,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
          ],
          if (checkedText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Checked ${checkedText.length} characters from the shared message.',
              style: const TextStyle(color: Palette.muted, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}

String _channelLabel(InvestigationChannel channel) {
  return switch (channel) {
    InvestigationChannel.sms => 'SMS',
    InvestigationChannel.whatsapp => 'WhatsApp',
    InvestigationChannel.facebook => 'Facebook',
    InvestigationChannel.email => 'Email',
    InvestigationChannel.phoneCall => 'Call',
    InvestigationChannel.other => 'Other',
  };
}
