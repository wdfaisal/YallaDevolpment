import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/formatting/formatters.dart';

void main() {
  group('Fmt.money', () {
    test('formats minor units with optional decimals', () {
      expect(Fmt.money(12345), '123.45');
      expect(Fmt.money(12000), '120');
      expect(Fmt.money(5), '0.05');
      expect(Fmt.money(0), '0');
      expect(Fmt.money(123456789), '1,234,567.89');
      expect(Fmt.money(-12345), '-123.45');
    });

    test('appends the currency when provided', () {
      expect(Fmt.money(12000, currency: 'SAR'), '120 SAR');
    });
  });

  group('Fmt.moneyExact', () {
    test('always shows two decimals', () {
      expect(Fmt.moneyExact(12000), '120.00');
      expect(Fmt.moneyExact(5), '0.05');
      expect(Fmt.moneyExact(123456789, currency: 'SAR'), '1,234,567.89 SAR');
    });
  });

  group('Fmt.number', () {
    test('groups whole numbers and keeps one decimal', () {
      expect(Fmt.number(4), '4');
      expect(Fmt.number(4.5), '4.5');
      expect(Fmt.number(1234), '1,234');
    });
  });

  group('Fmt.distance', () {
    test('renders metres under one kilometre', () {
      expect(Fmt.distance(0.75), '750 m');
      expect(Fmt.distance(1.24), '1.2 km');
      expect(Fmt.distance(null), '—');
    });
  });

  group('Fmt.eta', () {
    test('renders minutes and hours', () {
      expect(Fmt.eta(45), '45');
      expect(Fmt.eta(90), '1 h 30');
      expect(Fmt.eta(120), '2 h');
      expect(Fmt.eta(null), '—');
    });
  });

  test('Fmt.rating keeps one decimal', () {
    expect(Fmt.rating(4.567), '4.6');
    expect(Fmt.rating(5), '5.0');
  });

  group('dates', () {
    test('invalid and null values render a dash', () {
      expect(Fmt.dateTime(null), '—');
      expect(Fmt.dateTime('not-a-date'), '—');
      expect(Fmt.date('not-a-date'), '—');
    });

    test('formats a local timestamp', () {
      expect(Fmt.dateTime('2026-01-02T03:04:05'), '2026-01-02 03:04');
      expect(Fmt.date('2026-01-02T03:04:05'), '2026-01-02');
    });

    test('relative time is localized', () {
      final tenMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String();
      expect(Fmt.relative(tenMinutesAgo, isArabic: true), 'منذ 10 د');
      expect(Fmt.relative(tenMinutesAgo, isArabic: false), '10m ago');
      expect(Fmt.relative(null), '—');
    });
  });
}
