import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhannaapp/language.dart';
import 'package:zhannaapp/main.dart';

void main() {
  testWidgets('Organizer issues credentials that work after restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final language = LanguageController(preferences: prefs);
    addTearDown(language.dispose);

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Finder key(String value) => find.byKey(ValueKey(value));

    await tester.pumpWidget(ZhannaApp(controller: language));
    await tester.pumpAndSettle();
    await tap(key('continue-as-participant'));
    await tester.enterText(key('participant-login'), 'zhanna');
    await tester.enterText(key('participant-password'), 'ZhannaDemo2026');
    await tap(find.text('Войти'));
    await tap(find.text('Участницы'));
    await tap(find.text('Добавить участницу'));
    await tester.enterText(key('new-participant-name'), 'Дана');
    await tester.enterText(key('new-participant-login'), 'Aidana');
    await tap(find.text('Создать аккаунт'));
    expect(find.text('Этот логин уже занят'), findsOneWidget);
    await tester.enterText(key('new-participant-login'), 'Dana01');
    await tap(find.text('Создать аккаунт'));
    final issued = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .data!;
    expect(issued, startsWith('Логин: dana01\n'));
    final password = issued.split('Пароль: ').last;
    expect(
      prefs.getString('local_participant_accounts_v1'),
      isNot(contains(password)),
    );

    await tap(find.text('Готово'));
    await tap(find.text('Потоки'));
    await tap(find.text('Создать поток'));
    await tester.enterText(key('stream-name'), 'Ноябрьский поток');
    await tap(key('stream-member-dana01'));
    await tap(key('stream-meals'));
    await tap(key('catalog-allow-all'));
    await tap(find.text('Снять все отметки'));
    await tap(key('catalog-item-lunch_01'));
    await tap(find.text('Применить'));

    await tap(key('stream-videos'));
    await tap(key('catalog-allow-all'));
    await tap(find.text('Снять все отметки'));
    await tap(key('catalog-item-bundled_workout_01'));
    await tap(find.text('Применить'));

    await tester.scrollUntilVisible(
      find.text('Сохранить поток'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(find.text('Сохранить поток'));
    expect(find.text('Ноябрьский поток'), findsOneWidget);

    await prefs.setString(
      'shopping_selection_v1_dana01',
      '{"counts":{"lunch_01":1,"lunch_09":1},"checked":[]}',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ZhannaApp(controller: language));
    await tester.pumpAndSettle();
    await tap(key('continue-as-participant'));
    await tester.enterText(key('participant-login'), 'dana01');
    await tester.enterText(key('participant-password'), password);
    await tap(find.text('Войти'));
    expect(find.text('Привет, Дана'), findsOneWidget);
    expect(find.textContaining('Ноябрьский поток'), findsOneWidget);

    await tap(find.byType(NavigationDestination).at(1));
    expect(find.text('№1 · Гуляш с рисом'), findsOneWidget);
    expect(key('shopping-toggle-lunch_02'), findsNothing);
    expect(find.text('Мой выбор · 1'), findsOneWidget);
    await tap(key('open-shopping-selection'));
    expect(find.text('№1 · Гуляш с рисом'), findsOneWidget);
    expect(find.textContaining('Лаваш с курицей'), findsNothing);
    await tap(find.text('Составить список продуктов'));
    expect(find.text('Лаваш'), findsNothing);
    await tap(find.byType(BackButton));
    await tap(find.byType(BackButton));

    await tap(find.byType(NavigationDestination).at(2));
    await tap(find.text('Тренировки'));
    expect(find.text('Тренировка 1'), findsOneWidget);
    expect(find.text('Тренировка 2'), findsNothing);
  });
}
