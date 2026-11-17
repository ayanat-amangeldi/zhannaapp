import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhannaapp/main.dart';

void main() {
  testWidgets('Organizer credentials gate the admin panel', (tester) async {
    await tester.pumpWidget(const ZhannaApp());
    final entry = find.byKey(const ValueKey('organizer-entry'));
    final participant = find.byKey(const ValueKey('continue-as-participant'));
    await tester.tap(participant);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('participant-login')),
      'zhanna',
    );
    await tester.enterText(
      find.byKey(const ValueKey('participant-password')),
      'ZhannaDemo2026',
    );
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Неверный логин или пароль.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('participant-login')),
      'aidana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('participant-password')),
      'AidanaDemo2026',
    );
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(entry, findsNothing);
    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('organizer-login')),
      'zhanna',
    );
    final password = find.byKey(const ValueKey('organizer-password'));
    await tester.enterText(password, 'wrong');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Неверный логин или пароль.'), findsOneWidget);
    expect(find.text('Панель Жанны'), findsNothing);
    await tester.enterText(password, 'ZhannaDemo2026');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Панель Жанны'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(entry, findsOneWidget);
  });
}
