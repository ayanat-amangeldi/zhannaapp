import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhannaapp/language.dart';
import 'package:zhannaapp/main.dart';
import 'package:zhannaapp/participant_accounts.dart';

void main() {
  testWidgets(
    'Invitation opens the assigned account once and leaves welcome underneath',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final accounts = ParticipantAccounts(prefs);
      addTearDown(accounts.dispose);
      final language = LanguageController(preferences: prefs);
      addTearDown(language.dispose);
      final password = await accounts.create(name: 'Дана', login: 'dana01');
      final older = await accounts.createInvitation('dana01');
      final invite = await accounts.createInvitation('dana01');
      expect(
        await accounts.redeemInvitation(invitationToken(older.toString())!),
        isNull,
      );
      expect(accounts.signIn('dana01', password)?.name, 'Дана');

      tester.binding.platformDispatcher.defaultRouteNameTestValue = invite
          .toString();
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await tester.pumpWidget(ZhannaApp(controller: language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Активировать доступ'));
      await tester.pumpAndSettle();
      expect(find.text('Поток ещё не назначен'), findsOneWidget);

      await tester.tap(find.text('На стартовый экран'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('continue-as-participant')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Войти по ссылке'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Активировать доступ'));
      await tester.pumpAndSettle();
      expect(find.text('Введите ссылку'), findsOneWidget);
      expect(find.textContaining('недействительна'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('participant-invitation')),
        'неверная ссылка',
      );
      await tester.tap(find.text('Активировать доступ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('недействительна'), findsOneWidget);
      expect(find.text('Введите ссылку'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('participant-invitation')),
        invite.toString(),
      );
      await tester.tap(find.text('Активировать доступ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('уже использована'), findsOneWidget);
    },
  );
}
