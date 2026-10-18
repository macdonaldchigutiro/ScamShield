/// ScamShield detection engine.
///
/// Runs fully on the phone. Each warning sign adds a probability of "scam";
/// the final score combines them. Messages like "never share your PIN" are
/// recognised as advice, not as scams. This is a transparent rules engine, the
/// base you later extend with a trained model and community reports.
library;

enum Verdict { safe, suspicious, scam }

enum Channel { sms, whatsapp, facebook, email, call, other }

String channelLabel(Channel c) {
  switch (c) {
    case Channel.sms:
      return 'SMS';
    case Channel.whatsapp:
      return 'WhatsApp';
    case Channel.facebook:
      return 'Facebook';
    case Channel.email:
      return 'Email';
    case Channel.call:
      return 'Phone call';
    case Channel.other:
      return 'Other';
  }
}

class Hit {
  final int start, end;
  final double weight;
  const Hit(this.start, this.end, this.weight);
}

class Reason {
  final String title, detail, type;
  final double weight;
  const Reason(this.title, this.detail, this.type, this.weight);
}

class LinkInfo {
  final String url, domain;
  final List<String> flags;
  final double risk;
  const LinkInfo(this.url, this.domain, this.flags, this.risk);
}

class Analysis {
  final int score;
  final Verdict verdict;
  final String type;
  final Channel channel;
  final List<Reason> reasons;
  final List<Hit> hits;
  final List<LinkInfo> links;
  final double amount;
  final List<String> advice;

  const Analysis({
    required this.score,
    required this.verdict,
    required this.type,
    required this.channel,
    required this.reasons,
    required this.hits,
    required this.links,
    required this.amount,
    required this.advice,
  });
}

class _Rule {
  final String type, title, detail;
  final double weight;
  final bool negatable;
  final RegExp re;
  _Rule(this.type, this.title, this.detail, this.weight, String pattern,
      {this.negatable = false})
      : re = RegExp(pattern, caseSensitive: false);
}

final List<_Rule> _rules = [
  _Rule(
    'Code theft',
    'Asks you to send a verification code',
    'A verification code is the key to your account. Criminals trigger a code to your phone, then trick you into handing it over, often by pretending to be a friend or family member.',
    0.6,
    r"((send|forward|share|give|tell|read|transfer|resend|pass|screenshot|reply with)\W+(?:\w+\W+){0,6}?(6|six)[- ]?digit)|((send|forward|share|give|tell|read|transfer|resend|pass|reply with)\W+(?:\w+\W+){0,4}?(whatsapp |verification |security |login |confirmation |activation )?code\b)|((sent|texted|received)\W+(?:\w+\W+){0,3}?(6|six)[- ]?digit)|(\bcode\b\W+(?:\w+\W+){0,6}?(by mistake|wrong number))|(\bcode\b\W+(?:\w+\W+){0,10}?(can you|could you|please|pls|kindly)\W+(?:\w+\W+){0,3}?(send|forward|read|tell|give|share|transfer|resend|pass))",
    negatable: true,
  ),
  _Rule(
    'Account takeover',
    'Asks for your PIN or password',
    'Real mobile money providers and banks never ask for your PIN, password or one-time code, not even their own staff.',
    0.55,
    r"(send|share|give|reply|provide|confirm|enter|verify|tell)\W+(?:\w+\W+){0,5}?(pin|otp|password|passcode|verification code|one[- ]time code)",
    negatable: true,
  ),
  _Rule(
    'Fake reversal',
    'Claims money was sent by mistake',
    'Scammers send a fake "you received money" message, then ask you to send real money back. Check your balance in your official app or USSD menu, never from the SMS.',
    0.55,
    r"(by mistake|wrong number|sent (it |them |the money )?in error|(please|kindly|pliz|plz)\W+(?:\w+\W+){0,2}?(reverse|return|send back|refund|resend)|kukanganisa)",
  ),
  _Rule(
    'Prize scam',
    'Says you have won a prize',
    'You cannot win a draw you never entered. Genuine prizes never ask you to pay or share details first.',
    0.5,
    r"(you('ve| have)?\s+won|winner|congratulations|lucky draw|claim your (prize|reward|bonus)|win (a |an |free )?(prize|airtime|data|phone|cash|\$\d+)|wakakunda|makorokoto|uwinile)",
  ),
  _Rule(
    'Pressure',
    'Uses urgency to rush you',
    'Scammers want you to act before you have time to think or check.',
    0.2,
    r"(urgent|immediately|right now|act now|within \d+\s*(hours?|hrs?|minutes?|mins?)|last chance|final (notice|warning)|expires?|today only)",
  ),
  _Rule(
    'Account threat',
    'Threatens to block or close your account',
    'Fake alerts try to scare you into acting. Contact your provider using their official app or number instead.',
    0.3,
    r"((suspend|deactivat|block|freez|lock|terminat)\w*\W+(?:\w+\W+){0,4}?(account|wallet|line|sim|card))|((account|wallet|line|sim)\W+(?:\w+\W+){0,4}?(suspend|deactivat|block|frozen|locked|closed)\w*)",
  ),
  _Rule(
    'Advance-fee scam',
    'Asks you to pay a fee first',
    'Real jobs, loans and prizes do not ask for a fee up front.',
    0.5,
    r"((registration|processing|admin(istration)?|clearance|release|delivery|activation) fee)|((pay|send)\W+(?:\w+\W+){0,4}?(to (receive|release|claim|get|unlock)|first))|(fee to (receive|release|claim|get))",
    negatable: true,
  ),
  _Rule(
    'Fake investment',
    'Promises quick or guaranteed profit',
    'Guaranteed profit does not exist. Doubling your money fast is the classic sign of a scam.',
    0.5,
    r"(get\W+(?:\w+\W+){0,2}?\$\s?\d+\s+back|double your (money|investment)|guaranteed (returns?|profit)|(returns?|profit) of \d+\s*%|invest\W+(?:\w+\W+){0,3}?(and|to) (get|earn|receive)|forex|get rich)",
  ),
  _Rule(
    'Family impersonation',
    'Pretends to be someone you know',
    'Scammers pose as a relative or friend with a "new number", then ask for money or a code. Check by calling the person on the number you already have.',
    0.35,
    r"(my (phone |number|line) (has )?(changed|is new)|this is my new number|lost my phone|i am your (cousin|uncle|aunt|friend|brother|sister|son|daughter))",
  ),
  _Rule(
    'Asks for money',
    'Asks you to send money',
    'Be very careful with any message that tells you to send money to a number.',
    0.22,
    r"(send|transfer|deposit|pay|tumira|thumela)\W+(?:\w+\W+){0,3}?(\$\s?\d+|usd\s?\d+|zwl\s?\d+|zig\s?\d+|\d{2,}\s?(usd|dollars?|bucks|zwl|zig))",
    negatable: true,
  ),
  _Rule(
    'Pressure',
    'Tells you to keep it secret',
    'Scammers isolate you so no one can warn you.',
    0.25,
    r"(don'?t tell|do not tell|keep (this|it) (a )?(secret|private)|tell no one|do not share this)",
  ),
  _Rule(
    'Freebie bait',
    'Offers free data or airtime',
    'Free data and airtime messages are a popular way to collect your details and your verification codes.',
    0.25,
    r"(free (data|airtime|bundles?|mb|gb|talktime)|bonus (data|airtime))",
  ),
  _Rule(
    'Fake job',
    'Job offer that asks for details or money',
    'Real employers do not recruit by random message, and never charge you to apply.',
    0.3,
    r"((vacanc\w+|job offer|hiring|recruit\w+)\W+(?:\w+\W+){0,8}?(whatsapp|send (your )?(cv|id|details)|fee|pay|\$\d+))",
  ),
  _Rule(
    'Fake platform alert',
    'Fake WhatsApp upgrade or warning',
    'WhatsApp is free and does not send "Gold", "Premium" or "verify now" offers. These are used to steal accounts.',
    0.45,
    r"(whatsapp (gold|premium|plus|pink|blue|upgrade|update|subscription)|verify your whatsapp|whatsapp (account )?(will|has) (be |been )?(suspend|block|delet|expir|disabl)\w*)",
  ),
  _Rule(
    'Fake platform alert',
    'Fake account warning from a platform',
    'Scammers send fake "your page will be disabled" or "policy violation" notices to get you to a fake login page.',
    0.45,
    r"((your|the) (page|account|profile)\W+(?:\w+\W+){0,4}?(will be|has been|is)\W+(?:\w+\W+){0,3}?(disabled|restricted|deleted|suspended|removed))|((copyright|policy|community standards?) (violation|infringement)\W+(?:\w+\W+){0,8}?(appeal|verify|confirm))|(meta (support|security|team))",
  ),
  _Rule(
    'Click bait',
    'Bait to make you tap a link',
    'Lures like "vote for my child" or "is this you in this video" send you to a fake login page that steals your account.',
    0.4,
    r"((vote for|please vote)\W+(?:\w+\W+){0,8}?(link|click|http|www|\.com|bit\.ly))|((click|tap|open)\W+(?:\w+\W+){0,3}?(link|here)\W+(?:\w+\W+){0,8}?(vote|see (who|the)|is this you|your photo|video of you))|(is this you (in|on)\b)",
  ),
  _Rule(
    'SIM swap',
    'Talks about changing or blocking your SIM',
    'Scammers who get a replacement SIM in your name receive your codes and can take over your accounts. A real SIM change is done in person with your ID, not by message or call.',
    0.4,
    r"((sim( card)?)\W+(?:\w+\W+){0,4}?(upgrade|swap|replac|re-?regist|expire|deactivat|block|suspend))|((upgrade|replace|re-?register|swap)\W+(?:\w+\W+){0,3}?(your )?sim)",
  ),
  _Rule(
    'USSD trick',
    'Tells you to dial a code that contains a phone number',
    'Some dial codes forward your calls or messages to someone else, so the scammer receives your verification codes. Never dial a code you do not understand.',
    0.6,
    r"([*#]\d{2,3}[*#]\+?\d{7,}#?)|((dial|enter|type|press)\W+(?:\w+\W+){0,3}?[*#]\d+[*#]\d+[*#])",
  ),
  _Rule(
    'QR trick',
    'Asks you to scan a code to receive money',
    'You never need to scan a code or enter your PIN to receive money. Scanning can be used to send your money out.',
    0.45,
    r"(scan\W+(?:\w+\W+){0,3}?(qr|barcode|code)\W+(?:\w+\W+){0,8}?(receive|claim|get paid|refund|collect|withdraw))|((receive|claim|get paid|refund|collect|withdraw)\W+(?:\w+\W+){0,8}?scan\W+(?:\w+\W+){0,3}?(qr|barcode|code))",
  ),
  _Rule(
    'Overpayment scam',
    'Says they paid too much and wants a refund',
    'Scammers send a fake proof of payment for more than the price, then ask you to refund the difference. Check your own balance before sending anything.',
    0.4,
    r"(overpaid|sent (you )?(extra|too much)|paid (you )?(extra|too much)|extra \$?\d+)\W+(?:\w+\W+){0,10}?(send|return|refund|back|balance)",
  ),
  _Rule(
    'Payment redirection',
    'Asks you to pay into new bank details',
    'Criminals hack or copy a real business email, then give new bank details. Always confirm by phoning the person on a number you already have.',
    0.4,
    r"((change|update|new)\W+(?:\w+\W+){0,3}?(bank(ing)?|payment|account)\W+(?:\w+\W+){0,3}?(details|number|instructions))",
  ),
  _Rule(
    'Impersonation',
    'Claims to be a security or fraud department',
    'Real fraud teams never ask for your PIN or codes, and never ask you to move money to a safe account.',
    0.35,
    r"((this is|calling from|speaking from)\W+(?:\w+\W+){0,4}?(fraud|security|verification|risk) (department|team|unit))|(press \d to (confirm|verify|block|cancel))",
  ),
  _Rule(
    'Impersonation',
    'Asks you to move money to a safe account',
    'There is no such thing as a safe account you must move money to. This is a well-known trick.',
    0.5,
    r"(safe account|secure account)\W+(?:\w+\W+){0,6}?(transfer|move|send)",
  ),
];

const _brands = [
  'ecocash', 'econet', 'netone', 'telecel', 'onemoney', 'innbucks', 'zipit',
  'zimra', 'cbz', 'fbc', 'stanbic', 'nedbank', 'steward', 'zesa', 'rbz',
];

const _linkBrands = [
  ..._brands, 'facebook', 'whatsapp', 'instagram', 'tiktok', 'fb', 'meta',
  'paypal', 'google',
];

const _shorteners = [
  'bit.ly', 'tinyurl.com', 'cutt.ly', 'rb.gy', 'is.gd', 'goo.gl',
  'shorturl.at', 't.ly', 'ow.ly',
];

const _riskyTlds = [
  '.top', '.xyz', '.click', '.link', '.cc', '.site', '.online', '.live',
  '.info', '.icu', '.buzz', '.work',
];

const _lookalikeWords = [
  'verify', 'secure', 'login', 'update', 'claim', 'reward', 'promo', 'bonus',
  'free', 'support', 'account', 'portal', 'pay', 'refund',
];

final RegExp _urlRe = RegExp(
  r'((https?:\/\/|www\.)[^\s]+|\b[a-z0-9][a-z0-9\-]*\.(com|net|org|info|top|xyz|click|link|cc|site|online|live|co\.zw|org\.zw|zw|me|ly|gl|is)\b[^\s]*)',
  caseSensitive: false,
);

final RegExp _amountRe = RegExp(
  r'\$\s?(\d[\d,]*(?:\.\d+)?)|(\d[\d,]*)\s?(?:usd|dollars)',
  caseSensitive: false,
);

final RegExp _negationRe = RegExp(
  r"(do not|don'?t|dont|never|won'?t|will not|must not|should not|cannot|can'?t|ever ask|ever asks)\s+(\w+\s+){0,3}$",
  caseSensitive: false,
);

bool _negated(String text, int start) {
  final from = start - 30 < 0 ? 0 : start - 30;
  return _negationRe.hasMatch(text.substring(from, start));
}

const Map<String, List<String>> _advice = {
  'Code theft': [
    'Never share a verification code with anyone, even a friend or family member. A code is the key to your account.',
    'Call the person on a number you already have. Their account may be hacked.',
    'If you already shared it, open the app and log in again right away, then switch on two-step verification. See the Help tab.',
  ],
  'Account takeover': [
    'Never share your PIN, password or code, even with someone who says they work for the company.',
    'Do not reply. Block the sender.',
    'If you already shared it, call your provider or bank on their official number straight away and change your PIN.',
  ],
  'Fake reversal': [
    'Do not send money back.',
    'Check your real balance in your official app or USSD menu, not the message.',
    'Block the number and report it to your provider.',
  ],
  'Prize scam': [
    'Ignore it. You cannot win a draw you did not enter.',
    'Never pay a fee or share details to claim a prize.',
    'Delete the message and block the sender.',
  ],
  'Advance-fee scam': [
    'Do not pay anything upfront.',
    'Check the offer by calling the organisation on a number you find yourself.',
    'Report it and warn your friends and family.',
  ],
  'Fake investment': [
    'Do not invest. Guaranteed profit does not exist.',
    'Check that the company is registered before sending any money.',
    'Never send money to a personal number.',
  ],
  'Phishing link': [
    'Do not tap the link.',
    'To check an account, open the official app or type the official website yourself.',
    'Report the message and delete it.',
  ],
  'Account threat': [
    'Do not follow the message. Contact your provider using the official app or number.',
    'Do not tap links or share codes.',
    'Block the sender and report it.',
  ],
  'Family impersonation': [
    'Do not send anything yet.',
    'Call the person on the number you already have, or ask a question only they could answer.',
    'Warn the real person that someone is using their name.',
  ],
  'Fake platform alert': [
    'Do not tap the link or reply.',
    'Open the app yourself and check for real notices in its settings.',
    'Report the message and delete it.',
  ],
  'Click bait': [
    'Do not tap the link, even if it came from a friend. Their account may be hacked.',
    'Call your friend to ask if they really sent it.',
    'If you already logged in on the page, change your password now.',
  ],
  'SIM swap': [
    'Do not agree to any SIM change by message or call.',
    'Real SIM changes are done in person at a shop with your ID.',
    'If your phone suddenly loses signal for no reason, contact your provider at once. See the Help tab.',
  ],
  'USSD trick': [
    'Do not dial it. Codes with a phone number inside can forward your calls and texts to a scammer.',
    'If you already dialled it, contact your provider now and ask them to cancel any forwarding.',
    'Block the sender and report it.',
  ],
  'QR trick': [
    'Do not scan it. You never scan or enter a PIN to receive money.',
    'Check your balance in your official app.',
    'Block the sender and report it.',
  ],
  'Overpayment scam': [
    'Do not send any refund yet.',
    'Check your own balance. Ignore screenshots and "proof of payment".',
    'Only release goods or refunds once the money is really in your account.',
  ],
  'Payment redirection': [
    'Do not pay into the new details.',
    'Phone the person or company on a number you already have to confirm.',
    'Tell your IT or finance team, the email account may be hacked.',
  ],
  'Impersonation': [
    'Hang up or stop replying. Real security teams never ask for PINs or codes.',
    'Never move money to a "safe account".',
    'Call your bank or provider on the official number on your card or their website.',
  ],
};

const List<String> _genericAdvice = [
  'Do not reply, tap links or send money.',
  'Check by contacting the organisation on an official number you find yourself.',
  'Block the sender and report the message.',
];

String? _brandIn(String lower) {
  for (final b in _brands) {
    if (lower.contains(b)) return b;
  }
  return null;
}

LinkInfo _checkLink(String url) {
  var d = url.toLowerCase();
  d = d.replaceFirst(RegExp(r'^https?:\/\/'), '');
  d = d.split(RegExp(r'[\/?#]')).first;
  d = d.replaceFirst(RegExp(r'^www\.'), '');
  final flags = <String>[];
  var keep = 1.0;
  void flag(String text, double w) {
    flags.add(text);
    keep *= (1 - w);
  }

  if (_shorteners.any((s) => d == s || d.endsWith('.$s'))) {
    flag('A shortened link hides where it really goes', 0.3);
  }
  if (_riskyTlds.any((t) => d.endsWith(t))) {
    flag('Ends in an address type scammers use a lot', 0.22);
  }
  String? brand;
  for (final b in _linkBrands) {
    if (d.contains(b)) {
      brand = b;
      break;
    }
  }
  if (brand != null &&
      (d.contains('-') || _lookalikeWords.any((w) => d.contains(w)))) {
    flag('Looks like a fake "$brand" website', 0.45);
  }
  if (RegExp(r'\/(login|signin|sign-in|verify|secure|account)').hasMatch(url.toLowerCase())) {
    flag('Asks you to log in on an unfamiliar website', 0.2);
  }
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}').hasMatch(d)) {
    flag('Uses a raw number address instead of a name', 0.4);
  }
  if (RegExp(r'\d{3,}').hasMatch(d.split('.').first)) {
    flag('Strange numbers in the web address', 0.12);
  }
  return LinkInfo(url, d, flags, 1 - keep);
}

Analysis analyze(String text,
    {String sender = '', Channel channel = Channel.sms}) {
  final reasons = <Reason>[];
  final hits = <Hit>[];
  final links = <LinkInfo>[];
  final seenTitles = <String>{};

  for (final r in _rules) {
    var ms = r.re.allMatches(text).toList();
    if (r.negatable) {
      ms = ms.where((m) => !_negated(text, m.start)).toList();
    }
    if (ms.isEmpty) continue;
    if (seenTitles.add(r.title)) {
      reasons.add(Reason(r.title, r.detail, r.type, r.weight));
    }
    for (final m in ms) {
      hits.add(Hit(m.start, m.end, r.weight));
    }
  }

  for (final m in _urlRe.allMatches(text)) {
    final raw = m.group(0)!;
    final url = raw.replaceAll(RegExp(r'[.,;:!?)]+$'), '');
    final info = _checkLink(url);
    links.add(info);
    if (info.risk > 0) {
      hits.add(Hit(m.start, m.start + url.length, info.risk));
      reasons.add(Reason(
        'Suspicious link: ${info.domain}',
        '${info.flags.join('. ')}.',
        'Phishing link',
        info.risk,
      ));
    }
  }

  final lower = text.toLowerCase();
  final s = sender.trim();
  if (s.isNotEmpty) {
    final isNumber = RegExp(r'^\+?[\d\s\-]{7,}$').hasMatch(s);
    final brand = _brandIn(lower);
    if (isNumber && brand != null) {
      reasons.add(Reason(
        'Mentions $brand but came from a personal number',
        'Official messages usually come from the company name, not a personal number.',
        'Impersonation',
        0.3,
      ));
    }
  }

  final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (letters.length >= 25) {
    final upper = letters.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (upper / letters.length > 0.6) {
      reasons.add(const Reason(
        'Shouting in capital letters',
        'Scam messages often use capitals to grab attention and create panic.',
        'Pressure',
        0.1,
      ));
    }
  }
  if ('!'.allMatches(text).length >= 3) {
    reasons.add(const Reason(
      'Lots of exclamation marks',
      'Hype and excitement are used to stop you thinking.',
      'Pressure',
      0.08,
    ));
  }

  double keep = 1.0;
  for (final r in reasons) {
    keep *= (1 - r.weight);
  }
  final score = ((1 - keep) * 100).round();
  final verdict = score >= 60
      ? Verdict.scam
      : (score >= 25 ? Verdict.suspicious : Verdict.safe);

  reasons.sort((a, b) => b.weight.compareTo(a.weight));
  String type = 'No scam signs found';
  if (reasons.isNotEmpty && verdict != Verdict.safe) {
    type = reasons.first.type;
    if (type == 'Pressure' && reasons.length > 1) type = reasons[1].type;
  }

  double amount = 0;
  final am = _amountRe.firstMatch(text);
  if (am != null) {
    final raw = (am.group(1) ?? am.group(2) ?? '0').replaceAll(',', '');
    amount = double.tryParse(raw) ?? 0;
  }

  final advice = verdict == Verdict.safe
      ? const [
          'No common scam signs found.',
          'Still be careful with links, and never share your PIN or codes.',
        ]
      : (_advice[type] ?? _genericAdvice);

  return Analysis(
    score: score,
    verdict: verdict,
    type: type,
    channel: channel,
    reasons: reasons,
    hits: hits,
    links: links,
    amount: amount,
    advice: advice,
  );
}
