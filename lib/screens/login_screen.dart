import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../language.dart';
import '../participant_accounts.dart';
import '../marathon_streams.dart';
import '../shopping.dart';
import 'admin_screen.dart';
import '../widgets/auth_brand.dart';

typedef ParticipantHomeBuilder =
    Widget Function(BuildContext context, Participant participant);

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.accounts,
    required this.streams,
    required this.participantHome,
    this.initialInvitationToken,
  });

  final ParticipantAccounts accounts;
  final MarathonStreams streams;
  final ParticipantHomeBuilder participantHome;
  final String? initialInvitationToken;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _InvitationError { empty, invalid }

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _invitation = TextEditingController();
  late bool _useInvitation = widget.initialInvitationToken != null;
  bool _busy = false;
  _InvitationError? _invitationError;
  bool _invalid = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _invitation.dispose();
    super.dispose();
  }

  void _signIn() {
    // Test account for the local prototype. Release requires server authentication.
    if (kReleaseMode || _busy) return;
    final login = _login.text.trim().toLowerCase();
    if (login == 'zhanna' && _password.text == 'ZhannaDemo2026') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              AdminScreen(accounts: widget.accounts, streams: widget.streams),
        ),
      );
      return;
    }
    final participant = widget.accounts.signIn(login, _password.text);
    if (participant != null) {
      _openParticipant(participant);
      return;
    }
    setState(() => _invalid = true);
  }

  void _openParticipant(Participant participant) {
    ShoppingScope.of(context).selectAccount(participant.login);
    final destination = widget.participantHome;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => destination(context, participant),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _activate() async {
    if (kReleaseMode || _busy) return;
    final input = _invitation.text.trim();
    if (widget.initialInvitationToken == null && input.isEmpty) {
      setState(() => _invitationError = _InvitationError.empty);
      return;
    }
    final token = widget.initialInvitationToken ?? invitationToken(input);
    if (token == null) {
      setState(() => _invitationError = _InvitationError.invalid);
      return;
    }
    setState(() {
      _busy = true;
      _invitationError = null;
    });
    try {
      final participant = await widget.accounts.redeemInvitation(token);
      if (!mounted) return;
      if (participant != null) {
        _openParticipant(participant);
        return;
      }
    } catch (_) {
      // Let the participant try again if local storage could not be updated.
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _invitationError = _InvitationError.invalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageSwitch()]),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5D9D0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrand(compact: true),
                  const SizedBox(height: 16),
                  Text(
                    _useInvitation
                        ? context.tr('Вход по ссылке', 'Сілтеме арқылы кіру')
                        : context.tr('Вход в приложение', 'Қолданбаға кіру'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (kReleaseMode)
                    Text(
                      context.tr(
                        'Вход пока недоступен.',
                        'Кіру әзірге қолжетімсіз.',
                      ),
                    )
                  else ...[
                    Text(
                      context.tr('Тестовый вход', 'Сынақ нұсқасына кіру'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF675953),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_useInvitation) ...[
                      if (widget.initialInvitationToken == null)
                        TextField(
                          key: const ValueKey('participant-invitation'),
                          controller: _invitation,
                          onChanged: (_) {
                            if (_invitationError != null) {
                              setState(() => _invitationError = null);
                            }
                          },
                          enabled: !_busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              'Вставь ссылку Жанны',
                              'Жаннаның сілтемесін қой',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      if (_invitationError != null)
                        Text(
                          _invitationError == _InvitationError.empty
                              ? context.tr(
                                  'Введите ссылку',
                                  'Сілтемені енгізіңіз',
                                )
                              : context.tr(
                                  'Ссылка недействительна, уже использована или её срок истёк.',
                                  'Сілтеме жарамсыз, қолданылған немесе мерзімі өткен.',
                                ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _activate,
                        child: Text(
                          context.tr(
                            'Активировать доступ',
                            'Қолжетімділікті іске қосу',
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        key: const ValueKey('participant-login'),
                        controller: _login,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('Логин', 'Логин'),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('participant-password'),
                        controller: _password,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          labelText: context.tr('Пароль', 'Құпиясөз'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            tooltip: _showPassword
                                ? context.tr(
                                    'Скрыть пароль',
                                    'Құпиясөзді жасыру',
                                  )
                                : context.tr(
                                    'Показать пароль',
                                    'Құпиясөзді көрсету',
                                  ),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      if (_invalid) ...[
                        const SizedBox(height: 12),
                        Text(
                          context.tr(
                            'Неверный логин или пароль.',
                            'Логин немесе құпиясөз қате.',
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _signIn,
                        child: Text(context.tr('Войти', 'Кіру')),
                      ),
                    ],
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _useInvitation = !_useInvitation,
                            ),
                      child: Text(
                        _useInvitation
                            ? context.tr(
                                'Войти по логину и паролю',
                                'Логин мен құпиясөз арқылы кіру',
                              )
                            : context.tr(
                                'Войти по ссылке',
                                'Сілтеме арқылы кіру',
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
