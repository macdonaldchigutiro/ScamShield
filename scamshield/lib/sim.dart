import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'analyzer.dart';

class Msg {
  final int id;
  final String sender, text;
  final DateTime time;
  final Analysis a;
  final double angle, radius;
  Msg(this.id, this.sender, this.text, this.time, this.a, this.angle, this.radius);
}

class Sample {
  final String label, sender, text;
  final Channel channel;
  const Sample(this.label, this.sender, this.text, this.channel);
}

const List<Sample> samples = [
  Sample('WhatsApp code', '+263 771 000 101',
      "Hello I'm sorry I sent you a six digit code by SMS by mistake can you transfer it to me it's urgent",
      Channel.whatsapp),
  Sample('Vote link', '+263 772 000 117',
      'Please vote for my daughter in the school competition: https://vote-kids.xyz/login',
      Channel.whatsapp),
  Sample('Fake reversal', '+263 773 000 129',
      'I sent you \$50 by mistake. Please send it back to this number urgently. Thanks',
      Channel.sms),
  Sample('SIM upgrade', '+263 774 000 142',
      'Dear customer, your SIM card will be deactivated. Visit sim-upgrade-zw.top to re-register within 24 hours.',
      Channel.sms),
  Sample('Dial a code', '+263 775 000 156',
      'Win a prize! Dial *21*0771000555# to claim your airtime',
      Channel.sms),
  Sample('Facebook page', 'Meta Support',
      'Your page has been restricted for a copyright violation. Appeal here: meta-support-appeal.link',
      Channel.facebook),
  Sample('Bank details', 'accounts@payments-update.example',
      "Please note our new bank details. Update the payment instructions before Friday's invoice.",
      Channel.email),
  Sample('Fraud call', '+263 779 000 190',
      'This is the fraud department. Your account is under attack. Move your money to a safe account and tell us the OTP.',
      Channel.call),
  Sample('Shona prize', '+263 777 000 178',
      'Makorokoto! Wakakunda \$500. Tumira \$10 kuti tikutumire mari.',
      Channel.sms),
  Sample('Real WhatsApp code', 'WhatsApp',
      "Your WhatsApp code: 123-456. Don't share this code with anyone because it lets them take over your account.",
      Channel.sms),
  Sample('Normal message', 'Tendai',
      'Hi, are we still meeting at 5pm today? I will bring the books.',
      Channel.whatsapp),
];

class _T {
  final String text, sender;
  final Channel channel;
  const _T(this.text, this.channel, [this.sender = '']);
}

const List<_T> _scamPool = [
  _T("Hello I'm sorry I sent you a six digit code by SMS by mistake can you transfer it to me it's urgent", Channel.whatsapp),
  _T('Hi it is me, please send me the 6 digit code you just received', Channel.whatsapp),
  _T('Please vote for my daughter in the school competition: https://vote-kids.xyz/login', Channel.whatsapp),
  _T('Is this you in this video? tap here www.fb-video-view.click', Channel.whatsapp),
  _T('Free airtime from Econet! Click bit.ly/free-airtime and enter the code we send you', Channel.whatsapp),
  _T('Upgrade to WhatsApp Gold now. Your WhatsApp account will be suspended in 24 hours.', Channel.whatsapp),
  _T("Hello I am your cousin's friend, my number changed. Please send \$15 airtime emergency, do not tell mum.", Channel.whatsapp),
  _T('Hiring now! Earn \$300/week from home. Send your ID and pay \$10 registration fee to start. WhatsApp 0771 000 123.', Channel.whatsapp),
  _T('I sent you \$50 by mistake. Please send it back to this number urgently. Thanks', Channel.sms),
  _T('CONGRATULATIONS! You have won \$1000 in the EcoCash promo. Claim your prize: bit.ly/ec-claim and pay a \$5 registration fee.', Channel.sms),
  _T('Your EcoCash account will be suspended within 24 hours. Verify your PIN now: ecocash-verify.top/login', Channel.sms),
  _T('Dear customer, your SIM card will be deactivated. Visit sim-upgrade-zw.top to re-register within 24 hours.', Channel.sms),
  _T('Win a prize! Dial *21*0771000555# to claim your airtime', Channel.sms),
  _T('To receive your refund, scan this QR code and enter your PIN', Channel.sms),
  _T('This is ZIMRA. You owe unpaid tax. Pay \$40 now to avoid arrest: zimra-payments.xyz', Channel.sms),
  _T('Invest \$20 and get \$100 back in 24 hours. Guaranteed returns! Do not tell anyone.', Channel.sms),
  _T('Makorokoto! Wakakunda \$500. Tumira \$10 kuti tikutumire mari.', Channel.sms),
  _T('Your page has been restricted for a copyright violation. Appeal here: meta-support-appeal.link', Channel.facebook, 'Meta Support'),
  _T("Please note our new bank details. Update the payment instructions before Friday's invoice.", Channel.email, 'accounts@payments-update.example'),
  _T('This is the fraud department. Your account is under attack. Move your money to a safe account and tell us the OTP.', Channel.call),
];

const List<_T> _safePool = [
  _T('Hi, are we still meeting at 5pm today?', Channel.whatsapp, 'Tendai'),
  _T("Your WhatsApp code: 123-456. Don't share this code with anyone because it lets them take over your account.", Channel.sms, 'WhatsApp'),
  _T('Your OTP is 482913. Do not share it with anyone. Valid for 5 minutes.', Channel.sms, 'EcoCash'),
  _T('Never share your PIN with anyone, not even our staff. Stay safe from fraud.', Channel.sms, 'Your Bank'),
  _T('Dinner is ready, come home.', Channel.whatsapp, 'Mum'),
  _T('Reminder: your parent-teacher meeting is on Friday at 2pm.', Channel.sms, 'School'),
  _T('Your airtime balance is \$2.40. Dial *123# for bundles.', Channel.sms, 'Econet'),
  _T('Thanks for your payment of \$20. Your reference is INV-2041.', Channel.sms, 'Shop'),
  _T('Your Facebook login code is 889123. Never share this code.', Channel.facebook, 'Facebook'),
  _T('Your electricity token purchase of \$10 was successful.', Channel.sms, 'ZESA'),
  _T('Meeting moved to Thursday at 10am. Agenda attached.', Channel.email, 'boss@work.example'),
];

const List<String> _scamSenders = [
  '+263 771 000 101', '+263 772 000 117', '+263 773 000 129',
  '+263 774 000 142', '+263 775 000 156', '+263 776 000 163',
  '+263 777 000 178', '+263 778 000 184',
];

const _takeoverTypes = {
  'Code theft', 'SIM swap', 'Click bait', 'Fake platform alert', 'USSD trick',
  'Account takeover',
};

/// Simulated stream of incoming messages from every channel, all analysed on-device.
class ThreatSim extends ChangeNotifier {
  final math.Random _rnd = math.Random(7);
  final List<Msg> feed = [];
  int scanned = 0, blocked = 0, suspicious = 0;
  double amountBlocked = 0;
  final Map<String, int> byType = {};
  final Map<Channel, int> byChannel = {};
  final Map<String, int> senderCounts = {};
  final Map<String, String> senderType = {};
  int _id = 0, _ticks = 0;
  Timer? _timer;

  ThreatSim() {
    for (int i = 0; i < 14; i++) {
      _gen(DateTime.now().subtract(Duration(minutes: (14 - i) * 3)));
    }
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _ticks++;
      if (_ticks % 14 == 0) {
        _gen(DateTime.now());
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _gen(DateTime t) {
    final scam = _rnd.nextDouble() < 0.5;
    final pool = scam ? _scamPool : _safePool;
    final s = pool[_rnd.nextInt(pool.length)];
    final sender = s.sender.isNotEmpty
        ? s.sender
        : _scamSenders[_rnd.nextInt(_scamSenders.length)];
    final a = analyze(s.text, sender: sender, channel: s.channel);
    final id = ++_id;
    final angle = (id * 2.399963) % (2 * math.pi);
    final radius = 0.25 + 0.7 * (((id * 0.618034) % 1.0));
    feed.insert(0, Msg(id, sender, s.text, t, a, angle, radius));
    if (feed.length > 40) feed.removeLast();
    scanned++;
    if (a.verdict == Verdict.scam) {
      blocked++;
      amountBlocked += a.amount;
      byType[a.type] = (byType[a.type] ?? 0) + 1;
      byChannel[a.channel] = (byChannel[a.channel] ?? 0) + 1;
      senderCounts[sender] = (senderCounts[sender] ?? 0) + 1;
      senderType[sender] = a.type;
    } else if (a.verdict == Verdict.suspicious) {
      suspicious++;
    }
  }

  int get takeoverBlocked {
    int n = 0;
    byType.forEach((k, v) {
      if (_takeoverTypes.contains(k)) n += v;
    });
    return n;
  }

  String get threatLevel {
    final recent = feed.take(15).toList();
    if (recent.isEmpty) return 'LOW';
    final bad = recent.where((m) => m.a.verdict == Verdict.scam).length;
    final share = bad / recent.length;
    if (share > 0.55) return 'HIGH';
    if (share > 0.35) return 'ELEVATED';
    return 'LOW';
  }

  List<MapEntry<String, int>> get topTypes {
    final e = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return e.take(5).toList();
  }

  List<MapEntry<String, int>> get topSenders {
    final e = senderCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return e.take(6).toList();
  }
}
