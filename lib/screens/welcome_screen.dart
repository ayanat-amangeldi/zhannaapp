import 'package:flutter/material.dart';

import '../language.dart';
import '../participant_accounts.dart';
import '../marathon_streams.dart';
import 'login_screen.dart';
import '../widgets/auth_brand.dart';

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageSwitch()]),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthBrand(),
                      const SizedBox(height: 24),
                      const Spacer(),
                      Text(
                        context.tr('Добро пожаловать', 'Қош келдіңіз'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 22),
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
                        child: Row(
                          children: [
                            const Icon(Icons.login_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.tr('Продолжить ко входу', 'Кіруге өту'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
