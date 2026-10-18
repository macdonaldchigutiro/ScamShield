import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class _Check {
  final String id, group, title, why;
  final List<String> how;
  const _Check(this.id, this.group, this.title, this.why, this.how);
}

const _checks = [
  _Check('2sv', 'WHATSAPP AND SOCIAL MEDIA', 'Two-step verification is ON',
      'Even if a criminal gets your code, they cannot take over without your PIN.',
      [
        'Open WhatsApp.',
        'Go to Settings, then Account, then Two-step verification (menu names can change slightly).',
        'Turn it on and choose a 6-digit PIN only you know.',
        'Add an email so you can reset the PIN if you forget it.',
      ]),
  _Check('passkey', 'WHATSAPP AND SOCIAL MEDIA', 'Passkey or fingerprint login, where offered',
      'It is much harder to steal than a code sent by SMS.',
      [
        'Look in Settings, then Account, for passkeys.',
        'Follow the steps to use your fingerprint or face unlock.',
      ]),
  _Check('linked', 'WHATSAPP AND SOCIAL MEDIA', 'I checked my linked devices',
      'It shows everywhere your account is open. A stranger may be watching.',
      [
        'Open Settings, then Linked devices.',
        'Log out of any device you do not recognise.',
      ]),
  _Check('privacy', 'WHATSAPP AND SOCIAL MEDIA', 'My photo and last seen are for contacts only',
      'Scammers copy your photo and name to pretend to be you.',
      [
        'Open Settings, then Privacy.',
        'Set Profile photo, About and Last seen to My contacts.',
      ]),
  _Check('other2sv', 'WHATSAPP AND SOCIAL MEDIA', 'Same protection on Facebook, Google and X',
      'The same code trick works on all of them.',
      [
        'Open each app and find Security settings.',
        'Turn on two-step verification, ideally with an authenticator app instead of SMS.',
      ]),
  _Check('pin', 'MOBILE MONEY AND SIM', 'My mobile money PIN is not a birthday or 1234',
      'Easy PINs are guessed or seen over your shoulder.',
      [
        'Change it through your provider\'s official app or menu.',
        'Use something only you know. Never your birthday or phone number.',
        'Never write it on your phone or card.',
      ]),
  _Check('simid', 'MOBILE MONEY AND SIM', 'My ID details are kept private',
      'Criminals use your ID details to get a replacement SIM in your name.',
      [
        'Do not send photos of your ID to strangers.',
        'Ask your provider what extra protection they offer against SIM replacement.',
      ]),
  _Check('line', 'MOBILE MONEY AND SIM', 'I have my provider\'s official customer line saved',
      'If something goes wrong, minutes matter.',
      [
        'Find it on the provider\'s website, app or SIM pack.',
        'Save it in your phone as "Provider, official".',
        'Never use a number from a message.',
      ]),
  _Check('mail2sv', 'EMAIL AND PASSWORDS', 'My email has two-step verification',
      'Your email can reset all your other accounts, so guard it first.',
      [
        'Open your email account\'s Security settings.',
        'Turn on two-step verification.',
      ]),
  _Check('unique', 'EMAIL AND PASSWORDS', 'Important accounts have different passwords',
      'One stolen password should not open everything.',
      [
        'Use a long password you can remember, like four random words.',
        'Never reuse your email password anywhere else.',
      ]),
  _Check('recovery', 'EMAIL AND PASSWORDS', 'My recovery email and phone number are up to date',
      'You need them to get back in if you are locked out.',
      [
        'Check the recovery options in each important account.',
        'Remove old numbers and emails you no longer use.',
      ]),
  _Check('family', 'FAMILY AND FRIENDS', 'My family knows: never share a code',
      'Scammers target parents and grandparents, and people who are less used to apps.',
      [
        'Tell them: a 6-digit code is only ever for you.',
        'Show them the Check tab in this app.',
      ]),
  _Check('safeword', 'FAMILY AND FRIENDS', 'We have a family safe word',
      'If "you" ask for money, the safe word proves it is really you.',
      [
        'Pick a word only your family knows.',
        'Ask for it before sending money or codes to anyone who messages you.',
      ]),
  _Check('callfirst', 'FAMILY AND FRIENDS', 'I always call before sending money to a "friend"',
      'A hacked account can look exactly like your friend.',
      [
        'Call them on their number, not by message.',
        'Ask something only they would know.',
      ]),
];

class _Step {
  final String title, body;
  final bool stop;
  const _Step(this.title, this.body, [this.stop = false]);
}

const _chain = [
  _Step('A message arrives',
      'A "friend" says they sent you a code by mistake, or a link offers free airtime, a vote or a video.'),
  _Step('You share the code or log in',
      'You send the 6-digit code, or type your details on a fake page.', true),
  _Step('They take over your number',
      'The criminal registers your number on their own phone. Your account is now theirs.'),
  _Step('Your contacts are targeted',
      'Messages go out as you, asking for money or codes. Business accounts can be used to ask customers to pay.'),
  _Step('The damage spreads',
      'More accounts fall and money is lost. A SIM swap can help criminals do this even faster.'),
];

class ProtectScreen extends StatefulWidget {
  const ProtectScreen({super.key});

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends State<ProtectScreen> {
  final Set<String> _done = {};

  @override
  Widget build(BuildContext context) {
    final pct = _done.length / _checks.length;
    final color = pct >= 0.8 ? Palette.green : (pct >= 0.5 ? Palette.amber : Palette.red);
    final label = pct >= 0.8 ? 'STRONG' : (pct >= 0.5 ? 'FAIR' : 'AT RISK');
    final groups = <String>[];
    for (final c in _checks) {
      if (!groups.contains(c.group)) groups.add(c.group);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('PROTECT YOURSELF',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Most hacks start with one scam message. These steps make you much harder to trick or take over.',
            style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.35)),
        const SizedBox(height: 12),
        GlassCard(
          borderColor: color.withOpacity(0.5),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, v, _) => CustomPaint(
                        size: const Size(120, 120),
                        painter: RingPainter(v, color),
                      ),
                    ),
                    Text('${(pct * 100).round()}%',
                        style: TextStyle(
                            color: color, fontSize: 28, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR PROTECTION',
                        style: TextStyle(
                            color: Palette.dim, fontSize: 10, letterSpacing: 2)),
                    Text(label,
                        style: TextStyle(
                            color: color, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${_done.length} of ${_checks.length} steps done',
                        style: const TextStyle(color: Palette.text, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('HOW A TAKEOVER HAPPENS',
            style: TextStyle(color: Palette.red, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            children: [
              for (int i = 0; i < _chain.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            if (i < _chain.length - 1)
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                      width: 2,
                                      color: Palette.red.withOpacity(0.35)),
                                ),
                              ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1A0A18),
                                border: Border.all(
                                    color: _chain[i].stop ? Palette.amber : Palette.red,
                                    width: 2),
                              ),
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      color: _chain[i].stop
                                          ? Palette.amber
                                          : Palette.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_chain[i].title,
                                  style: const TextStyle(
                                      color: Palette.text,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(_chain[i].body,
                                  style: const TextStyle(
                                      color: Palette.dim, fontSize: 12.5, height: 1.35)),
                              if (_chain[i].stop) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Palette.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Palette.amber),
                                  ),
                                  child: const Text('STOP HERE: a code is only for you',
                                      style: TextStyle(
                                          color: Palette.amber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        for (final g in groups) ...[
          const SizedBox(height: 14),
          Text(g,
              style: const TextStyle(
                  color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 8),
          for (final c in _checks.where((x) => x.group == g))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: EdgeInsets.zero,
                borderColor: _done.contains(c.id) ? Palette.green.withOpacity(0.5) : null,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: Palette.cyan,
                    collapsedIconColor: Palette.dim,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(52, 0, 14, 14),
                    leading: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (!_done.add(c.id)) _done.remove(c.id);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _done.contains(c.id) ? Palette.green : Colors.transparent,
                          border: Border.all(
                              color: _done.contains(c.id) ? Palette.green : Palette.dim,
                              width: 2),
                        ),
                        child: _done.contains(c.id)
                            ? const Icon(Icons.check, size: 18, color: Palette.bg)
                            : null,
                      ),
                    ),
                    title: Text(c.title,
                        style: const TextStyle(
                            color: Palette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    subtitle: Text(c.why,
                        style: const TextStyle(
                            color: Palette.dim, fontSize: 12, height: 1.3)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('HOW',
                                style: TextStyle(
                                    color: Palette.green,
                                    letterSpacing: 2,
                                    fontSize: 10)),
                            for (int i = 0; i < c.how.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${i + 1}.  ${c.how[i]}',
                                    style: const TextStyle(
                                        color: Palette.text, fontSize: 13, height: 1.35)),
                              ),
                          ],
                        ),
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
