import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/incidents/presentation/controllers/incident_controller.dart';
import 'theme.dart';

enum _IncidentType {
  sentMoney,
  sharedCode,
  whatsappTaken,
  clickedLink,
  sharedDetails,
  notSure,
}

enum _Urgency { now, today, soon }

class _RecoveryStep {
  final String id;
  final _Urgency urgency;
  final String title;
  final String detail;

  const _RecoveryStep(this.id, this.urgency, this.title, this.detail);
}

class _IncidentChoice {
  final _IncidentType type;
  final IconData icon;
  final String title;
  final String subtitle;

  const _IncidentChoice(this.type, this.icon, this.title, this.subtitle);
}

const _choices = <_IncidentChoice>[
  _IncidentChoice(
    _IncidentType.sentMoney,
    Icons.payments_outlined,
    'I sent money',
    'Mobile money, bank transfer or cash to a scammer',
  ),
  _IncidentChoice(
    _IncidentType.sharedCode,
    Icons.password_outlined,
    'I shared a code or PIN',
    'WhatsApp code, OTP, mobile money or bank PIN',
  ),
  _IncidentChoice(
    _IncidentType.whatsappTaken,
    Icons.chat_outlined,
    'My WhatsApp was taken over',
    'I am locked out, or people got strange messages from me',
  ),
  _IncidentChoice(
    _IncidentType.clickedLink,
    Icons.link_rounded,
    'I clicked a link or installed an app',
    'I may have typed details into a fake page',
  ),
  _IncidentChoice(
    _IncidentType.sharedDetails,
    Icons.badge_outlined,
    'I shared personal or bank details',
    'ID, card number, account details or documents',
  ),
  _IncidentChoice(
    _IncidentType.notSure,
    Icons.help_outline_rounded,
    'I am not sure what happened',
    'Something feels wrong and I want to be safe',
  ),
];

const _plans = <_IncidentType, List<_RecoveryStep>>{
  _IncidentType.sentMoney: [
    _RecoveryStep(
      'call_provider',
      _Urgency.now,
      'Call your mobile money provider or bank now',
      'Use the official app, the number on your bank card, or the provider\'s official website. Do not use a number from the scam message. Ask them to flag or freeze the transaction. Speed matters.',
    ),
    _RecoveryStep(
      'stop_paying',
      _Urgency.now,
      'Stop sending any more money',
      'Scammers often ask for one more payment to release or recover your money. Do not pay anything else.',
    ),
    _RecoveryStep(
      'screenshots',
      _Urgency.now,
      'Save screenshots and receipts',
      'Keep the chat, the scammer\'s number, the payment confirmation and any receipts. Do not delete the conversation yet.',
    ),
    _RecoveryStep(
      'police',
      _Urgency.today,
      'Report to the police and get a report number',
      'Take your screenshots, transaction reference and the ScamShield incident report.',
    ),
    _RecoveryStep(
      'block',
      _Urgency.today,
      'Block and report the scammer',
      'Do this after you have saved your evidence.',
    ),
    _RecoveryStep(
      'warn_others',
      _Urgency.soon,
      'Warn people close to you',
      'The same scammer may target your family, friends or savings group.',
    ),
  ],
  _IncidentType.sharedCode: [
    _RecoveryStep(
      'change_pin',
      _Urgency.now,
      'Change your PIN or password straight away',
      'Use the official app or official menu, not a link. Change it anywhere else you reused it.',
    ),
    _RecoveryStep(
      'call_provider',
      _Urgency.now,
      'Call your provider or bank',
      'Tell them you shared a code or PIN and ask them to check for unauthorised activity.',
    ),
    _RecoveryStep(
      'wa_reregister',
      _Urgency.now,
      'If it was WhatsApp, register your number again',
      'Open WhatsApp, enter your number and the new code sent to you. Never share that code.',
    ),
    _RecoveryStep(
      'check_transactions',
      _Urgency.today,
      'Check recent transactions',
      'Report every payment or transfer you do not recognise.',
    ),
    _RecoveryStep(
      'logout_devices',
      _Urgency.today,
      'Log out of unknown devices and sessions',
      'Use each account\'s security settings to remove devices you do not recognise.',
    ),
    _RecoveryStep(
      'two_step',
      _Urgency.soon,
      'Turn on two-step verification everywhere',
      'Start with WhatsApp, email, banking and mobile money.',
    ),
  ],
  _IncidentType.whatsappTaken: [
    _RecoveryStep(
      'wa_reregister',
      _Urgency.now,
      'Register WhatsApp with your number again',
      'Enter your number and the SMS code sent to you. This usually logs the other person out.',
    ),
    _RecoveryStep(
      'warn_contacts',
      _Urgency.now,
      'Warn your contacts another way',
      'Call or text them and say not to send money or codes if they get messages from your number.',
    ),
    _RecoveryStep(
      'wa_two_step',
      _Urgency.now,
      'Turn on WhatsApp two-step verification',
      'Settings > Account > Two-step verification. Choose a PIN nobody can guess.',
    ),
    _RecoveryStep(
      'linked_devices',
      _Urgency.today,
      'Check linked devices',
      'Log out any device you do not recognise.',
    ),
    _RecoveryStep(
      'locked_out',
      _Urgency.today,
      'Still locked out? Use official WhatsApp help',
      'If SMS codes do not arrive, contact your mobile network because your SIM may have been swapped.',
    ),
    _RecoveryStep(
      'other_accounts',
      _Urgency.soon,
      'Secure email and social media too',
      'Change passwords and enable two-step verification on connected accounts.',
    ),
  ],
  _IncidentType.clickedLink: [
    _RecoveryStep(
      'stop_typing',
      _Urgency.now,
      'Close the page and enter nothing else',
      'Do not type any more details and do not install anything else from the link.',
    ),
    _RecoveryStep(
      'uninstall',
      _Urgency.now,
      'Remove any app installed from the link',
      'Delete anything you did not get from the official app store.',
    ),
    _RecoveryStep(
      'change_passwords',
      _Urgency.now,
      'Change passwords for anything you entered',
      'Use a different trusted device if possible.',
    ),
    _RecoveryStep(
      'scan',
      _Urgency.today,
      'Run your device security scan',
      'On Android, use Google Play Protect or another trusted security tool.',
    ),
    _RecoveryStep(
      'check_accounts',
      _Urgency.today,
      'Check bank and mobile money activity',
      'Report transactions you do not recognise immediately.',
    ),
    _RecoveryStep(
      'expect_followups',
      _Urgency.soon,
      'Expect follow-up scams',
      'Anyone calling to “help” may be part of the same scam. Use official numbers only.',
    ),
  ],
  _IncidentType.sharedDetails: [
    _RecoveryStep(
      'call_bank',
      _Urgency.now,
      'Call your bank if you shared card or account details',
      'Ask them to block or secure the affected card/account and tell you what to do next.',
    ),
    _RecoveryStep(
      'change_pins',
      _Urgency.now,
      'Change affected PINs and passwords',
      'Start with banking and mobile money, then email.',
    ),
    _RecoveryStep(
      'watch_sim',
      _Urgency.today,
      'Watch your phone signal',
      'Unexpected loss of signal can indicate a SIM swap. Contact your network immediately.',
    ),
    _RecoveryStep(
      'watch_accounts',
      _Urgency.today,
      'Check accounts for unfamiliar activity',
      'Look for transactions, new devices or password resets you did not make.',
    ),
    _RecoveryStep(
      'police_id',
      _Urgency.soon,
      'Report if identity documents were shared',
      'Keep a record of exactly what you shared and when.',
    ),
  ],
  _IncidentType.notSure: [
    _RecoveryStep(
      'stop_talking',
      _Urgency.now,
      'Stop replying to the sender',
      'Do not send money, codes or personal details while you work out what happened.',
    ),
    _RecoveryStep(
      'screenshots',
      _Urgency.now,
      'Save the evidence',
      'Screenshot the messages and the sender\'s number or account.',
    ),
    _RecoveryStep(
      'check_accounts',
      _Urgency.today,
      'Check your accounts for anything unusual',
      'Review mobile money, bank, email and WhatsApp linked devices.',
    ),
    _RecoveryStep(
      'use_checker',
      _Urgency.today,
      'Run the message through ScamShield',
      'Use the Check tab to see exactly what looks suspicious.',
    ),
    _RecoveryStep(
      'two_step',
      _Urgency.soon,
      'Turn on two-step verification',
      'Start with WhatsApp, email and financial accounts.',
    ),
  ],
};

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  _IncidentType? _selectedType;
  final Set<String> _done = <String>{};
  final _whenController = TextEditingController();
  final _amountController = TextEditingController();
  final _scammerController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _whenController.dispose();
    _amountController.dispose();
    _scammerController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<_RecoveryStep> get _steps => _plans[_selectedType] ?? const [];

  _IncidentChoice get _selectedChoice =>
      _choices.firstWhere((item) => item.type == _selectedType);

  void _resetChoice() {
    setState(() {
      _selectedType = null;
      _done.clear();
    });
  }

  String _value(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? 'Not provided' : value;
  }

  String _buildSummary() {
    final doneSteps = _steps.where((step) => _done.contains(step.id)).toList();
    final todoSteps = _steps.where((step) => !_done.contains(step.id)).toList();
    final buffer = StringBuffer()
      ..writeln('SCAM INCIDENT SUMMARY')
      ..writeln('What happened: ${_selectedChoice.title}')
      ..writeln('When it happened: ${_value(_whenController)}')
      ..writeln('Amount lost: ${_value(_amountController)}')
      ..writeln('Scammer name / number / account: ${_value(_scammerController)}')
      ..writeln('Transaction reference: ${_value(_referenceController)}')
      ..writeln('Notes: ${_value(_notesController)}')
      ..writeln()
      ..writeln('Steps completed:');

    if (doneSteps.isEmpty) buffer.writeln('- None yet');
    for (final step in doneSteps) {
      buffer.writeln('- ${step.title}');
    }

    buffer
      ..writeln()
      ..writeln('Steps still to do:');
    if (todoSteps.isEmpty) buffer.writeln('- None');
    for (final step in todoSteps) {
      buffer.writeln('- ${step.title}');
    }
    return buffer.toString();
  }

  double? _parseAmount() {
    final cleaned = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return cleaned.isEmpty ? null : double.tryParse(cleaned);
  }

  Future<void> _copySummary() async {
    await Clipboard.setData(ClipboardData(text: _buildSummary()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report summary copied.')),
    );
  }

  Future<void> _saveToLocker() async {
    if (_saving || _selectedType == null) return;
    setState(() => _saving = true);
    try {
      final incident = await ref
          .read(incidentControllerProvider.notifier)
          .saveRecoveryIncident(
            category: _selectedChoice.title,
            summary: _buildSummary(),
            recommendedActions: _steps.map((step) => step.title).toList(),
            sender: _scammerController.text,
            notes: _notesController.text,
            amount: _parseAmount(),
            transactionReference: _referenceController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Evidence Locker as ${incident.id}.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _selectedType == null ? _buildPicker() : _buildPlan(),
    );
  }

  Widget _buildPicker() {
    return ListView(
      key: const ValueKey('recovery-picker'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        const Text(
          'What happened?',
          style: TextStyle(
            color: Palette.text,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the closest situation. ScamShield will put the most urgent actions first.',
          style: TextStyle(color: Palette.dim, fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 18),
        for (final choice in _choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _selectedType = choice.type),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 82),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Palette.red.withOpacity(.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(choice.icon, color: Palette.red, size: 27),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.title,
                              style: const TextStyle(
                                color: Palette.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              choice.subtitle,
                              style: const TextStyle(
                                color: Palette.dim,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Palette.dim),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlan() {
    final total = _steps.length;
    final doneCount = _steps.where((step) => _done.contains(step.id)).length;

    return ListView(
      key: const ValueKey('recovery-plan'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _resetChoice,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Change what happened'),
            ),
          ],
        ),
        Text(
          _selectedChoice.title,
          style: const TextStyle(
            color: Palette.text,
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$doneCount of $total steps done. Work from the top.',
          style: const TextStyle(color: Palette.dim, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : doneCount / total,
            minHeight: 8,
            color: Palette.green,
            backgroundColor: Palette.line,
          ),
        ),
        const SizedBox(height: 16),
        _recoveryScamWarning(),
        for (final urgency in _Urgency.values) ..._buildUrgencySection(urgency),
        const SizedBox(height: 22),
        _detailsCard(),
        const SizedBox(height: 18),
        _contactCard(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _copySummary,
              icon: const Icon(Icons.copy_rounded, size: 19),
              label: const Text('Copy report summary'),
            ),
            OutlinedButton.icon(
              onPressed: _saving ? null : _saveToLocker,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory_2_outlined, size: 19),
              label: Text(_saving ? 'Saving…' : 'Save to Evidence Locker'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'After saving, open Evidence Locker to review the case and download the PDF incident report.',
          style: TextStyle(color: Palette.dim, fontSize: 12.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _recoveryScamWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.amber.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.amber.withOpacity(.55)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Palette.amber),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Never pay anyone who offers to get your money back. Recovery scams often target people immediately after the first scam.',
              style: TextStyle(
                color: Palette.text,
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUrgencySection(_Urgency urgency) {
    final steps = _steps.where((step) => step.urgency == urgency).toList();
    if (steps.isEmpty) return const [];

    late final String label;
    late final Color color;
    switch (urgency) {
      case _Urgency.now:
        label = 'DO NOW — NEXT 15 MINUTES';
        color = Palette.red;
      case _Urgency.today:
        label = 'DO TODAY';
        color = Palette.amber;
      case _Urgency.soon:
        label = 'IN THE NEXT FEW DAYS';
        color = Palette.cyan;
    }

    return [
      const SizedBox(height: 18),
      Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final step in steps) _stepTile(step, color),
    ];
  }

  Widget _stepTile(_RecoveryStep step, Color accent) {
    final done = _done.contains(step.id);
    return Semantics(
      checked: done,
      label: step.title,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border(
            left: BorderSide(color: done ? Palette.green : accent, width: 4),
            top: const BorderSide(color: Palette.line),
            right: const BorderSide(color: Palette.line),
            bottom: const BorderSide(color: Palette.line),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => setState(() {
            if (!_done.add(step.id)) _done.remove(step.id);
          }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: done ? Palette.green : Palette.dim,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          color: done ? Palette.dim : Palette.text,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.detail,
                        style: const TextStyle(
                          color: Palette.dim,
                          fontSize: 14.5,
                          height: 1.45,
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

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: lines,
        maxLines: lines == 1 ? 1 : 5,
        style: const TextStyle(color: Palette.text, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Palette.surfaceHi,
          labelStyle: const TextStyle(color: Palette.dim),
        ),
      ),
    );
  }

  Widget _detailsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details to keep',
            style: TextStyle(
              color: Palette.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Banks, providers and police may ask for these. Fill in what you know.',
            style: TextStyle(color: Palette.dim, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 14),
          _field(_whenController, 'When did it happen? (date and time)'),
          _field(
            _amountController,
            'Amount lost (if any)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _field(_scammerController, 'Scammer name, number or account'),
          _field(_referenceController, 'Transaction reference or ID'),
          _field(_notesController, 'Anything else', lines: 3),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who to contact',
            style: TextStyle(
              color: Palette.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use the official number inside your bank or mobile-money app, the number on your bank card, or the provider\'s verified website. Do not call a number sent in the suspicious message. ScamShield will only add one-tap contacts after they have been verified.',
            style: TextStyle(color: Palette.dim, fontSize: 14.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}
