import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content.dart';
import '../language.dart';

class WhatsAppContactButton extends StatelessWidget {
  const WhatsAppContactButton({super.key});

  Future<void> _open(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // The platform can fail to open an external link.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Не удалось открыть WhatsApp.', 'WhatsApp ашылмады.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = ContentScope.of(context).whatsappNumber;
    final url = number == null ? null : Uri.https('wa.me', '/$number');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: url == null ? null : () => _open(context, url),
            icon: const Icon(Icons.chat_outlined),
            label: Text(
              context.tr(
                'Написать Жанне в WhatsApp',
                'Жаннаға WhatsApp арқылы жазу',
              ),
            ),
          ),
          if (url == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                context.tr(
                  'Жанна ещё не указала номер.',
                  'Жанна нөмірін әлі көрсетпеді.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WhatsAppSettingsScreen extends StatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  State<WhatsAppSettingsScreen> createState() => _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState extends State<WhatsAppSettingsScreen> {
  final _form = GlobalKey<FormState>();
  TextEditingController? _number;
  bool _saving = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final number = ContentScope.of(context).whatsappNumber;
    _number ??= TextEditingController(text: number == null ? '' : '+$number');
  }

  @override
  void dispose() {
    _number?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final store = ContentScope.of(context);
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await store.saveWhatsAppNumber(_number!.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Номер WhatsApp', 'WhatsApp нөмірі')),
    ),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _number,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr(
                  'Номер с кодом страны',
                  'Ел кодымен бірге нөмір',
                ),
                hintText: '+7 700 000 00 00',
              ),
              validator: (value) {
                final input = value ?? '';
                return input.trim().isNotEmpty &&
                        normalizeWhatsAppNumber(input) == null
                    ? context.tr(
                        'Введи действительный номер с кодом страны.',
                        'Ел кодымен бірге дұрыс нөмір енгіз.',
                      )
                    : null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                'Оставь поле пустым, чтобы отключить кнопку.',
                'Батырманы өшіру үшін өрісті бос қалдыр.',
              ),
            ),
            if (_failed)
              Text(
                context.tr('Не удалось сохранить номер.', 'Нөмір сақталмады.'),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(context.tr('Сохранить', 'Сақтау')),
            ),
          ],
        ),
      ),
    ),
  );
}
