import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../../domain/entities/scam_investigation.dart';
import '../controllers/scam_investigator_controller.dart';

/// Analyst-style phishing investigation that still fits the consumer product.
///
/// The screen parses common mail headers locally, surfaces explainable header
/// mismatches and URLs, then sends the complete pasted email through the same
/// ScamShield investigation pipeline used by ordinary message checks.
class PhishingInvestigatorScreen extends ConsumerStatefulWidget {
  const PhishingInvestigatorScreen({super.key});

  @override
  ConsumerState<PhishingInvestigatorScreen> createState() =>
      _PhishingInvestigatorScreenState();
}

class _PhishingInvestigatorScreenState
    extends ConsumerState<PhishingInvestigatorScreen> {
  final _controller = TextEditingController();
  _ParsedEmail? _parsed;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    setState(() => _parsed = _ParsedEmail.parse(raw));
    await ref.read(scamInvestigatorControllerProvider.notifier).investigate(
          content: raw,
          inputType: InvestigationInputType.message,
          channel: InvestigationChannel.email,
          sender: _parsed?.from ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scamInvestigatorControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Text(
          'Phishing investigation',
          style: TextStyle(
            color: Palette.text,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Paste the suspicious email, including headers if available. ScamShield checks sender relationships, URLs and scam wording locally first.',
          style: TextStyle(color: Palette.dim, height: 1.45),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EMAIL / HEADERS',
                style: TextStyle(
                  color: Palette.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 9,
                maxLines: 18,
                style: const TextStyle(color: Palette.text, height: 1.4),
                decoration: const InputDecoration(
                  hintText:
                      'From: PayPal <security@example.com>\nReply-To: ...\nReturn-Path: ...\nSubject: ...\n\nPaste the message body here...',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isLoading ? null : _analyse,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.policy_outlined),
                label: Text(state.isLoading
                    ? 'INVESTIGATING…'
                    : 'INVESTIGATE EMAIL'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Palette.cyan,
                  foregroundColor: Palette.bg,
                ),
              ),
            ],
          ),
        ),
        if (_parsed != null) ...[
          const SizedBox(height: 16),
          _HeaderAnalysis(parsed: _parsed!),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(state.errorMessage!, style: const TextStyle(color: Palette.red)),
        ],
        if (state.result != null) ...[
          const SizedBox(height: 16),
          _ScamResult(result: state.result!),
        ],
      ],
    );
  }
}

class _HeaderAnalysis extends StatelessWidget {
  final _ParsedEmail parsed;
  const _HeaderAnalysis({required this.parsed});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEADER & LINK FINDINGS',
            style: TextStyle(
              color: Palette.violet,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _field('From', parsed.from),
          _field('Reply-To', parsed.replyTo),
          _field('Return-Path', parsed.returnPath),
          _field('Subject', parsed.subject),
          const SizedBox(height: 10),
          if (parsed.findings.isEmpty)
            const Text(
              'No obvious header mismatch was found. This does not prove the email is genuine.',
              style: TextStyle(color: Palette.dim, height: 1.4),
            )
          else
            for (final finding in parsed.findings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Palette.amber, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        finding,
                        style: const TextStyle(
                          color: Palette.text,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (parsed.urls.isNotEmpty) ...[
            const Divider(height: 22),
            Text(
              '${parsed.urls.length} URL${parsed.urls.length == 1 ? '' : 'S'} EXTRACTED',
              style: const TextStyle(
                color: Palette.cyan,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            for (final url in parsed.urls.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: SelectableText(
                  url,
                  style: const TextStyle(color: Palette.dim, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, height: 1.35),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Palette.dim,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value, style: const TextStyle(color: Palette.text)),
          ],
        ),
      ),
    );
  }
}

class _ScamResult extends StatelessWidget {
  final ScamInvestigation result;
  const _ScamResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = switch (result.verdict) {
      InvestigationVerdict.highRisk => Palette.red,
      InvestigationVerdict.suspicious => Palette.amber,
      InvestigationVerdict.lowRisk => Palette.green,
    };

    return GlassCard(
      borderColor: color.withOpacity(.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${result.riskScore}',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.verdict.name.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.summary,
                      style: const TextStyle(color: Palette.text, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.reasons.isNotEmpty) ...[
            const Divider(height: 24),
            for (final reason in result.reasons.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '• ${reason.title}: ${reason.explanation}',
                  style: const TextStyle(
                    color: Palette.dim,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ParsedEmail {
  final String from;
  final String replyTo;
  final String returnPath;
  final String subject;
  final List<String> urls;
  final List<String> findings;

  const _ParsedEmail({
    required this.from,
    required this.replyTo,
    required this.returnPath,
    required this.subject,
    required this.urls,
    required this.findings,
  });

  factory _ParsedEmail.parse(String raw) {
    String header(String name) {
      final match = RegExp('^${RegExp.escape(name)}:\\s*(.+)\$',
              caseSensitive: false, multiLine: true)
          .firstMatch(raw);
      return match?.group(1)?.trim() ?? '';
    }

    String domainOf(String value) {
      final email = RegExp(r'[A-Z0-9._%+-]+@([A-Z0-9.-]+\.[A-Z]{2,})',
              caseSensitive: false)
          .firstMatch(value);
      return email?.group(1)?.toLowerCase() ?? '';
    }

    final from = header('From');
    final replyTo = header('Reply-To');
    final returnPath = header('Return-Path');
    final subject = header('Subject');
    final fromDomain = domainOf(from);
    final replyDomain = domainOf(replyTo);
    final returnDomain = domainOf(returnPath);
    final findings = <String>[];

    if (fromDomain.isNotEmpty &&
        replyDomain.isNotEmpty &&
        fromDomain != replyDomain) {
      findings.add(
          'Reply-To domain ($replyDomain) differs from the visible From domain ($fromDomain).');
    }
    if (fromDomain.isNotEmpty &&
        returnDomain.isNotEmpty &&
        fromDomain != returnDomain) {
      findings.add(
          'Return-Path domain ($returnDomain) differs from the visible From domain ($fromDomain).');
    }
    if (from.isNotEmpty && fromDomain.isEmpty) {
      findings.add('The From header does not contain a normal email address.');
    }

    final urls = RegExp(r'https?://[^\s<>"\']+', caseSensitive: false)
        .allMatches(raw)
        .map((match) => match.group(0)!)
        .toSet()
        .toList();

    return _ParsedEmail(
      from: from,
      replyTo: replyTo,
      returnPath: returnPath,
      subject: subject,
      urls: urls,
      findings: findings,
    );
  }
}
