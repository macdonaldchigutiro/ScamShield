import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../controllers/protection_controller.dart';

class _ProtectionStep {
  final String id;
  final String group;
  final String title;
  final String why;
  final List<String> how;

  const _ProtectionStep({
    required this.id,
    required this.group,
    required this.title,
    required this.why,
    required this.how,
  });
}

const _steps = <_ProtectionStep>[
  _ProtectionStep(id: '2sv', group: 'WHATSAPP', title: 'Two-step verification is on', why: 'Adds a PIN that makes account takeover harder.', how: ['WhatsApp → Settings → Account → Two-step verification.', 'Turn it on and choose a PIN only you know.', 'Add a recovery email.']),
  _ProtectionStep(id: 'passkey', group: 'WHATSAPP', title: 'Passkey or biometric login is enabled', why: 'A fingerprint, face or passkey is harder to steal than an SMS code.', how: ['Open WhatsApp account/security settings.', 'Enable passkeys or biometric protection where available.']),
  _ProtectionStep(id: 'linked', group: 'WHATSAPP', title: 'I checked linked devices', why: 'Unknown linked devices may be reading your messages.', how: ['WhatsApp → Linked devices.', 'Log out anything you do not recognise.']),
  _ProtectionStep(id: 'privacy', group: 'WHATSAPP', title: 'Profile details are limited to contacts', why: 'Public photos and details make impersonation easier.', how: ['WhatsApp → Settings → Privacy.', 'Limit profile photo, About and Last seen to contacts.']),
  _ProtectionStep(id: 'other2sv', group: 'ACCOUNTS', title: 'Important social accounts use 2-step verification', why: 'One stolen password should not give a scammer your social identity.', how: ['Open the security settings for Google, Facebook, X and other important accounts.', 'Turn on 2-step verification, preferably with an authenticator or passkey.']),
  _ProtectionStep(id: 'pin', group: 'MONEY & SIM', title: 'My mobile-money PIN is strong and private', why: 'Birthdays, 1234 and phone-number PINs are easy to guess.', how: ['Change weak PINs using the provider’s official app or menu.', 'Never share the PIN or store it in a note on the phone.']),
  _ProtectionStep(id: 'simid', group: 'MONEY & SIM', title: 'I keep SIM/ID details private', why: 'Identity details can be abused during SIM-swap attempts.', how: ['Do not send ID photos to strangers.', 'Ask your network what extra SIM-swap protection they offer.']),
  _ProtectionStep(id: 'line', group: 'MONEY & SIM', title: 'I saved my provider’s official support number', why: 'If money or a SIM is compromised, minutes matter.', how: ['Get the number from the official website, app or SIM pack.', 'Save it clearly as an official provider contact.']),
  _ProtectionStep(id: 'mail2sv', group: 'EMAIL & PASSWORDS', title: 'My email has 2-step verification', why: 'Email can reset most of your other accounts.', how: ['Open your email account Security settings.', 'Turn on 2-step verification or a passkey.']),
  _ProtectionStep(id: 'unique', group: 'EMAIL & PASSWORDS', title: 'Important accounts use different passwords', why: 'One stolen password should not unlock everything.', how: ['Use a unique password for email, banking and social accounts.', 'A password manager can help.']),
  _ProtectionStep(id: 'recovery', group: 'EMAIL & PASSWORDS', title: 'Recovery email and phone are up to date', why: 'Correct recovery details help you regain control quickly.', how: ['Review recovery settings on important accounts.', 'Remove old phone numbers and email addresses.']),
  _ProtectionStep(id: 'family', group: 'FAMILY', title: 'My family knows never to share a login code', why: 'Scammers often pressure relatives who are less familiar with account-security tricks.', how: ['Explain that a 6-digit login code is private.', 'Show them ScamShield’s Check and Help sections.']),
  _ProtectionStep(id: 'safeword', group: 'FAMILY', title: 'We have a family safe word', why: 'A safe word can expose “new number” and emergency impersonation scams.', how: ['Choose a word only close family know.', 'Ask for it before sending urgent money to someone claiming to be family.']),
  _ProtectionStep(id: 'callfirst', group: 'FAMILY', title: 'I call before sending unexpected money', why: 'A hacked account can look exactly like the person you know.', how: ['Call the person using a number you already trust.', 'Do not rely on the same chat that requested the money.']),
];

class ProtectionScreen extends ConsumerWidget {
  const ProtectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(protectionControllerProvider);
    final completed = state.completedStepIds;
    final pct = state.progress;
    final color = pct >= .8 ? Palette.green : pct >= .5 ? Palette.amber : Palette.red;
    final label = pct >= .8 ? 'STRONG' : pct >= .5 ? 'BUILDING' : 'NEEDS ATTENTION';
    final groups = _steps.map((step) => step.group).toSet().toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const Text('YOUR PROTECTION', style: TextStyle(color: Palette.cyan, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 5),
        const Text('This score comes only from the safety steps you confirm below. ScamShield does not guess settings it cannot verify.', style: TextStyle(color: Palette.dim, fontSize: 13, height: 1.45)),
        const SizedBox(height: 14),
        GlassCard(
          borderColor: color.withOpacity(.45),
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: Palette.cyan))
              : Row(
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(size: const Size.square(112), painter: RingPainter(pct, color)),
                          Text('${state.percentage}%', style: TextStyle(color: color, fontSize: 27, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text('${state.completedCount} of ${state.totalCount} safety steps completed', style: const TextStyle(color: Palette.text, fontSize: 13)),
                        const SizedBox(height: 7),
                        Text(state.completedCount == state.totalCount ? 'Excellent — keep these settings maintained.' : '${state.totalCount - state.completedCount} actions can still strengthen your protection.', style: const TextStyle(color: Palette.dim, fontSize: 11.5, height: 1.35)),
                      ]),
                    ),
                  ],
                ),
        ),
        for (final group in groups) ...[
          const SizedBox(height: 18),
          Text(group, style: const TextStyle(color: Palette.cyan, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
          const SizedBox(height: 8),
          for (final step in _steps.where((item) => item.group == group))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: EdgeInsets.zero,
                borderColor: completed.contains(step.id) ? Palette.green.withOpacity(.45) : null,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: Palette.cyan,
                    collapsedIconColor: Palette.dim,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    childrenPadding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
                    leading: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(protectionControllerProvider.notifier).toggle(step.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: completed.contains(step.id) ? Palette.green : Colors.transparent,
                          border: Border.all(color: completed.contains(step.id) ? Palette.green : Palette.dim, width: 2),
                        ),
                        child: completed.contains(step.id) ? const Icon(Icons.check_rounded, color: Palette.bg, size: 18) : null,
                      ),
                    ),
                    title: Text(step.title, style: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(step.why, style: const TextStyle(color: Palette.dim, fontSize: 12.5, height: 1.35))),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('HOW TO DO IT', style: TextStyle(color: Palette.green, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          const SizedBox(height: 5),
                          for (var i = 0; i < step.how.length; i++) Padding(padding: const EdgeInsets.only(top: 5), child: Text('${i + 1}. ${step.how[i]}', style: const TextStyle(color: Palette.text, fontSize: 13, height: 1.4))),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
