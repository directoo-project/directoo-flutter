import 'package:directoo/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persian digits and mobile normalization', () {
    expect(faDigits('0912'), '۰۹۱۲');
    expect(normalizePhone('+989121234567'), '09121234567');
    expect(isIranMobile('09121234567'), isTrue);
    expect(isValidInstagramUsername('my.shop'), isTrue);
  });

  test('jalali conversion keeps a known date', () {
    final parts = gregorianToJalali(2026, 10, 30);
    expect(parts[0], 1405);
    expect(parts[1], 8);
    expect(parts[2], 8);
  });
}
