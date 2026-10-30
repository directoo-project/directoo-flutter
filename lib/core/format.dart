const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

String faDigits(String input) {
  return input.replaceAllMapped(RegExp(r'\d'), (match) {
    return _persianDigits[int.parse(match.group(0)!)];
  });
}

String faGrouped(num value) {
  final negative = value < 0;
  final rounded = value.abs().round();
  final text = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write('٬');
    buffer.write(text[i]);
  }
  return faDigits('${negative ? '-' : ''}$buffer');
}

String toman(num value) => '${faGrouped(value)} تومان';

String faInt(num value) => faDigits(value.round().toString());

List<int> gregorianToJalali(int gy, int gm, int gd) {
  final gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 +
      (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) +
      gd +
      gdm[gm - 1];
  var jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final jm = days < 186 ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
  final jd = 1 + (days < 186 ? (days % 31) : ((days - 186) % 30));
  return [jy, jm, jd];
}

String formatJalali(String? iso, {bool withTime = true}) {
  if (iso == null || iso.isEmpty) return '—';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return iso;
  final j = gregorianToJalali(date.year, date.month, date.day);
  final day =
      '${j[0]}/${j[1].toString().padLeft(2, '0')}/${j[2].toString().padLeft(2, '0')}';
  if (!withTime) return faDigits(day);
  final clock =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return faDigits('$day $clock');
}

String normalizePhone(String phone) {
  var value = phone.replaceAll(RegExp(r'[\s\-()]'), '');
  if (value.startsWith('+98')) {
    value = '0${value.substring(3)}';
  } else if (value.startsWith('98') && value.length >= 12) {
    value = '0${value.substring(2)}';
  }
  return value;
}

bool isIranMobile(String phone) => RegExp(r'^09\d{9}$').hasMatch(normalizePhone(phone));

String normalizeInstagramUsername(String value) {
  var raw = value.trim();
  if (raw.isEmpty) return '';
  final looksLikeUrl = raw.startsWith(RegExp(r'https?://', caseSensitive: false)) ||
      RegExp(r'^(www\.)?instagram\.com/', caseSensitive: false).hasMatch(raw);
  if (looksLikeUrl) {
    final withProtocol = raw.startsWith(RegExp(r'https?://')) ? raw : 'https://$raw';
    final uri = Uri.tryParse(withProtocol);
    if (uri != null) {
      raw = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    }
  }
  return raw.split('/').first.split('?').first.replaceFirst(RegExp(r'^@+'), '').trim();
}

bool isValidInstagramUsername(String value) =>
    RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(value);
