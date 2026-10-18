import 'package:flutter/material.dart';

import 'theme.dart';

class _Playbook {
  final String name, how;
  final List<String> flags, todo;
  final IconData icon;
  const _Playbook(this.name, this.icon, this.how, this.flags, this.todo);
}

const _books = [
  _Playbook(
    'WhatsApp and social account takeover',
    Icons.phonelink_lock,
    'A message from a "friend" says they sent you a code by mistake, or a link offers free airtime or asks you to vote. If you share the code or log in on the fake page, criminals register your number on their phone and message your contacts asking for money.',
    ['Someone asks for a 6-digit code', 'A message from a contact that feels slightly off', 'Free airtime or "vote for" links'],
    ['Never share a code, with anyone', 'Switch on two-step verification (Settings, Account, Two-step verification)', 'Call your friend to check before you reply'],
  ),
  _Playbook(
    'SIM swap',
    Icons.sim_card_alert_outlined,
    'Criminals get a replacement SIM in your name, so your calls and codes go to them. They then reset your WhatsApp, email and mobile money.',
    ['Your phone suddenly has no signal for no reason', 'Messages about SIM upgrades or blocking', 'You stop getting codes you asked for'],
    ['Contact your provider at once from another phone', 'Visit the shop with your ID', 'Ask what extra protection you can put on your line'],
  ),
  _Playbook(
    'Dial-a-code (USSD) tricks',
    Icons.dialpad,
    'You are told to dial a code. Some codes forward your calls or messages to a number the scammer controls, so they receive your verification codes.',
    ['A dial code that contains a phone number', 'Prize or airtime offers', 'Pressure to do it now'],
    ['Never dial a code you do not understand', 'Ask your provider what a code does before using it', 'If you already dialled one, contact your provider now'],
  ),
  _Playbook(
    'Fake page and account warnings',
    Icons.report_problem_outlined,
    'A message says your Facebook page or account will be disabled, or you broke a rule, and sends you to a fake login page.',
    ['Threat to disable or delete', 'A link to "appeal" or "verify"', 'Web address that is not the real site'],
    ['Do not tap the link', 'Open the app yourself to check for real notices', 'Report and delete the message'],
  ),
  _Playbook(
    'Overpayment and fake proof of payment',
    Icons.receipt_long_outlined,
    'A buyer "accidentally" pays too much, shows a fake screenshot, and asks you to refund the difference. The payment never arrived.',
    ['A screenshot instead of money in your account', 'Pressure to refund quickly', 'Buyer will not wait'],
    ['Check your own balance, not the screenshot', 'Refund only after the money is really yours', 'Block and report'],
  ),
  _Playbook(
    'Business payment redirection',
    Icons.business_center_outlined,
    'A criminal copies or hacks a real supplier\'s email and sends new bank details. Your payment goes to them instead.',
    ['A sudden change of bank details', 'Urgent payment request', 'Email address slightly different from usual'],
    ['Phone the supplier on a number you already have', 'Have two people approve changes to payment details', 'Tell your IT team'],
  ),
  _Playbook(
    'Fake reversal',
    Icons.swap_horiz_rounded,
    'You get a message saying money arrived by mistake, then a call or text asking you to send it back. The first message is fake, so you send your real money.',
    ['"Sent by mistake"', 'Pressure to return it fast', 'Message came from a personal number'],
    ['Check your balance in the official app or USSD menu', 'Never send money back because of an SMS', 'Block and report the number'],
  ),
  _Playbook(
    'PIN and OTP theft',
    Icons.password_rounded,
    'Someone pretends to be your provider or bank and asks for your PIN or a code sent to your phone. With it, they empty your account.',
    ['Asks for a PIN, password or OTP', 'Says your account will be blocked', 'Urgent tone'],
    ['Never share a PIN or code with anyone', 'Hang up and call the official number yourself', 'If you shared it, call your provider at once'],
  ),
  _Playbook(
    'Prize and promo scams',
    Icons.emoji_events_outlined,
    'A message says you won money or a phone. To claim it you must pay a fee or enter your details on a fake website.',
    ['You never entered a draw', 'Asks for a fee to claim', 'Link to a strange website'],
    ['Ignore and delete', 'Never pay to receive a prize', 'Warn your family and friends'],
  ),
  _Playbook(
    'Fake jobs and loans',
    Icons.work_outline,
    'A job or loan offer arrives out of the blue. You are asked to pay a registration or processing fee, or to send your ID.',
    ['Contact from a stranger on WhatsApp', 'Fee up front', 'Too-good pay for easy work'],
    ['Never pay to get a job or loan', 'Check the company on its official channels', 'Do not send ID copies to strangers'],
  ),
  _Playbook(
    'Fake investments',
    Icons.trending_up,
    'You are promised your money will double in days. Early "returns" may be paid to win your trust, then everything disappears.',
    ['Guaranteed profit', 'Very fast returns', '"Do not tell anyone"'],
    ['Do not invest', 'Check the company is registered', 'Never send money to a personal number'],
  ),
  _Playbook(
    'Fake relatives',
    Icons.family_restroom,
    'A message says "Hi, this is your cousin, my number changed", then asks for airtime or money for an emergency.',
    ['A "new number" from someone you know', 'An emergency needing money now', 'Asks you to keep it secret'],
    ['Call the person on the number you already have', 'Ask a question only they would know', 'Warn the real person'],
  ),
  _Playbook(
    'Fake links and websites',
    Icons.link_off,
    'A link takes you to a copy of a real website. It looks genuine, but anything you type goes straight to the scammer.',
    ['Shortened links', 'Strange endings such as .xyz or .top', 'Brand name with extra words, like -verify'],
    ['Do not tap links in unexpected messages', 'Open the official app or type the address yourself', 'Report and delete'],
  ),
  _Playbook(
    'Fake authority threats',
    Icons.account_balance_outlined,
    'A message claims to be from a tax or government office. It says you owe money and will be arrested unless you pay now.',
    ['Threats of arrest or fines', 'Payment demanded by mobile money', 'Link to a payment page'],
    ['Real offices do not demand payment by text', 'Contact the office through its official channels', 'Never pay through a link in a message'],
  ),
];

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('SCAM PLAYBOOK',
            style: TextStyle(color: Palette.cyan, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Know the tricks and you will spot them. Tap one to open it.',
            style: TextStyle(color: Palette.dim, fontSize: 12)),
        const SizedBox(height: 12),
        GlassCard(
          borderColor: Palette.cyan.withOpacity(0.5),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_moon_outlined, color: Palette.cyan),
                  SizedBox(width: 8),
                  Text('5 GOLDEN RULES',
                      style: TextStyle(
                          color: Palette.cyan,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontSize: 12)),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '1. Nobody real asks for your PIN or codes.\n'
                '2. Never pay money to receive money.\n'
                '3. Check your balance in the official app, not in an SMS.\n'
                '4. If it is urgent and scary, stop and call someone you trust.\n'
                '5. If a message sounds too good to be true, it is.',
                style: TextStyle(color: Palette.text, height: 1.7, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final b in _books)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: Palette.cyan,
                  collapsedIconColor: Palette.dim,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.violet.withOpacity(0.2),
                    ),
                    child: Icon(b.icon, color: Palette.violet, size: 20),
                  ),
                  title: Text(b.name,
                      style: const TextStyle(
                          color: Palette.text, fontWeight: FontWeight.w700)),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.how,
                              style: const TextStyle(
                                  color: Palette.dim, height: 1.4, fontSize: 13)),
                          const SizedBox(height: 10),
                          const Text('RED FLAGS',
                              style: TextStyle(
                                  color: Palette.red,
                                  letterSpacing: 2,
                                  fontSize: 10)),
                          for (final f in b.flags)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('•  $f',
                                  style: const TextStyle(
                                      color: Palette.text, fontSize: 13)),
                            ),
                          const SizedBox(height: 10),
                          const Text('WHAT TO DO',
                              style: TextStyle(
                                  color: Palette.green,
                                  letterSpacing: 2,
                                  fontSize: 10)),
                          for (final t in b.todo)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('•  $t',
                                  style: const TextStyle(
                                      color: Palette.text, fontSize: 13)),
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
    );
  }
}
