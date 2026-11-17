import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../language.dart';
import '../participant_accounts.dart';

class ParticipantsScreen extends StatelessWidget {
  const ParticipantsScreen({super.key, required this.accounts});
  final ParticipantAccounts accounts;

  Future<void> _copyInvite(
    BuildContext context,
    Participant participant,
  ) async {
    try {
      final link = await accounts.createInvitation(participant.login);
      await Clipboard.setData(ClipboardData(text: link.toString()));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Ссылка скопирована. Она действует 72 часа и открывается один раз.',
              'Сілтеме көшірілді. Ол 72 сағат жарамды және бір рет қолданылады.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Не удалось скопировать ссылку. Попробуй ещё раз.',
              'Сілтеме көшірілмеді. Қайталап көр.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: accounts,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.person_add_outlined),
          label: Text(context.tr('Добавить участницу', 'Қатысушы қосу')),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _CreateParticipant(accounts: accounts),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (accounts.participants.isEmpty)
          Text(context.tr('Пока нет участниц.', 'Әзірге қатысушылар жоқ.')),
        for (final participant in accounts.participants)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(participant.name),
              subtitle: Text(participant.login),
              trailing: IconButton(
                tooltip: context.tr(
                  'Скопировать новую ссылку',
                  'Жаңа сілтемені көшіру',
                ),
                icon: const Icon(Icons.link),
                onPressed: () => _copyInvite(context, participant),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CreateParticipant extends StatefulWidget {
  const _CreateParticipant({required this.accounts});
  final ParticipantAccounts accounts;

  @override
  State<_CreateParticipant> createState() => _CreateParticipantState();
}

class _CreateParticipantState extends State<_CreateParticipant> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _login = TextEditingController();
  bool _saving = false;
  bool _saveFailed = false;
  String? _password;

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final password = await widget.accounts.create(
        name: _name.text,
        login: _login.text,
      );
      if (mounted) setState(() => _password = password);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _password;
    final login = _login.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Новая участница', 'Жаңа қатысушы')),
        actions: const [LanguageSwitch()],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (password == null) ...[
              TextFormField(
                key: const ValueKey('new-participant-name'),
                controller: _name,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: context.tr('Имя', 'Есімі'),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? context.tr('Введи имя', 'Есімін енгіз')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('new-participant-login'),
                controller: _login,
                enabled: !_saving,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: context.tr('Логин', 'Логин'),
                  helperText: context.tr('Например, dana01', 'Мысалы, dana01'),
                ),
                validator: (value) {
                  final candidate = value ?? '';
                  if (!widget.accounts.validLogin(candidate)) {
                    return context.tr(
                      '3–32 символа: латиница, цифры, . _ -',
                      '3–32 таңба: латын әріптері, сандар, . _ -',
                    );
                  }
                  return widget.accounts.loginTaken(candidate)
                      ? context.tr('Этот логин уже занят', 'Бұл логин бос емес')
                      : null;
                },
              ),
              const SizedBox(height: 24),
              if (_saveFailed)
                Text(
                  context.tr(
                    'Не удалось сохранить участницу.',
                    'Қатысушыны сақтау мүмкін болмады.',
                  ),
                ),
              FilledButton(
                onPressed: _saving ? null : _create,
                child: Text(context.tr('Создать аккаунт', 'Аккаунт ашу')),
              ),
            ] else ...[
              Text(
                _name.text.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Пароль показывается один раз. Скопируй данные, чтобы передать их участнице.',
                  'Құпиясөз бір рет көрсетіледі. Қатысушыға беру үшін деректерді көшіріп ал.',
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                '${context.tr('Логин', 'Логин')}: $login\n${context.tr('Пароль', 'Құпиясөз')}: $password',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          '${context.tr('Логин', 'Логин')}: $login\n${context.tr('Пароль', 'Құпиясөз')}: $password',
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr('Данные скопированы', 'Деректер көшірілді'),
                      ),
                    ),
                  );
                },
                label: Text(
                  context.tr('Скопировать данные', 'Деректерді көшіру'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('Готово', 'Дайын')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
