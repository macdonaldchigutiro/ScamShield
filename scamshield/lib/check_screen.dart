import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'analysis_view.dart';
import 'analyzer.dart';
import 'sim.dart';
import 'theme.dart';

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _sender = TextEditingController();
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  Analysis? _result;
  String _checkedText = '';
  String _checkedSender = '';
  bool _scanning = false;
  Channel _channel = Channel.whatsapp;

  @override
  void dispose() {
    _text.dispose();
    _sender.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData('text/plain');
    if (d?.text != null) {
      setState(() => _text.text = d!.text!);
    }
  }

  Future<void> _run() async {
    final t = _text.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Paste a message first, or tap one of the examples.'),
      ));
      return;
    }
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() {
      _scanning = true;
      _result = null;
    });
    _scan.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final a = analyze(t, sender: _sender.text, channel: _channel);
    if (a.verdict == Verdict.scam) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _scanning = false;
      _result = a;
      _checkedText = t;
      _checkedSender = _sender.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('CHECK A MESSAGE',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 4),
        const Text(
          'Paste a message from SMS, WhatsApp, Facebook, email, or what a caller said. It is checked on your phone and nothing is sent anywhere.',
          style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 12),
        const Text('WHERE DID IT COME FROM?',
            style: TextStyle(color: Palette.dim, letterSpacing: 2, fontSize: 10)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in Channel.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _channel = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: _channel == c ? shieldGradient : null,
                        color: _channel == c ? null : Palette.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _channel == c
                                ? Colors.transparent
                                : Palette.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(channelIcon(c),
                              size: 15,
                              color: _channel == c ? Colors.white : Palette.dim),
                          const SizedBox(width: 6),
                          Text(channelLabel(c),
                              style: TextStyle(
                                  color: _channel == c
                                      ? Colors.white
                                      : Palette.dim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _text,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(color: Palette.text, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Paste the message here…',
                  hintStyle: TextStyle(color: Palette.dim),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Palette.glassBorder),
              TextField(
                controller: _sender,
                style: const TextStyle(color: Palette.text, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Who sent it? Name or number (optional)',
                  hintStyle: TextStyle(color: Palette.dim, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  prefixIcon: Icon(Icons.person_outline,
                      color: Palette.dim, size: 18),
                  prefixIconConstraints: BoxConstraints(minWidth: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste, size: 18, color: Palette.cyan),
              label: const Text('Paste', style: TextStyle(color: Palette.cyan)),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _text.clear();
                _sender.clear();
                _result = null;
              }),
              icon: const Icon(Icons.clear, size: 18, color: Palette.dim),
              label: const Text('Clear', style: TextStyle(color: Palette.dim)),
            ),
          ],
        ),
        const Text('OR TRY AN EXAMPLE',
            style: TextStyle(color: Palette.dim, letterSpacing: 2, fontSize: 10)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in samples)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _text.text = s.text;
                      _sender.text = s.sender;
                      _channel = s.channel;
                      _result = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Palette.glassBorder),
                      ),
                      child: Text(s.label,
                          style: const TextStyle(
                              color: Palette.text, fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlowButton(
          label: _scanning ? 'SCANNING…' : 'SCAN MESSAGE',
          icon: Icons.radar,
          onTap: _scanning ? null : _run,
        ),
        const SizedBox(height: 18),
        if (_scanning)
          GlassCard(
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: AnimatedBuilder(
                    animation: _scan,
                    builder: (context, _) => CustomPaint(
                      size: const Size(double.infinity, 70),
                      painter: _ScanPainter(_scan.value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _scan,
                  builder: (context, _) {
                    const steps = [
                      'Reading the message…',
                      'Checking pressure tactics…',
                      'Checking links and senders…',
                      'Working out the risk…',
                    ];
                    final i = (_scan.value * steps.length).floor().clamp(0, 3).toInt();
                    return Text(steps[i],
                        style: const TextStyle(color: Palette.cyan, fontSize: 13));
                  },
                ),
              ],
            ),
          )
        else if (_result != null)
          AnalysisView(text: _checkedText, a: _result!, sender: _checkedSender),
      ],
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0x1400E5FF));
    for (int i = 0; i < 4; i++) {
      final y = 12.0 + i * 15;
      canvas.drawLine(
        Offset(16, y),
        Offset(size.width * (0.5 + 0.4 * ((i * 37) % 10) / 10), y),
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    final x = size.width * t;
    canvas.drawRect(
      Rect.fromLTWH(x - 30, 0, 30, size.height),
      Paint()
        ..shader = LinearGradient(colors: [
          Palette.cyan.withOpacity(0),
          Palette.cyan.withOpacity(0.35),
        ]).createShader(Rect.fromLTWH(x - 30, 0, 30, size.height)),
    );
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Palette.cyan
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.t != t;
}
