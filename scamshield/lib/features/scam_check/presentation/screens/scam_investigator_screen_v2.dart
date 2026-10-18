import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../theme.dart';
import '../../domain/entities/scam_investigation.dart';
import '../controllers/scam_investigator_controller.dart';

/// Main ScamShield investigation screen.
///
/// This widget only manages user interaction and presentation. Scam detection
/// remains in the domain/data layers so it can evolve independently of the UI.
class ScamInvestigatorScreen extends ConsumerStatefulWidget {
  const ScamInvestigatorScreen({super.key});

  @override
  ConsumerState<ScamInvestigatorScreen> createState() =>
      _ScamInvestigatorScreenState();
}

class _ScamInvestigatorScreenState
    extends ConsumerState<ScamInvestigatorScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();

  InvestigationInputType _inputType = InvestigationInputType.message;
  InvestigationChannel _channel = InvestigationChannel.whatsapp;
  String _checkedContent = '';

  @override
  void dispose() {
    _contentController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (!mounted || data?.text == null) return;
    setState(() => _contentController.text = data!.text!);
  }

  Future<void> _investigate() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    _checkedContent = _contentController.text.trim();
    await ref.read(scamInvestigatorControllerProvider.notifier).investigate(
          content: _contentController.text,
          inputType: _inputType,
          channel: _channel,
          sender: _senderController.text,
        );

    if (!mounted) return;
    final result = ref.read(scamInvestigatorControllerProvider).result;
    if (result?.verdict == InvestigationVerdict.highRisk) {
      HapticFeedback.heavyImpact();
    }
  }

  void _clear() {
    _contentController.clear();
    _senderController.clear();
    _checkedContent = '';
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
        const _InvestigatorHeader(),
        const SizedBox(height: 16),
        const _Label('WHAT DO YOU WANT TO CHECK?'),
        const SizedBox(height: 8),
        _TypeSelector(
          selected: _inputType,
          onChanged: (value) {
            setState(() => _inputType = value);
            ref.read(scamInvestigatorControllerProvider.notifier).clear();
          },
        ),
        const SizedBox(height: 14),
        _InvestigationInput(
          type: _inputType,
          channel: _channel,
          contentController: _contentController,
          senderController: _senderController,
          onChannelChanged: (value) => setState(() => _channel = value),
          onPaste: _paste,
          onClear: _clear,
        ),
        const SizedBox(height: 14),
        GlowButton(
          label: state.isLoading ? 'INVESTIGATING…' : 'INVESTIGATE NOW',
          icon: state.isLoading
              ? Icons.hourglass_top_rounded
              : Icons.manage_search_rounded,
          onTap: state.isLoading ? null : _investigate,
        ),
        if (state.isLoading) ...[
          const SizedBox(height: 16),
          const _ScanningPanel(),
        ],
        if (state.result != null && !state.isLoading) ...[
          const SizedBox(height: 18),
          _ResultView(
            content: _checkedContent,
            result: state.result!,
            onGetHelp: () {
              // The Help area is tab index 3 in the persistent shell.
              ref.read(selectedHomeTabProvider.notifier).state = 3;
            },
          ),
        ],
      ],
    );
  }
}

class _InvestigatorHeader extends StatelessWidget {
  const _InvestigatorHeader();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.cyan.withOpacity(0.35),
      tint: const Color(0x1500E5FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: shieldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Palette.cyan.withOpacity(0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.manage_search_rounded,
                color: Colors.white, size: 28),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Check it before you trust it.',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'See the risk, the warning signs and the safest next action — not just a yes/no answer.',
                  style: TextStyle(
                    color: Palette.dim,
                    fontSize: 12.5,
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _TypeSelector extends StatelessWidget {
  final InvestigationInputType selected;
  final ValueChanged<InvestigationInputType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeButton(
          type: InvestigationInputType.message,
          label: 'Message',
          icon: Icons.chat_bubble_outline,
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _TypeButton(
          type: InvestigationInputType.link,
          label: 'Link',
          icon: Icons.link_rounded,
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _TypeButton(
          type: InvestigationInputType.phoneNumber,
          label: 'Number',
          icon: Icons.phone_outlined,
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final InvestigationInputType type;
  final String label;
  final IconData icon;
  final InvestigationInputType selected;
  final ValueChanged<InvestigationInputType> onChanged;

  const _TypeButton({
    required this.type,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selected;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isSelected ? shieldGradient : null,
            color: isSelected ? null : Palette.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : Palette.glassBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 21,
                  color: isSelected ? Colors.white : Palette.dim),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Palette.dim,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestigationInput extends StatelessWidget {
  final InvestigationInputType type;
  final InvestigationChannel channel;
  final TextEditingController contentController;
  final TextEditingController senderController;
  final ValueChanged<InvestigationChannel> onChannelChanged;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  const _InvestigationInput({
    required this.type,
    required this.channel,
    required this.contentController,
    required this.senderController,
    required this.onChannelChanged,
    required this.onPaste,
    required this.onClear,
  });

  String get _hint {
    switch (type) {
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
          if (type == InvestigationInputType.message) ...[
            const _Label('WHERE DID IT COME FROM?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in InvestigationChannel.values)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onChannelChanged(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: value == channel
                            ? Palette.violet.withOpacity(0.5)
                            : Palette.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: value == channel
                              ? Palette.violet
                              : Palette.glassBorder,
                        ),
                      ),
                      child: Text(
                        _channelLabel(value),
                        style: TextStyle(
                          color: value == channel ? Colors.white : Palette.dim,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: contentController,
            minLines: type == InvestigationInputType.message ? 4 : 2,
            maxLines: type == InvestigationInputType.message ? 7 : 4,
            keyboardType: type == InvestigationInputType.phoneNumber
                ? TextInputType.phone
                : TextInputType.multiline,
            style: const TextStyle(color: Palette.text, height: 1.45),
            decoration: InputDecoration(
              hintText: _hint,
              hintStyle: const TextStyle(color: Palette.dim),
              border: InputBorder.none,
            ),
          ),
          if (type == InvestigationInputType.message) ...[
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
                    color: Palette.cyan, size: 17),
                label: const Text('Paste',
                    style: TextStyle(color: Palette.cyan)),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded,
                    color: Palette.dim, size: 17),
                label: const Text('Clear',
                    style: TextStyle(color: Palette.dim)),
              ),
              const Spacer(),
              const Icon(Icons.lock_outline, color: Palette.green, size: 14),
              const SizedBox(width: 5),
              const Text('On-device',
                  style: TextStyle(color: Palette.dim, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanningPanel extends StatelessWidget {
  const _ScanningPanel();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.cyan.withOpacity(0.3),
      child: const Column(
        children: [
          LinearProgressIndicator(
            backgroundColor: Palette.glassBorder,
            color: Palette.cyan,
            minHeight: 3,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar_rounded, color: Palette.cyan, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Checking language, identity cues, links and pressure tactics…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.dim, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final String content;
  final ScamInvestigation result;
  final VoidCallback onGetHelp;

  const _ResultView({
    required this.content,
    required this.result,
    required this.onGetHelp,
  });

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(result.verdict);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: color.withOpacity(0.65),
          tint: color.withOpacity(0.05),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                              begin: 0, end: result.riskScore / 100),
                          duration: const Duration(milliseconds: 750),
                          builder: (context, value, _) => CustomPaint(
                            size: const Size(92, 92),
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
                                fontWeight: FontWeight.w900,
                                fontSize: 23,
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
                                color: color, size: 20),
                            const SizedBox(width: 6),
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
                        const SizedBox(height: 6),
                        Text(
                          result.verdict == InvestigationVerdict.lowRisk
                              ? 'No strong known scam pattern found'
                              : result.category,
                          style: const TextStyle(
                            color: Palette.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _verdictSummary(result.verdict),
                          style: const TextStyle(
                            color: Palette.dim,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result.verdict != InvestigationVerdict.lowRisk) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    result.verdict == InvestigationVerdict.highRisk
                        ? 'STOP: do not send money, codes or passwords, and do not follow the sender’s instructions until you verify them independently.'
                        : 'Pause before acting. Verify the sender or organisation independently first.',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _Label('WHAT SCAMSHIELD SAW'),
          const SizedBox(height: 8),
          GlassCard(child: _HighlightedText(content: content, result: result)),
        ],
        if (result.reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _Label('WHY THIS SCORE?'),
          const SizedBox(height: 8),
          for (final reason in result.reasons.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      reason.severity >= 0.4
                          ? Icons.gpp_bad_outlined
                          : Icons.warning_amber_rounded,
                      color: reason.severity >= 0.4
                          ? Palette.red
                          : Palette.amber,
                      size: 20,
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
          const _Label('LINK INTELLIGENCE'),
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
                                color: Palette.dim,
                                fontSize: 11.5,
                                height: 1.35),
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
        const _Label('SAFEST NEXT STEPS'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              for (int index = 0;
                  index < result.recommendedActions.length;
                  index++)
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
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Palette.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.recommendedActions[index],
                          style: const TextStyle(
                            color: Palette.text,
                            fontSize: 12.5,
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
        if (result.verdict != InvestigationVerdict.lowRisk) ...[
          const SizedBox(height: 12),
          GlowButton(
            label: 'I ALREADY ACTED — GET HELP',
            icon: Icons.health_and_safety_outlined,
            gradient: dangerGradient,
            glow: Palette.red,
            onTap: onGetHelp,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                final warning =
                    'ScamShield warning: this content scored ${result.riskScore}% risk (${result.category}). Do not send money, codes or passwords until you verify it independently.';
                Clipboard.setData(ClipboardData(text: warning));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Safety warning copied.'),
                ));
              },
              icon: const Icon(Icons.ios_share_rounded,
                  color: Palette.cyan, size: 18),
              label: const Text('Copy warning to share',
                  style: TextStyle(color: Palette.cyan)),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'ScamShield is decision support, not a guarantee. If you are unsure, contact the organisation using an official number you find independently.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.dim, fontSize: 10.5, height: 1.4),
        ),
      ],
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String content;
  final ScamInvestigation result;

  const _HighlightedText({required this.content, required this.result});

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty || result.highlights.isEmpty) {
      return Text(content,
          style: const TextStyle(color: Palette.text, height: 1.5));
    }

    final severity = List<double>.filled(content.length, 0);
    for (final highlight in result.highlights) {
      final start = highlight.start.clamp(0, content.length).toInt();
      final end = highlight.end.clamp(start, content.length).toInt();
      for (int index = start; index < end; index++) {
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
    int start = 0;
    while (start < content.length) {
      final currentBucket = bucket(severity[start]);
      int end = start + 1;
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
    case InvestigationVerdict.lowRisk:
      return Palette.green;
    case InvestigationVerdict.suspicious:
      return Palette.amber;
    case InvestigationVerdict.highRisk:
      return Palette.red;
  }
}

IconData _verdictIcon(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.lowRisk:
      return Icons.verified_user_rounded;
    case InvestigationVerdict.suspicious:
      return Icons.warning_amber_rounded;
    case InvestigationVerdict.highRisk:
      return Icons.gpp_bad_rounded;
  }
}

String _verdictLabel(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.lowRisk:
      return 'LOW RISK';
    case InvestigationVerdict.suspicious:
      return 'SUSPICIOUS';
    case InvestigationVerdict.highRisk:
      return 'HIGH RISK';
  }
}

String _verdictSummary(InvestigationVerdict verdict) {
  switch (verdict) {
    case InvestigationVerdict.lowRisk:
      return 'No strong known scam pattern was detected. Still protect money, passwords and codes.';
    case InvestigationVerdict.suspicious:
      return 'Some warning signs were detected. Verify independently before you act.';
    case InvestigationVerdict.highRisk:
      return 'Strong scam indicators were detected. Treat this as dangerous until proven otherwise.';
  }
}
