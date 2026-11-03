import 'package:flutter/material.dart';
import 'package:flutter_tr_formatters/flutter_tr_formatters.dart';

void main() => runApp(const MaterialApp(home: ExampleForm()));

/// A small form that uses every formatter and validator in the package.
class ExampleForm extends StatefulWidget {
  /// Creates the example form.
  const ExampleForm({super.key});

  @override
  State<ExampleForm> createState() => _ExampleFormState();
}

class _ExampleFormState extends State<ExampleForm> {
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_tr_formatters')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Cep telefonu', hintText: '0543 413 54 61'),
              keyboardType: TextInputType.phone,
              inputFormatters: const [TrPhoneFormatter()],
              validator: TrValidators.phone(mobileOnly: true),
            ),
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'IBAN',
                  hintText: 'TR00 0000 0000 0000 0000 0000 00'),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [TrIbanFormatter()],
              validator: TrValidators.iban(),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'T.C. kimlik no'),
              keyboardType: TextInputType.number,
              inputFormatters: const [TcknFormatter()],
              validator: TrValidators.tckn(),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Vergi no'),
              keyboardType: TextInputType.number,
              inputFormatters: const [VknFormatter()],
              validator: TrValidators.vkn(),
            ),
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Plaka', hintText: '34 ABC 123'),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [TrPlateFormatter()],
              validator: TrValidators.plate(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final ok = _form.currentState!.validate();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Form geçerli' : 'Hataları düzeltin')));
              },
              child: const Text('Kontrol et'),
            ),
          ],
        ),
      ),
    );
  }
}
