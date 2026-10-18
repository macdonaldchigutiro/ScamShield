import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../theme.dart';
import '../../domain/entities/scam_investigation.dart';
import '../controllers/scam_investigator_controller.dart';

/// ScamShield's primary investigation experience.
///
/// The screen is intentionally action-first: users choose what they want to
/// inspect, provide the suspicious content, and receive an explainable verdict
/// with clear next steps. Detection logic lives outside this widget.
class ScamInvestigatorScreen extends ConsumerStatefulWidget {
  const ScamInvestigatorScreen({super.key});

  @override
  ConsumerState<ScamInvestigatorScreen> createState() =>
      _ScamInvestigatorScreenState();
}

class _ScamInvestigatorScreenState
    extends ConsumerState<ScamInvestigatorScreen> {
  final _contentController = TextEditingController();
  final _senderController = TextEditingController();

  InvestigationInputType _inputType = InvestigationInputType.message;
  InvestigationChannel _channel = InvestigationChannel.whatsapp;
  String _lastCheckedContent = '';

  @override
  void dispose() {
    _contentController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final clipboard = await Clipboard.getData('text/plain');
    if (!mounted || clipboard?.text == null) return;
    setState(() => _contentController.text = clipboard!.text!);
  }

  Future<void> _investigate() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    _lastCheckedContent = _contentController.text.trim();
    await ref.read(scamInvestigatorControllerProvider.notifier).investigate(
          content: _contentController.text,
          inputType: _inputType,
          channel: _channel,
          sender: _senderController.text,
        );

    if (!mounted) return;
    final state = ref.read(scamInvestigatorControllerProvider);
    if (state.result?.verdict == InvestigationVerdict.highRisk) {
      HapticFeedback.heavyImpact();
    }
  }

  void _clear() {
    _contentController.clear();
    _senderController.clear();
    _lastCheckedContent = '';
    ref.read(scamInvestigatorControllerProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scamInvestigatorControllerProvider);

    ref.listen<ScamInvestigatorState>(
      scamInvestigatorControllerProvider,
      (previous, next) {
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
        _IntroCard(),
        const SizedBox(height: 16),
        const _SectionLabel('WHAT DO YOU WANT TO CHECK?'),
        const SizedBox(height: 8),
        _InputTypeSelector(
          selected: _inputType,
          onChanged: (value) {
            setState(() => _inputType = value);
            ref.read(scamInvestigatorControllerProvider.notifier).clear();
          },
        ),
        const SizedBox(height: 14),
        _InputCard(
          inputType: _inputType,
          channel: _channel,
          contentController: _contentController,
          senderController: _senderController,
          onChannelChanged: (value) => setState(() => _channel = value),
          onPaste: _paste,
          onClear: _clear,
        ),
        const SizedBox(height: 14),
        _InvestigateButton(
          loading: state.isLoading,
          onPressed: state.isLoading ? null : _investigate,
        ),
        if (state.isLoading) ...[
          const SizedBox(height: 16),
          const _ScanningCard(),
        ],
        if (state.result != null && !state.isLoading) ...[
          const SizedBox(height: 18),
          _InvestigationResultCard(
            content: _lastCheckedContent,
            result: state.result!,
            onNeedHelp: () {
              // Help is the fourth tab in the persistent application shell.
              ref.read(selectedHomeTabProvider.notifier).state = 3;
            },
          ),
        ],
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.cyan.withOpacity(0.35),
      tint: const Color(0x1500E5FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: shieldGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Palette.cyan.withOpacity(0.25),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(Icons.manage_search_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCAM INVESTIGATOR',
                  style: TextStyle(
                    color: Palette.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Check something before you trust it.',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'ScamShield explains the warning signs, highlights risky wording and tells you the safest next action.',
                  style: TextStyle(color: Palette.dim, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Palette.dim,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _InputTypeSelector extends StatelessWidget {
  final InvestigationInputType selected;
  final ValueChanged<InvestigationInputType> onChanged;

  const _InputTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeTile(
            label: 'Message',
            icon: Icons.chat_bubble_outline,
            selected: selected == InvestigationInputType.message,
            onTap: () => onChanged(InvestigationInputType.message),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TypeTile(
            label: 'Link',
            icon: Icons.link_rounded,
            selected: selected == InvestigationInputType.link,
            onTap: () => onChanged(InvestigationInputType.link),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TypeTile(
            label: 'Number',
            icon: Icons.phone_outlined,
            selected: selected == InvestigationInputType.phoneNumber,
            onTap: () => onChanged(InvestigationInputType.phoneNumber),
          ),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected ? shieldGradient : null,
          color: selected ? null : Palette.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : Palette.glassBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Palette.dim, size: 21),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Palette.dim,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final InvestigationInputType inputType;
  final InvestigationChannel channel;
  final TextEditingController contentController;
  final TextEditingController senderController;
  final ValueChanged<InvestigationChannel> onChannelChanged;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  const _InputCard({
    required this.inputType,
    required this.channel,
    required this.contentController,
    required this.senderController,
    required this.onChannelChanged,
    required this.onPaste,
    required this.onClear,
  });

  String get _hint {
    switch (inputType) {
      case InvestigationInputType.message:
        return 'Paste the suspicious message here…';
      case InvestigationInputType.link:
        return 'Paste the suspicious website or link here…';
      case InvestigationInputType.phoneNumber:
        return 'Enter the phone number or caller details…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inputType == InvestigationInputType.message) ...[
            const _SectionLabel('WHERE DID IT COME FROM?'),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final value in InvestigationChannel.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(_channelLabel(value)),
                        selected: value == channel,
                        onSelected: (_) => onChannelChanged(value),
                        labelStyle: TextStyle(
                          color: value == channel ? Colors.white : Palette.dim,
                          fontSize: 11,
                        ),
                        selectedColor: Palette.violet.withOpacity(0.75),
                        backgroundColor: Palette.glass,
                        side: const BorderSide(color: Palette.glassBorder),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: contentController,
            minLines: inputType == InvestigationInputType.message ? 4 : 2,
            maxLines: inputType == InvestigationInputType.message ? 7 : 4,
            keyboardType: inputType == InvestigationInputType.phoneNumber
                ? TextInputType.phone
                : TextInputType.multiline,
            style: const TextStyle(color: Palette.text, height: 1.45),
            decoration: InputDecoration(
              hintText: _hint,
              hintStyle: const TextStyle(color: Palette.dim),
              border: InputBorder.none,
            ),
          ),
          if (inputType == InvestigationInputType.message) ...[
            const Divider(color: Palette.glassBorder),
            TextField(
              controller: senderController,
              style: const TextStyle(color: Palette.text, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Sender name or number (optional)',
                hintStyle: TextStyle(color: Palette.dim, fontSize: 13),
                prefixIcon: Icon(Icons.person_outline,
                    color: Palette.dim, size: 18),
                prefixIconConstraints: BoxConstraints(minWidth: 30),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ],
          const Divider(color: Palette.glassBorder),
          Row(
            children: [
              TextButton.icon(
                onPressed: onPaste,
                icon: const Icon(Icons.content_paste_rounded,
                    size: 17, color: Palette.cyan),
                label: const Text('Paste',
                    style: TextStyle(color: Palette.cyan)),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline,
                    size: 17, color: Palette.dim),
                label: const Text('Clear',
                    style: TextStyle(color: Palette.dim)),
              ),
              const Spacer(),
              const Icon(Icons.lock_outline, size: 14, color: Palette.green),
              const SizedBox(width: 5),
              const Text(
                'On-device check',
                style: TextStyle(color: Palette.dim, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestigateButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _InvestigateButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlowButton(
      label: loading ? 'INVESTIGATING…' : 'INVESTIGATE NOW',
      icon: loading ? Icons.hourglass_top_rounded : Icons.shield_search_rounded,
      onTap: onPressed,
    );
  }
}

class _ScanningCard extends StatefulWidget {
  const _ScanningCard();

  @override
  State<_ScanningCard> createState() => _ScanningCardState();
}

class _ScanningCardState extends State<_ScanningCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.cyan.withOpacity(0.3),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LinearProgressIndicator(
              value: _controller.value,
              backgroundColor: Palette.glassBorder,
              color: Palette.cyan,
              minHeight: 3,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar_rounded, color: Palette.cyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Checking language, identity cues, links and pressure tactics…',
                style: TextStyle(color: Palette.dim, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestigationResultCard extends StatelessWidget {
  final String content;
  final ScamInvestigation result;
  final VoidCallback onNeedHelp;

  const _InvestigationResultCard({
    required this.content,
    required this.result,
    required this.onNeedHelp,
  });

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(result.verdict);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: color.withOpacity(0.7),
          tint: color.withOpacity(0.055),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 94,
                    height: 94,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: result.riskScore / 100),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CustomPaint(
                            size: const Size(94, 94),
                            painter: RingPainter(value, color, thickness: 9),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${result.riskScore}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text('RISK',
                                style: TextStyle(
                                    color: Palette.dim,
                                    fontSize: 9,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_verdictIcon(result.verdict),
                                color: color, size: 21),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _verdictLabel(result.verdict),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          result.verdict == InvestigationVerdict.lowRisk
                              ? 'No strong scam pattern was found.'
                              : result.category,
                          style: const TextStyle(
                            color: Palette.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _verdictSummary(result.verdict),
                          style: const TextStyle(
                              color: Palette.dim, fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result.verdict != InvestigationVerdict.lowRisk) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    result.verdict == InvestigationVerdict.highRisk
                        ? 'Do not send money, share a code, enter passwords or follow instructions from this content until you independently verify it.'
                        : 'Pause before acting. Verify the sender or organisation using contact details you find independently.',
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('WHAT SCAMSHIELD SAW'),
          const SizedBox(height: 8),
          GlassCard(child: _HighlightedContent(content: content, result: result)),
        ],
        if (result.reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('WHY THIS SCORE?'),
          const SizedBox(height: 8),
          for (final reason in result.reasons.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (reason.severity >= 0.4
                                ? Palette.red
                                : Palette.amber)
                            .withOpacity(0.12),
                      ),
                      child: Icon(
                        reason.severity >= 0.4
                            ? Icons.gpp_bad_outlined
                            : Icons.warning_amber_rounded,
                        color: reason.severity >= 0.4
                            ? Palette.red
                            : Palette.amber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reason.title,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(reason.explanation,
                              style: const TextStyle(
                                  color: Palette.dim,
                                  fontSize: 12,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (result.links.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionLabel('LINK INTELLIGENCE'),
          const SizedBox(height: 8),
          for (final link in result.links)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                borderColor: link.risk > 0
                    ? Palette.red.withOpacity(0.4)
                    : Palette.green.withOpacity(0.25),
                child: Row(
                  children: [
                    Icon(
                      link.risk > 0 ? Icons.link_off_rounded : Icons.link_rounded,
                      color: link.risk > 0 ? Palette.red : Palette.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(link.domain,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace')),
                          const SizedBox(height: 3),
                          Text(
                            link.warnings.isEmpty
                                ? 'No obvious link warning was found by the on-device rules.'
                                : link.warnings.join(' • '),
                            style: const TextStyle(
                                color: Palette.dim, fontSize: 11.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 10),
        const _SectionLabel('SAFEST NEXT STEPS'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              for (int i = 0; i < result.recommendedActions.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Palette.cyan),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Palette.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.recommendedActions[i],
                          style: const TextStyle(
                              color: Palette.text, height: 1.4, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (result.verdict != InvestigationVerdict.lowRisk) ...[
          const SizedBox(height: 12),
          GlowButton(
            label: 'I ALREADY ACTED — GET HELP',
            icon: Icons.health_and_safety_outlined,
            gradient: dangerGradient,
            glow: Palette.red,
            onTap: onNeedHelp,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              final warning =
                  'ScamShield warning: this content scored ${result.riskScore}% risk (${result.category}). Do not send money, codes or passwords until you verify it independently.';
              Clipboard.setData(ClipboardData(text: warning));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Safety warning copied.'),
              ));
            },
            icon: const Icon(Icons.ios_share_rounded, color: Palette.cyan),
            label: const Text('Copy warning to share',
                style: TextStyle(color: Palette.cyan)),
          ),
        ],
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'ScamShield is decision support, not a guarantee. When unsure, contact the organisation using an official number you find yourself.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette.dim, fontSize: 10.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _HighlightedContent extends StatelessWidget {
  final String content;
  final ScamInvestigation result;

  const _HighlightedContent({required this.content, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.highlights.isEmpty || content.isEmpty) {
      return Text(content,
          style: const TextStyle(color: Palette.text, height: 1.5));
    }

    final severity = List<double>.filled(content.length, 0);
    for (final highlight in result.highlights) {
      final start = highlight.start.clamp(0, content.length);
      final end = highlight.end.clamp(start, content.length);
      for (var index = start; index < end; index++) {
        if (highlight.severity > severity[index]) {
          severity[index] = highlight.severity;
        }
      }
    }

    int bucket(double value) {
      if (value <= 0) return 0;
      if (value < 0.25) return 1;
      if (value < 0.4) return 2;
      return 3;
    }

    final spans = <TextSpan>[];
    var start = 0;
    while (start < content.length) {
      final currentBucket = bucket(severity[start]);
      var end = start + 1;
      while (end < content.length &&
          bucket(severity[end]) == currentBucket) {
        end++;
      }

      final warningColor =
          currentBucket >= 3 ? Palette.red : Palette.amber;
      spans.add(TextSpan(
        text: content.substring(start, end),
        style: currentBucket == 0
            ? null
            : TextStyle(
                color: warningColor,
                fontWeight: FontWeight.w700,
                backgroundColor: warningColor.withOpacity(0.13),
              ),
      ));
      start = end;
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(
          color: Palette.text,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
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

Color _verdictColor(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return Palette.red;
    case InvestigationVerdict.suspicious:
      return Palette.amber;
    case InvestigationVerdict.lowRisk:
      return Palette.green;
  }
}

IconData _verdictIcon(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return Icons.gpp_bad_rounded;
    case InvestigationVerdict.suspicious:
      return Icons.warning_amber_rounded;
    case InvestigationVerdict.lowRisk:
      return Icons.verified_user_rounded;
  }
}

String _verdictLabel(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return 'HIGH RISK';
    case InvestigationVerdict.suspicious:
      return 'SUSPICIOUS';
    case InvestigationVerdict.lowRisk:
      return 'LOW RISK';
  }
}

String _verdictSummary(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.highRisk:
      return 'Strong scam indicators were detected. Treat this as dangerous until proven otherwise.';
    case InvestigationVerdict.suspicious:
      return 'Some warning signs were detected. Verify independently before you act.';
    case InvestigationVerdict.lowRisk:
      return 'No strong known scam pattern was detected, but remain careful with money, passwords and codes.';
  }
}
