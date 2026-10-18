# ScamShield - digital fraud defence (prototype)

Most account hacks in Zimbabwe, including hijacked WhatsApp accounts, start with
one scam message: a "friend" asking for a 6-digit code, a free-airtime link, a
fake SIM upgrade. ScamShield covers the whole chain, on every channel.

Self-contained: no backend needed.

## Run (inside your CropMedic folder)
    flutter create scamshield
    cd scamshield
Copy pubspec.yaml and lib/ from this folder into it (replace the originals), then:
    flutter pub get
    flutter run -d chrome

## Four layers of defence
1. CHECK   - paste a message from SMS, WhatsApp, Facebook, email or what a caller
             said. Get a risk score, the message with warning signs marked,
             reasons, link analysis and what to do.
2. PROTECT - a 14-step protection checklist (two-step verification, linked
             devices, SIM and mobile money safety, family safe word) with a score,
             and a visual of how a takeover happens and where to stop it.
3. HELP    - tap what happened ("I shared a WhatsApp code", "My WhatsApp was taken
             over", "I sent money to a scammer", "My phone lost signal"...) and get a
             step-by-step recovery plan: right now, today, this week.
4. LEARN   - a playbook of 14 scam types and 5 golden rules.

Plus RADAR (live multi-channel threat feed with account-takeover count) and a
PARTNER VIEW (business icon, top right) for telcos, banks and police.

## What it detects (lib/analyzer.dart)
Code theft, PIN/password theft, fake reversals, prize scams, advance fees, fake
investments, fake jobs, family impersonation, SIM swap talk, dial-a-code (USSD)
tricks, QR tricks, overpayment, payment redirection, fake WhatsApp/Facebook
warnings, vote-for-my-child and "is this you" bait, fake fraud-department calls,
and lookalike or shortened links. It also understands advice: "Never share your
PIN" and real OTP messages are NOT flagged.

Tested: 18 scam messages (all flagged, one correctly as "suspicious") and 17
normal messages (zero false alarms), including real OTP texts and bank warnings.

## Honest limits
- Rules catch known patterns. New scams need new rules or a trained model.
- Shona and Ndebele wording is basic and needs review by native speakers.
- WhatsApp does not let other apps read your chats, and Google Play restricts SMS
  access. Practical routes: "Share to ScamShield", user-granted notification
  access, or filtering at the telco level through a partnership.
- Recovery steps are general guidance. Menu names in apps change; always use the
  official help pages and official phone numbers.
- Partner data is simulated. A real partner view needs signed agreements and
  privacy safeguards.

## Next steps
Collect labelled messages (with consent) and train a text model (TFLite) beside
the rules; add community reporting; add a backend for the partner view.
