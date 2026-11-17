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
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthBrand(),
                const SizedBox(height: 26),
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
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('Вход для участницы', 'Қатысушыға кіру'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('organizer-entry'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          LoginScreen(accounts: accounts, streams: streams),
                    ),
                  ),
                  child: Text(
                    context.tr('Вход для организатора', 'Ұйымдастырушыға кіру'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
