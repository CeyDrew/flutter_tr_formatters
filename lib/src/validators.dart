/// Checks for Turkish identifiers. Every check accepts `null` and never throws.
///
/// The `tckn`, `iban`, `phone`, … factories return functions that can be passed
/// straight to `TextFormField.validator`. They return `null` for an empty field,
/// so combine them with your own "required" check when the field is mandatory.
abstract final class TrValidators {
  static final _tckn = RegExp(r'^[1-9]\d{10}$');
  static final _vkn = RegExp(r'^\d{10}$');
  static final _iban = RegExp(r'^TR\d{7}0[0-9A-Z]{16}$');
  static final _phone = RegExp(r'^(?:[2-5]\d{2}|850)\d{7}$');
  static final _mobile = RegExp(r'^5\d{9}$');
  static const _plateLetters = '[ABCDEFGHIJKLMNOPRSTUVYZ]';
  static final _plate = RegExp(
    '^(0[1-9]|[1-7]\\d|8[01]) (?:$_plateLetters \\d{4,5}|$_plateLetters{2} \\d{3,4}|$_plateLetters{3} \\d{2,3})\$',
  );

  /// T.C. Kimlik No: 11 digits, not starting with 0, with two check digits.
  static bool isTckn(String? value) {
    final v = value?.trim();
    if (v == null || !_tckn.hasMatch(v)) return false;
    final d = v.split('').map(int.parse).toList();
    final odd = d[0] + d[2] + d[4] + d[6] + d[8];
    final even = d[1] + d[3] + d[5] + d[7];
    final tenth = ((odd * 7 - even) % 10 + 10) % 10;
    final eleventh = d.take(10).reduce((a, b) => a + b) % 10;
    return d[9] == tenth && d[10] == eleventh;
  }

  /// Vergi Kimlik No: 10 digits, the last one is a check digit.
  static bool isVkn(String? value) {
    final v = value?.trim();
    if (v == null || !_vkn.hasMatch(v)) return false;
    final d = v.split('').map(int.parse).toList();
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      final tmp = (d[i] + 9 - i) % 10;
      var x = (tmp * (1 << (9 - i))) % 9;
      if (tmp != 0 && x == 0) x = 9;
      sum += x;
    }
    return (10 - sum % 10) % 10 == d[9];
  }

  /// Turkish IBAN (26 characters, mod-97 checksum). Spaces and lowercase are accepted.
  static bool isIban(String? value) {
    if (value == null) return false;
    final iban = compactIban(value);
    if (!_iban.hasMatch(iban)) return false;
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    var remainder = 0;
    for (final unit in rearranged.codeUnits) {
      final n = unit >= 65 ? unit - 55 : unit - 48;
      remainder = (n > 9 ? remainder * 100 + n : remainder * 10 + n) % 97;
    }
    return remainder == 1;
  }

  /// Turkish phone number: mobile (5xx), landline (2xx/3xx/4xx) or 850.
  /// Accepts `+90`, `90` and `0` prefixes and spaces, dashes, dots and brackets.
  static bool isPhone(String? value, {bool mobileOnly = false}) {
    final n = nationalPhone(value);
    if (n == null) return false;
    return (mobileOnly ? _mobile : _phone).hasMatch(n);
  }

  /// Turkish vehicle plate such as `34 ABC 123` or `06A1234`.
  static bool isPlate(String? value) {
    final p = normalizePlate(value);
    return p != null && _plate.hasMatch(p);
  }

  /// `"+90 (543) 413-54-61"` → `"5434135461"`, or `null` if it is not 10 national digits.
  static String? nationalPhone(String? value) {
    if (value == null) return null;
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (!RegExp(r'^\+?\d+$').hasMatch(cleaned)) return null;
    var digits = cleaned.replaceFirst('+', '');
    if (digits.length == 12 && digits.startsWith('90')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits.length == 10 ? digits : null;
  }

  /// Valid number in E.164 form (`+905434135461`), or `null`.
  static String? toE164(String? value) => isPhone(value) ? '+90${nationalPhone(value)}' : null;

  /// Removes whitespace and uppercases an IBAN.
  static String compactIban(String value) => value.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  /// `"34abc123"` → `"34 ABC 123"`, or `null` if the shape does not match.
  static String? normalizePlate(String? value) {
    if (value == null) return null;
    final compact = value.replaceAll(RegExp(r'[\s\-]+'), '').toUpperCase();
    final m = RegExp(r'^(\d{2})([A-Z]{1,3})(\d{2,5})$').firstMatch(compact);
    return m == null ? null : '${m[1]} ${m[2]} ${m[3]}';
  }

  /// `TextFormField` validator for T.C. Kimlik No.
  static String? Function(String?) tckn({String message = 'Geçerli bir T.C. kimlik numarası girin'}) =>
      _field(isTckn, message);

  /// `TextFormField` validator for Vergi Kimlik No.
  static String? Function(String?) vkn({String message = 'Geçerli bir vergi kimlik numarası girin'}) =>
      _field(isVkn, message);

  /// `TextFormField` validator for TR IBAN.
  static String? Function(String?) iban({String message = 'Geçerli bir IBAN girin'}) => _field(isIban, message);

  /// `TextFormField` validator for phone numbers; set [mobileOnly] to accept only 5xx numbers.
  static String? Function(String?) phone({bool mobileOnly = false, String? message}) => _field(
        (v) => isPhone(v, mobileOnly: mobileOnly),
        message ?? (mobileOnly ? 'Geçerli bir cep telefonu numarası girin' : 'Geçerli bir telefon numarası girin'),
      );

  /// `TextFormField` validator for vehicle plates.
  static String? Function(String?) plate({String message = 'Geçerli bir plaka girin'}) => _field(isPlate, message);

  static String? Function(String?) _field(bool Function(String?) check, String message) =>
      (value) => (value == null || value.trim().isEmpty || check(value)) ? null : message;
}
