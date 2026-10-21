import '../entities/scam_investigation.dart';

/// Extracts and normalises phone numbers without making unverifiable claims.
///
/// This is the local intelligence layer used by both direct number checks and
/// screenshot/message analysis. A future reputation API can enrich the same
/// domain model with verified report counts and carrier data.
class PhoneIntelligenceService {
  const PhoneIntelligenceService();

  static final RegExp _candidatePattern = RegExp(
    r'(?<!\d)(?:\+?\d[\d\s()\-]{5,}\d)(?!\d)',
  );

  List<InvestigationPhoneNumber> inspect(
    String content, {
    bool directNumberCheck = false,
  }) {
    final candidates = <String>{};

    if (directNumberCheck) {
      final value = content.trim();
      if (value.isNotEmpty) candidates.add(value);
    } else {
      for (final match in _candidatePattern.allMatches(content)) {
        final value = match.group(0)?.trim();
        if (value != null && value.isNotEmpty) candidates.add(value);
      }
    }

    return candidates
        .map(_inspectCandidate)
        .whereType<InvestigationPhoneNumber>()
        .toList(growable: false);
  }

  InvestigationPhoneNumber? _inspectCandidate(String raw) {
    final normalized = _normalize(raw);
    final digits = normalized.replaceAll(RegExp(r'\D'), '');

    // E.164 permits at most 15 digits. Values outside a plausible phone-number
    // range are ignored so dates, prices and account references are less likely
    // to be mistaken for phone numbers.
    if (digits.length < 7 || digits.length > 15) return null;

    final warnings = <String>[];
    var risk = 0.0;

    final countryHint = _countryHint(normalized);
    final typeHint = _typeHint(normalized);

    // Missing a country code is metadata, not evidence of fraud. It must never
    // increase risk or make an ordinary local mobile number look suspicious.

    if (_looksLikeUkPremiumOrPersonalNumber(normalized)) {
      warnings.add(
        'This looks like a UK premium-rate, service or personal-number range. Check call charges and verify who owns it before calling back.',
      );
      risk += 0.18;
    }

    if (RegExp(r'^(\+?)(\d)\2{6,}$').hasMatch(normalized.replaceAll(' ', ''))) {
      warnings.add('The number has an unusual repeated-digit pattern.');
      risk += 0.10;
    }

    // A number cannot be labelled safe or fraudulent from formatting alone.
    // Keep baseline risk at zero unless there is concrete local evidence.
    risk = risk.clamp(0.0, 0.35);

    return InvestigationPhoneNumber(
      raw: raw,
      normalized: normalized,
      countryHint: countryHint,
      typeHint: typeHint,
      warnings: warnings,
      risk: risk,
      reputationAvailable: false,
    );
  }

  String _normalize(String raw) {
    var value = raw.trim();
    final hasPlus = value.startsWith('+');
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$value' : value;
  }

  String _countryHint(String number) {
    if (number.startsWith('+44')) return 'United Kingdom';
    if (number.startsWith('+263')) return 'Zimbabwe';
    if (number.startsWith('+27')) return 'South Africa';
    if (number.startsWith('+1')) return 'United States / Canada';
    if (number.startsWith('+353')) return 'Ireland';
    if (number.startsWith('+61')) return 'Australia';
    return number.startsWith('+') ? 'International number' : 'Country not confirmed';
  }

  String _typeHint(String number) {
    final compact = number.replaceAll(RegExp(r'\D'), '');

    if (number.startsWith('+447') ||
        (!number.startsWith('+') && compact.startsWith('07'))) {
      return 'Mobile-style number';
    }
    if (number.startsWith('+2637')) return 'Zimbabwe mobile-style number';
    if (_looksLikeUkPremiumOrPersonalNumber(number)) {
      return 'UK service / premium / personal-number range';
    }
    if (number.startsWith('+44')) return 'UK telephone number';
    return 'Telephone number';
  }

  bool _looksLikeUkPremiumOrPersonalNumber(String number) {
    final compact = number.replaceAll(RegExp(r'\D'), '');
    final ukLocal = number.startsWith('+44')
        ? '0${compact.substring(2)}'
        : compact;

    return ukLocal.startsWith('09') ||
        ukLocal.startsWith('070') ||
        ukLocal.startsWith('084') ||
        ukLocal.startsWith('087');
  }
}
