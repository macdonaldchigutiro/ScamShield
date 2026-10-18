import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'analyzer.dart';
import 'theme.dart';

Color verdictColor(Verdict v) {
  switch (v) {
    case Verdict.scam:
      return Palette.red;
    case Verdict.suspicious:
      return Palette.amber;
    case Verdict.safe:
      return Palette.green;
  }
}

String verdictLabel(Verdict v) {
  switch (v) {
    case Verdict.scam:
      return 'LIKELY A SCAM';
    case Verdict.suspicious:
      return 'SUSPICIOUS';
    case Verdict.safe:
      return 'LOOKS SAFE';
  }
}

IconData channelIcon(Channel c) {
  switch (c) {
    case Channel.sms:
      return Icons.sms_outlined;
    case Channel.whatsapp:
      return Icons.chat_bubble_outline;
    case Channel.facebook:
      return Icons.public;
    case Channel.email:
      return Icons.mail_outline;
    case Channel.call:
      return Icons.call_outlined;
    case Channel.other:
      return Icons.more_horiz;
  }
}

IconData verdictIcon(Verdict v) {
  switch (v) {
    case Verdict.scam:
      return Icons.gpp_bad_rounded;
    case Verdict.suspicious:
      return Icons.warning_amber_rounded;
    case Verdict.safe:
      return Icons.verified_user_rounded;
  }
}

void showAnalysisSheet(BuildContext context, String text, Analysis a,
    {String sender = ''}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1226),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Palette.glassBorder)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnalysisView(text: text, a: a, sender: sender),
          ],
        ),
      ),
    ),
  );
}

class AnalysisView extends StatelessWidget {
  final String text;
  final Analysis a;
  final String sender;
  const AnalysisView(
      {super.key, required this.text, required this.a, this.sender = ''});

  Widget _highlighted() {
    final sev = List<double>.filled(text.length, 0.0);
    for (final h in a.hits) {
      for (int i = h.start; i < h.end && i < text.length; i++) {
        if (h.weight > sev[i]) sev[i] = h.weight;
      }
    }
    int bucket(double w) => w <= 0 ? 0 : (w < 0.2 ? 1 : (w < 0.4 ? 2 : 3));
    final spans = <TextSpan>[];
    int i = 0;
    while (i < text.length) {
      final b = bucket(sev[i]);
      int j = i;
      while (j < text.length && bucket(sev[j]) == b) {
        j++;
      }
      final chunk = text.substring(i, j);
      if (b == 0) {
        spans.add(TextSpan(text: chunk));
      } else {
        final c = b == 3 ? Palette.red : Palette.amber;
        spans.add(TextSpan(
          text: chunk,
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.w700,
            backgroundColor: c.withOpacity(0.16),
          ),
        ));
      }
      i = j;
    }
    return Text.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(color: Palette.text, fontSize: 15, height: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = verdictColor(a.verdict);
    final warning = 'Scam warning: I checked this message with ScamShield and it '
        'looks like "${a.type}". Do not reply, tap links or send money.\n\n'
        '"$text"';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: color.withOpacity(0.6),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: a.score / 100),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => CustomPaint(
                        size: const Size(112, 112),
                        painter: RingPainter(v, color, thickness: 10),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${a.score}',
                            style: TextStyle(
                                color: color,
                                fontSize: 30,
                                fontWeight: FontWeight.w800)),
                        const Text('RISK',
                            style: TextStyle(
                                color: Palette.dim,
                                fontSize: 9,
                                letterSpacing: 2)),
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
                        Icon(verdictIcon(a.verdict), color: color, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(verdictLabel(a.verdict),
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  fontSize: 15)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.verdict == Verdict.safe
                          ? 'No common scam signs found.'
                          : 'Type: ${a.type}',
                      style: const TextStyle(color: Palette.text, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(channelIcon(a.channel), size: 13, color: Palette.dim),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sender.isEmpty
                                ? channelLabel(a.channel)
                                : '${channelLabel(a.channel)} • $sender',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Palette.dim, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('THE MESSAGE, WITH WARNING SIGNS MARKED',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        GlassCard(child: _highlighted()),
        if (a.reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('WHY WE FLAGGED THIS',
              style:
                  TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 8),
          for (final r in a.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: r.weight >= 0.4 ? Palette.red : Palette.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(r.detail,
                              style: const TextStyle(
                                  color: Palette.dim, fontSize: 13, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (a.links.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('LINKS FOUND',
              style:
                  TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 8),
          for (final l in a.links)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                borderColor: l.risk > 0 ? Palette.red.withOpacity(0.5) : null,
                child: Row(
                  children: [
                    Icon(l.risk > 0 ? Icons.link_off : Icons.link,
                        color: l.risk > 0 ? Palette.red : Palette.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.domain,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontFamily: 'monospace',
                                  fontSize: 13)),
                          Text(
                            l.flags.isEmpty
                                ? 'No obvious problems, but never enter your PIN on a website you reached from a message.'
                                : l.flags.join('. '),
                            style: const TextStyle(
                                color: Palette.dim, fontSize: 12, height: 1.3),
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
        const Text('WHAT TO DO',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              for (int i = 0; i < a.advice.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Palette.cyan),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Palette.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(a.advice[i],
                            style: const TextStyle(
                                color: Palette.text, height: 1.4)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (a.verdict != Verdict.safe) ...[
          const SizedBox(height: 14),
          GlowButton(
            label: 'COPY WARNING TO SHARE',
            icon: Icons.ios_share,
            onTap: () {
              Clipboard.setData(ClipboardData(text: warning));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Warning copied. Paste it into WhatsApp to protect others.'),
              ));
            },
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Thank you. In the full app this is reported to protect others (simulated).'),
            )),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Palette.red.withOpacity(0.7)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_gmailerrorred, color: Palette.red, size: 20),
                  SizedBox(width: 8),
                  Text('REPORT AS SCAM',
                      style: TextStyle(
                          color: Palette.red,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
