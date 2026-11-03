import 'package:flutter/services.dart';

/// Formats a Turkish phone number while typing: `0543 413 54 61`.
///
/// Pasted `+90 …` numbers are converted, a leading `0` is added when missing
/// and input stops at 11 digits.
class TrPhoneFormatter extends _GroupingFormatter {
  /// Creates the formatter.
  const TrPhoneFormatter();

  @override
  String clean(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('90') && d.length > 11) d = d.substring(2);
    if (d.isNotEmpty && !d.startsWith('0')) d = '0$d';
    return d.length > 11 ? d.substring(0, 11) : d;
  }

  @override
  List<int> get groups => const [4, 3, 2, 2];
}

/// Formats a Turkish IBAN in groups of four: `TR33 0006 1005 1978 6457 8413 26`.
///
/// Letters are uppercased, `TR` is added when the user starts with digits
/// and input stops at 26 characters.
class TrIbanFormatter extends _GroupingFormatter {
  /// Creates the formatter.
  const TrIbanFormatter();

  @override
  String clean(String input) {
    var s = input.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if (s.isNotEmpty && RegExp(r'^\d').hasMatch(s)) s = 'TR$s';
    final out = StringBuffer();
    for (var i = 0; i < s.length && out.length < 26; i++) {
      final c = s[i];
      // Two letters for the country code, then digits and letters.
      if (out.length >= 2 || RegExp('[A-Z]').hasMatch(c)) out.write(c);
    }
    return out.toString();
  }

  @override
  List<int> get groups => const [4, 4, 4, 4, 4, 4, 2];
}

/// Digits only, at most 11, and the first digit cannot be 0 (T.C. Kimlik No).
class TcknFormatter extends _GroupingFormatter {
  /// Creates the formatter.
  const TcknFormatter();

  @override
  String clean(String input) {
    final d =
        input.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    return d.length > 11 ? d.substring(0, 11) : d;
  }

  @override
  List<int> get groups => const [];
}

/// Digits only, at most 10 (Vergi Kimlik No).
class VknFormatter extends _GroupingFormatter {
  /// Creates the formatter.
  const VknFormatter();

  @override
  String clean(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(0, 10) : d;
  }

  @override
  List<int> get groups => const [];
}

/// Formats a vehicle plate while typing: `34 ABC 123`.
///
/// Uppercases letters, drops letters that are not used on Turkish plates
/// (Ç, Ğ, İ, Ö, Ş, Ü, Q, W, X) and inserts the spaces automatically.
class TrPlateFormatter extends TextInputFormatter {
  /// Creates the formatter.
  const TrPlateFormatter();

  static final _letter = RegExp('[ABCDEFGHIJKLMNOPRSTUVYZ]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.toUpperCase();
    final province = StringBuffer();
    final letters = StringBuffer();
    final number = StringBuffer();

    for (final c in raw.split('')) {
      final isDigit = RegExp(r'\d').hasMatch(c);
      if (province.length < 2) {
        if (isDigit) province.write(c);
      } else if (number.isEmpty && _letter.hasMatch(c) && letters.length < 3) {
        letters.write(c);
      } else if (isDigit && letters.isNotEmpty && number.length < 5) {
        number.write(c);
      }
    }

    final parts = [province, letters, number]
        .map((b) => b.toString())
        .where((s) => s.isNotEmpty);
    final text = parts.join(' ');
    final significantBefore = _significant(
        raw.substring(0, newValue.selection.end.clamp(0, raw.length)));
    return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
            offset: _offsetFor(text, significantBefore)));
  }
}

/// Keeps the cleaned characters, inserts spaces between [groups] and keeps the
/// cursor next to the same character it was next to before formatting.
abstract class _GroupingFormatter extends TextInputFormatter {
  const _GroupingFormatter();

  String clean(String input);
  List<int> get groups;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = clean(newValue.text);
    final text = _group(cleaned, groups);

    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final before = clean(newValue.text.substring(0, cursor)).length;
    final significantBefore = before > cleaned.length ? cleaned.length : before;

    return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
            offset: _offsetFor(text, significantBefore)));
  }

  static String _group(String s, List<int> groups) {
    if (groups.isEmpty) return s;
    final out = StringBuffer();
    var i = 0;
    for (final size in groups) {
      if (i >= s.length) break;
      if (out.isNotEmpty) out.write(' ');
      final end = (i + size).clamp(0, s.length);
      out.write(s.substring(i, end));
      i = end;
    }
    if (i < s.length) out.write(' ${s.substring(i)}');
    return out.toString();
  }
}

int _significant(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').length;

/// Text offset just after the [count]-th non-space character of [text].
int _offsetFor(String text, int count) {
  if (count <= 0) return 0;
  var seen = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] != ' ') seen++;
    if (seen == count) return i + 1;
  }
  return text.length;
}
