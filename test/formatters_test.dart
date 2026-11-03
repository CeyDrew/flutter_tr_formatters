import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tr_formatters/flutter_tr_formatters.dart';

/// Applies [formatter] as if [text] was typed or pasted with the cursor at [cursor] (default: end).
TextEditingValue apply(TextInputFormatter formatter, String text,
        {int? cursor, String old = ''}) =>
    formatter.formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursor ?? text.length)),
    );

/// Types [input] one character at a time.
String type(TextInputFormatter formatter, String input) {
  var value = TextEditingValue.empty;
  for (final c in input.split('')) {
    final t = value.text + c;
    value = formatter.formatEditUpdate(
        value,
        TextEditingValue(
            text: t, selection: TextSelection.collapsed(offset: t.length)));
  }
  return value.text;
}

void main() {
  group('TrPhoneFormatter', () {
    const f = TrPhoneFormatter();

    test('typing', () {
      expect(type(f, '05434135461'), '0543 413 54 61');
      expect(type(f, '0543'), '0543');
      expect(type(f, '05434'), '0543 4');
    });

    test('adds the leading 0 and stops at 11 digits', () {
      expect(type(f, '5434135461'), '0543 413 54 61');
      expect(type(f, '054341354619999'), '0543 413 54 61');
    });

    test('pasting', () {
      expect(apply(f, '+90 (543) 413-54-61').text, '0543 413 54 61');
      expect(apply(f, '905434135461').text, '0543 413 54 61');
    });

    test('cursor stays after the same digit', () {
      // "0543 413 54 61" with "9" inserted after "0543 4"; the last digit falls off.
      final v = apply(f, '0543 4913 54 61', cursor: 7, old: '0543 413 54 61');
      expect(v.text, '0543 491 35 46');
      expect(v.selection.baseOffset, 7);
    });

    test('result validates', () {
      expect(TrValidators.isPhone(type(f, '5434135461')), isTrue);
    });
  });

  group('TrIbanFormatter', () {
    const f = TrIbanFormatter();

    test('typing and grouping', () {
      expect(type(f, 'tr330006100519786457841326'),
          'TR33 0006 1005 1978 6457 8413 26');
    });

    test('adds TR when starting with digits and stops at 26 characters', () {
      expect(type(f, '330006100519786457841326999'),
          'TR33 0006 1005 1978 6457 8413 26');
    });

    test('pasting with spaces and dashes', () {
      expect(apply(f, 'TR33-0006-1005-1978-6457-8413-26').text,
          'TR33 0006 1005 1978 6457 8413 26');
    });

    test('result validates', () {
      expect(TrValidators.isIban(type(f, '330006100519786457841326')), isTrue);
    });
  });

  test('TcknFormatter', () {
    const f = TcknFormatter();
    expect(type(f, '10000000146'), '10000000146');
    expect(type(f, '0100'), '100');
    expect(type(f, '1a2b3'), '123');
    expect(type(f, '100000001469999'), '10000000146');
  });

  test('VknFormatter', () {
    const f = VknFormatter();
    expect(type(f, '1234567890123'), '1234567890');
    expect(type(f, '12-34'), '1234');
  });

  group('TrPlateFormatter', () {
    const f = TrPlateFormatter();

    test('typing inserts spaces', () {
      expect(type(f, '34abc123'), '34 ABC 123');
      expect(type(f, '06a1234'), '06 A 1234');
      expect(type(f, '34'), '34');
      expect(type(f, '34a'), '34 A');
    });

    test('drops letters not used on plates and extra characters', () {
      expect(type(f, '34çab123'), '34 AB 123');
      expect(type(f, '34qwxab12'), '34 AB 12');
      expect(type(f, '34abcd123'), '34 ABC 123');
      expect(type(f, '34a1234567'), '34 A 12345');
    });

    test('pasting', () {
      expect(apply(f, '34-abc-123').text, '34 ABC 123');
    });

    test('result validates', () {
      expect(TrValidators.isPlate(type(f, '34abc123')), isTrue);
    });
  });
}
