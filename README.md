# flutter_tr_formatters

[![tests](https://github.com/CeyDrew/flutter_tr_formatters/actions/workflows/tests.yml/badge.svg)](https://github.com/CeyDrew/flutter_tr_formatters/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Input formatters and validators for Turkish data in Flutter: **phone numbers**, **TR IBAN**, **T.C. Kimlik No**, **Vergi Kimlik No** and **vehicle plates**. No dependencies besides Flutter.

[Türkçe aşağıda](#türkçe)

| Field | While typing | Validator |
|---|---|---|
| Phone | `05434135461` → `0543 413 54 61` | `TrValidators.phone()` / `phone(mobileOnly: true)` |
| IBAN | `tr330006…` → `TR33 0006 1005 1978 6457 8413 26` | `TrValidators.iban()` |
| T.C. Kimlik No | digits only, max 11, no leading 0 | `TrValidators.tckn()` |
| Vergi No | digits only, max 10 | `TrValidators.vkn()` |
| Plate | `34abc123` → `34 ABC 123` | `TrValidators.plate()` |

## Usage

```yaml
dependencies:
  flutter_tr_formatters:
    git: https://github.com/CeyDrew/flutter_tr_formatters
```

```dart
import 'package:flutter_tr_formatters/flutter_tr_formatters.dart';

TextFormField(
  keyboardType: TextInputType.phone,
  inputFormatters: const [TrPhoneFormatter()],
  validator: TrValidators.phone(mobileOnly: true),
);

TextFormField(
  textCapitalization: TextCapitalization.characters,
  inputFormatters: const [TrIbanFormatter()],
  validator: TrValidators.iban(message: 'IBAN hatalı'),
);
```

A complete form is in [`example/main.dart`](example/main.dart).

### Formatters

- **`TrPhoneFormatter`** — groups as `0XXX XXX XX XX`, adds the leading `0`, converts pasted `+90 …` numbers, stops at 11 digits.
- **`TrIbanFormatter`** — uppercases, groups by four, adds `TR` when the user starts with digits, stops at 26 characters.
- **`TcknFormatter`** — digits only, at most 11, a leading `0` is dropped.
- **`VknFormatter`** — digits only, at most 10.
- **`TrPlateFormatter`** — uppercases, inserts the spaces, drops letters not used on Turkish plates (Ç Ğ İ Ö Ş Ü Q W X).

The cursor stays next to the character it was next to, so editing in the middle of a number works naturally.

### Validators

Use the checks directly anywhere in your code:

```dart
TrValidators.isTckn('10000000146');            // true
TrValidators.isVkn('1234567890');              // true
TrValidators.isIban('TR33 0006 1005 1978 6457 8413 26'); // true — ISO 7064 mod-97
TrValidators.isPhone('0212 555 12 34', mobileOnly: true); // false
TrValidators.isPlate('06 A 1234');             // true
TrValidators.toE164('0543 413 54 61');         // '+905434135461' — send this to your API
```

The `tckn()`, `vkn()`, `iban()`, `phone()` and `plate()` factories return functions for `TextFormField.validator`. They return `null` for an empty field, so add your own required check if the field is mandatory. Messages are in Turkish by default and can be changed with `message:`.

These checks prove a value is **well-formed**; they do not prove that an identity number exists or that an IBAN belongs to the user.

## Backend

The same rules are available for Laravel in [laravel-tr-validation](https://github.com/CeyDrew/laravel-tr-validation), so the app and the API validate the same way.

## Testing

```bash
flutter test
```

Tests cover typing character by character, pasting, cursor position, length limits, 1,000 generated TCKN/VKN numbers and the form-field validators.

## License

MIT © 2026 Abdurrahman Bilici

---

## Türkçe

Flutter için Türkiye'ye özel giriş biçimlendiricileri ve doğrulayıcılar: **telefon**, **TR IBAN**, **T.C. kimlik no**, **vergi no** ve **araç plakası**.

- Kullanıcı yazarken alan kendiliğinden biçimlenir: `0543 413 54 61`, `TR33 0006 1005 …`, `34 ABC 123`.
- `TrValidators.tckn()`, `iban()`, `phone(mobileOnly: true)` gibi fonksiyonlar doğrudan `TextFormField.validator` alanına verilir; hata mesajları varsayılan olarak Türkçedir.
- `TrValidators.toE164()` telefon numarasını API'ye gönderilecek `+905434135461` biçimine çevirir.
- Aynı kuralların Laravel sürümü: [laravel-tr-validation](https://github.com/CeyDrew/laravel-tr-validation).
