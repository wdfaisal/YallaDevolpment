/// Formatting helpers. Money is always handled in integer minor units; the
/// backend is the only source of financial values.
class Fmt {
  const Fmt._();

  /// Formats minor units with a thousands separator and 0/2 decimals.
  /// `12345` -> `123.45`; `12000` -> `120`.
  static String money(int minor, {String currency = ''}) {
    final negative = minor < 0;
    final absolute = minor.abs();
    final whole = absolute ~/ 100;
    final fraction = absolute % 100;
    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer.write(_group(whole));
    if (fraction != 0) {
      buffer.write('.');
      buffer.write(fraction.toString().padLeft(2, '0'));
    }
    if (currency.isNotEmpty) {
      buffer.write(' ');
      buffer.write(currency);
    }
    return buffer.toString();
  }

  /// Always shows two decimals (for totals and receipts).
  static String moneyExact(int minor, {String currency = ''}) {
    final negative = minor < 0;
    final absolute = minor.abs();
    final whole = absolute ~/ 100;
    final fraction = (absolute % 100).toString().padLeft(2, '0');
    final text = '${negative ? '-' : ''}${_group(whole)}.$fraction';
    return currency.isEmpty ? text : '$text $currency';
  }

  static String _group(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  static String number(num value) {
    if (value == value.roundToDouble()) return _group(value.round());
    return value.toStringAsFixed(1);
  }

  static String distance(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String eta(int? minutes) {
    if (minutes == null) return '—';
    if (minutes < 60) return '$minutes';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest';
  }

  static String rating(double value) => value.toStringAsFixed(1);

  /// Short localized date (yyyy-MM-dd HH:mm) without external packages.
  static String dateTime(String? iso) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  static String date(String? iso) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  static String relative(String? iso, {bool isArabic = true}) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '—';
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'now';
    if (diff.inMinutes < 60) {
      return isArabic ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return isArabic ? 'منذ ${diff.inDays} ي' : '${diff.inDays}d ago';
    }
    return date(iso);
  }
}
