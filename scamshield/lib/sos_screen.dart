import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class _Phase {
  final String name;
  final List<String> steps;
  const _Phase(this.name, this.steps);
}

class _Incident {
  final String title, summary;
  final IconData icon;
  final Color color;
  final List<_Phase> phases;
  final bool warn;
  const _Incident(this.title, this.summary, this.icon, this.color, this.phases,
      {this.warn = false});
}

const _incidents = [
  _Incident(
    'I shared a WhatsApp code',
    'Act fast. The code lets someone register your number on their phone.',
    Icons.password_rounded,
    Palette.red,
    [
      _Phase('RIGHT NOW', [
        'Open WhatsApp. If it asks you to register, ask for a new code to your own number and enter it yourself. This logs the other person out.',
        'Switch on two-step verification (Settings, Account, Two-step verification) and set a PIN only you know.',
        'Check Linked devices and log out any you do not recognise.',
        'Tell your closest contacts, by call or SMS, not to send money or codes if they get messages from you.',
      ]),
      _Phase('TODAY', [
        'Change the passwords of your email and Facebook, and turn on two-step verification there.',
        'Check your mobile money and bank balances for anything you did not do.',
        'Send a warning to your contacts using the button below.',
      ]),
      _Phase('THIS WEEK', [
        'Report it to your mobile provider and to the police. Keep screenshots of the messages.',
        'Beware of "hacker recovery" helpers who ask for money. They are scams.',
      ]),
    ],
    warn: true,
  ),
  _Incident(
    'My WhatsApp was taken over',
    'You may be locked out. Work through these in order.',
    Icons.phonelink_lock,
    Palette.red,
    [
      _Phase('RIGHT NOW', [
        'Try to register your number again. Ask for the SMS code and enter it yourself.',
        'No SMS code or no signal? Your SIM may have been swapped. Call your provider from another phone and ask them to check and block it.',
        'If the other person set a two-step PIN, WhatsApp may make you wait several days. Use the official Contact us option in the app or on the WhatsApp website.',
        'Tell your contacts through another channel (call, SMS or Facebook) not to send money.',
      ]),
      _Phase('TODAY', [
        'Visit your provider\'s shop with your ID if your SIM or line is involved.',
        'Change passwords on email and social media from a safe device.',
        'Check mobile money and bank accounts for anything you did not do.',
      ]),
      _Phase('THIS WEEK', [
        'Report it to the police and keep the report number.',
        'Once you are back in, turn on two-step verification and passkeys.',
        'If it is a business account, tell customers through other channels that payment requests may be fake.',
      ]),
    ],
    warn: true,
  ),
  _Incident(
    'I sent money to a scammer',
    'Speed helps. Getting money back is not guaranteed, but act now.',
    Icons.currency_exchange,
    Palette.amber,
    [
      _Phase('RIGHT NOW', [
        'Call your mobile money provider or bank on their official number straight away.',
        'Give them the time, amount, transaction reference and the number you sent to. Ask them to flag or block that number and try to stop the money.',
        'Do not send any more money, even if someone says it will help you get it back.',
      ]),
      _Phase('TODAY', [
        'Take screenshots of the messages, the scammer\'s number and the transaction.',
        'Report it to the police and ask for a report number.',
        'Block the scammer and change your PIN.',
      ]),
      _Phase('THIS WEEK', [
        'Follow up with your provider using your reference.',
        'Beware of anyone who promises to recover your money for a fee.',
        'Tell family and friends so they are warned.',
      ]),
    ],
  ),
  _Incident(
    'I shared my PIN or password',
    'Change it before anyone uses it.',
    Icons.lock_open_rounded,
    Palette.amber,
    [
      _Phase('RIGHT NOW', [
        'Change the PIN or password using the official app or menu.',
        'Call your provider or bank on their official number and tell them what happened.',
        'Check your recent transactions for anything you did not do.',
      ]),
      _Phase('TODAY', [
        'Change the same password anywhere else you used it.',
        'Ask your provider about limits or alerts on your account.',
      ]),
      _Phase('THIS WEEK', [
        'Watch your accounts closely.',
        'Work through the Protect tab so you are harder to trick next time.',
      ]),
    ],
  ),
  _Incident(
    'My phone lost signal for no reason',
    'This can mean someone took over your SIM. Move quickly.',
    Icons.signal_cellular_connected_no_internet_0_bar,
    Palette.red,
    [
      _Phase('RIGHT NOW', [
        'Use another phone or Wi-Fi to call your provider\'s official line.',
        'Tell them your SIM may have been swapped and ask them to block the new SIM and restore yours.',
        'Call your bank and mobile money provider and ask them to pause your accounts.',
      ]),
      _Phase('TODAY', [
        'Visit the provider\'s shop with your ID.',
        'From a safe device, change passwords for email, Facebook and WhatsApp.',
        'Check all your accounts for anything you did not do.',
      ]),
      _Phase('THIS WEEK', [
        'Report it to the police.',
        'Ask your provider about extra protection on your line.',
      ]),
    ],
    warn: true,
  ),
  _Incident(
    'My Facebook or email was hacked',
    'Do email first. It can reset all your other accounts.',
    Icons.mark_email_unread_outlined,
    Palette.amber,
    [
      _Phase('RIGHT NOW', [
        'On another device, use the official "forgot password" or recovery page for that service.',
        'Change the password and log out all other sessions.',
        'Turn on two-step verification.',
      ]),
      _Phase('TODAY', [
        'Check what the hacker changed: recovery email, phone number, forwarding rules.',
        'Warn your friends not to click links or send money.',
        'Check your bank and mobile money accounts.',
      ]),
      _Phase('THIS WEEK', [
        'Review which apps have access to the account and remove the ones you do not know.',
        'Use a different strong password for each important account.',
      ]),
    ],
    warn: true,
  ),
  _Incident(
    'A friend\'s account sent me something strange',
    'Their account may be hacked. Do not reply yet.',
    Icons.person_search,
    Palette.cyan,
    [
      _Phase('RIGHT NOW', [
        'Do not reply, tap links, send money or share any code.',
        'Call your friend on their phone, not by message, and tell them.',
        'If you already tapped or shared a code, use the plan for that.',
      ]),
      _Phase('TODAY', [
        'Take a screenshot and report the message.',
        'Tell people you both know.',
      ]),
      _Phase('THIS WEEK', [
        'Help your friend work through their recovery plan.',
      ]),
    ],
  ),
  _Incident(
    'I tapped a suspicious link',
    'Stay calm. What you do next matters.',
    Icons.ads_click,
    Palette.cyan,
    [
      _Phase('RIGHT NOW', [
        'Close the page and do not type anything.',
        'If you typed a password or PIN, change it right now.',
        'Turn off mobile data or Wi-Fi if you are unsure.',
      ]),
      _Phase('TODAY', [
        'Check your accounts for anything you did not do.',
        'Update your phone and run its security scan.',
      ]),
      _Phase('THIS WEEK', [
        'Expect more messages from the same sender and ignore them.',
        'Report the link and the message.',
      ]),
    ],
  ),
];

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('GET HELP NOW',
            style: TextStyle(color: Palette.red, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Tap what happened. We will walk you through it step by step. Being tricked can happen to anyone.',
            style: TextStyle(color: Palette.dim, fontSize: 12, height: 1.35)),
        const SizedBox(height: 14),
        for (final inc in _incidents)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _open(context, inc),
              child: GlassCard(
                borderColor: inc.color.withOpacity(0.45),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: inc.color.withOpacity(0.15),
                      ),
                      child: Icon(inc.icon, color: inc.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inc.title,
                              style: const TextStyle(
                                  color: Palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(inc.summary,
                              style: const TextStyle(
                                  color: Palette.dim, fontSize: 12, height: 1.3)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Palette.dim),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _open(BuildContext context, _Incident inc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, controller) => _Plan(inc: inc, controller: controller),
      ),
    );
  }
}

class _Plan extends StatefulWidget {
  final _Incident inc;
  final ScrollController controller;
  const _Plan({required this.inc, required this.controller});

  @override
  State<_Plan> createState() => _PlanState();
}

class _PlanState extends State<_Plan> {
  final Set<String> _done = {};

  int get _total => widget.inc.phases.fold(0, (a, p) => a + p.steps.length);

  @override
  Widget build(BuildContext context) {
    final inc = widget.inc;
    final progress = _total == 0 ? 0.0 : _done.length / _total;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1226),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Palette.glassBorder)),
      ),
      child: ListView(
        controller: widget.controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: inc.color.withOpacity(0.15),
                ),
                child: Icon(inc.icon, color: inc.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(inc.title,
                    style: const TextStyle(
                        color: Palette.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(inc.summary,
              style: const TextStyle(color: Palette.dim, height: 1.4)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: Palette.green,
              backgroundColor: Palette.glassBorder,
            ),
          ),
          const SizedBox(height: 4),
          Text('${_done.length} of $_total steps done',
              style: const TextStyle(color: Palette.dim, fontSize: 11)),
          for (int p = 0; p < inc.phases.length; p++) ...[
            const SizedBox(height: 16),
            Text(inc.phases[p].name,
                style: TextStyle(
                    color: p == 0 ? Palette.red : Palette.cyan,
                    letterSpacing: 2,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (int i = 0; i < inc.phases[p].steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final key = '$p-$i';
                    setState(() {
                      if (!_done.add(key)) _done.remove(key);
                    });
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderColor: _done.contains('$p-$i')
                        ? Palette.green.withOpacity(0.5)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _done.contains('$p-$i')
                                ? Palette.green
                                : Colors.transparent,
                            border: Border.all(
                                color: _done.contains('$p-$i')
                                    ? Palette.green
                                    : Palette.dim,
                                width: 2),
                          ),
                          child: _done.contains('$p-$i')
                              ? const Icon(Icons.check, size: 16, color: Palette.bg)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(inc.phases[p].steps[i],
                              style: TextStyle(
                                  color: _done.contains('$p-$i')
                                      ? Palette.dim
                                      : Palette.text,
                                  height: 1.4,
                                  fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 14),
          const Text('WHO TO CONTACT',
              style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 8),
          const GlassCard(
            child: Text(
              '•  Your mobile provider: use the official number from their website, app or SIM pack.\n'
              '•  Your bank or mobile money provider.\n'
              '•  The police, for a report number.\n'
              '•  The app\'s official help centre (WhatsApp, Facebook, Google).\n\n'
              'Never use a phone number or link that came from a message.',
              style: TextStyle(color: Palette.text, height: 1.5, fontSize: 13),
            ),
          ),
          if (inc.warn) ...[
            const SizedBox(height: 14),
            GlowButton(
              label: 'COPY A WARNING FOR MY CONTACTS',
              icon: Icons.ios_share,
              onTap: () {
                Clipboard.setData(const ClipboardData(
                  text: 'Warning: my account may have been hacked. Do not reply to '
                      'messages asking for money or a code, even if they look like '
                      'they are from me. Please call me on my number to check. '
                      'Share this with others.',
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Copied. Paste it into SMS, Facebook or a call script.'),
                ));
              },
            ),
          ],
        ],
      ),
    );
  }
}
