import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tr_formatters/flutter_tr_formatters.dart';

String makeTckn(String first9) {
  final d = first9.split('').map(int.parse).toList();
  d.add(
      (((d[0] + d[2] + d[4] + d[6] + d[8]) * 7 - (d[1] + d[3] + d[5] + d[7])) %
                  10 +
              10) %
          10);
  d.add(d.reduce((a, b) => a + b) % 10);
  return d.join();
}

String makeVkn(String first9) {
  var sum = 0;
  for (var i = 0; i < 9; i++) {
    final tmp = (int.parse(first9[i]) + 9 - i) % 10;
    final v = (tmp * (1 << (9 - i))) % 9;
    sum += (tmp != 0 && v == 0) ? 9 : v;
  }
  return '$first9${(10 - sum % 10) % 10}';
}

void main() {
  group('TCKN', () {
    test('valid', () {
      expect(TrValidators.isTckn('10000000146'), isTrue);
      expect(TrValidators.isTckn(' 10000000146 '), isTrue);
    });

    test('invalid', () {
      for (final v in [
        '10000000147',
        '10000000156',
        '01234567890',
        '1000000014',
        '100000001460',
        '1000000014a',
        '',
        null
      ]) {
        expect(TrValidators.isTckn(v), isFalse, reason: '$v');
      }
    });

    test('generated numbers pass and a changed check digit fails', () {
      final r = Random(42);
      for (var i = 0; i < 500; i++) {
        final tckn = makeTckn('${r.nextInt(900000000) + 100000000}');
        expect(TrValidators.isTckn(tckn), isTrue, reason: tckn);
        final broken =
            '${tckn.substring(0, 10)}${(int.parse(tckn[10]) + 1) % 10}';
        expect(TrValidators.isTckn(broken), isFalse, reason: broken);
      }
    });
  });

  test('VKN', () {
    expect(TrValidators.isVkn('1234567890'), isTrue);
    expect(TrValidators.isVkn('1234567891'), isFalse);
    expect(TrValidators.isVkn('123456789'), isFalse);
    expect(TrValidators.isVkn(null), isFalse);

    final r = Random(7);
    for (var i = 0; i < 500; i++) {
      final vkn = makeVkn('${r.nextInt(1000000000)}'.padLeft(9, '0'));
      expect(TrValidators.isVkn(vkn), isTrue, reason: vkn);
      expect(
          TrValidators.isVkn(
              '${vkn.substring(0, 9)}${(int.parse(vkn[9]) + 1) % 10}'),
          isFalse);
    }
  });

  test('IBAN', () {
    expect(TrValidators.isIban('TR330006100519786457841326'), isTrue);
    expect(TrValidators.isIban('TR33 0006 1005 1978 6457 8413 26'), isTrue);
    expect(TrValidators.isIban('tr330006100519786457841326'), isTrue);
    expect(TrValidators.isIban('TR330006100519786457841327'), isFalse);
    expect(TrValidators.isIban('TR340006100519786457841326'), isFalse);
    expect(TrValidators.isIban('TR330006110519786457841326'), isFalse,
        reason: 'reserved digit must be 0');
    expect(TrValidators.isIban('DE89370400440532013000'), isFalse);
    expect(TrValidators.isIban(null), isFalse);
  });

  test('phone', () {
    for (final v in [
      '05434135461',
      '5434135461',
      '+905434135461',
      '905434135461',
      '0543 413 54 61',
      '+90 (543) 413-54-61',
      '0212 555 12 34',
      '0850 222 33 44'
    ]) {
      expect(TrValidators.isPhone(v), isTrue, reason: v);
    }
    for (final v in [
      '0543413546',
      '054341354611',
      '+15434135461',
      '0143 413 54 61',
      '0643 413 54 61',
      '444 1 444',
      '',
      null
    ]) {
      expect(TrValidators.isPhone(v), isFalse, reason: '$v');
    }
    expect(TrValidators.isPhone('0212 555 12 34', mobileOnly: true), isFalse);
    expect(TrValidators.toE164('0543 413 54 61'), '+905434135461');
    expect(TrValidators.toE164('123'), isNull);
  });

  test('plate', () {
    for (final v in [
      '34 ABC 123',
      '34ABC123',
      '06 A 1234',
      '06a1234',
      '35 AB 4567',
      '81 Z 12345',
      '01 ABC 12'
    ]) {
      expect(TrValidators.isPlate(v), isTrue, reason: v);
    }
    for (final v in [
      '00 A 1234',
      '82 A 1234',
      '34 ABCD 12',
      '34 A 123',
      '34 ABC 1234',
      '34 Q 1234',
      '34 ÇA 123',
      'ABC 123',
      '',
      null
    ]) {
      expect(TrValidators.isPlate(v), isFalse, reason: '$v');
    }
  });

  test('form field validators ignore empty values and return the message', () {
    final v = TrValidators.tckn();
    expect(v(null), isNull);
    expect(v('  '), isNull);
    expect(v('10000000146'), isNull);
    expect(v('123'), 'Geçerli bir T.C. kimlik numarası girin');
    expect(TrValidators.phone(mobileOnly: true)('0212 555 12 34'),
        'Geçerli bir cep telefonu numarası girin');
    expect(TrValidators.iban(message: 'IBAN hatalı')('TR00'), 'IBAN hatalı');
    expect(TrValidators.plate()('34 ABC 123'), isNull);
    expect(TrValidators.vkn()('1234567890'), isNull);
  });
}
