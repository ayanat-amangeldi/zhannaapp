import 'package:flutter/material.dart';

import '../language.dart';
import '../marathon_streams.dart';
import '../participant_accounts.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.accounts,
    required this.streams,
    required this.participantHome,
  });

  final ParticipantAccounts accounts;
  final MarathonStreams streams;
  final ParticipantHomeBuilder participantHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final burgundy = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KEZEK SENDE',
              style: TextStyle(
                color: burgundy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'by zhanna',
              style: TextStyle(
                color: Color(0xFF675953),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: const [LanguageSwitch()],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5D9D0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D75354A),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('Добро пожаловать', 'Қош келдіңіз'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(
                          'Войдите по логину и паролю или по ссылке от Жанны.',
                          'Логин мен құпиясөзді енгізіңіз немесе Жаннаның сілтемесімен кіріңіз.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF675953),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('continue-as-participant'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LoginScreen(
                              accounts: accounts,
                              streams: streams,
                              participantHome: participantHome,
                            ),
                          ),
                        ),
                        child: Text(
                          context.tr('Перейти ко входу', 'Кіруге өту'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
