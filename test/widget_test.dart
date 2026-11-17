import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhannaapp/language.dart';
import 'package:zhannaapp/main.dart';

void main() {
  testWidgets('Language changes navigation, categories and open recipe', (
    tester,
  ) async {
    await tester.pumpWidget(const ZhannaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-as-participant')));
    await tester.pumpAndSettle();
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
    expect(find.text('Привет, Айдана'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-kk')));
    await tester.pumpAndSettle();
    expect(find.text('Сәлем, Айдана'), findsOneWidget);
    expect(find.text('Басты бет'), findsOneWidget);
    expect(find.text('Привет, Айдана'), findsNothing);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('№1 · Күріш қосылған гуляш'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category-breakfast')));
    await tester.pumpAndSettle();
    expect(
      find.text('№1 · Жұмыртқа ағы қосылған сұлы ботқасы'),
      findsOneWidget,
    );
    expect(find.text('№1 · Күріш қосылған гуляш'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('category-dinner')));
    await tester.pumpAndSettle();
    expect(find.text('№1 · Пеште піскен балық пен картоп'), findsOneWidget);
    expect(find.text('№1 · Күріш қосылған гуляш'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('category-lunch')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Құрамын көру').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Құрамын көру').first);
    await tester.pumpAndSettle();
    expect(find.text('Қияр'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-ru')));
    await tester.pumpAndSettle();
    expect(find.text('Огурец'), findsOneWidget);
    expect(find.text('Қияр'), findsNothing);
    expect(find.text('Состав'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Выберите раздел'), findsOneWidget);
    await tester.tap(find.text('Тренировки'));
    await tester.pumpAndSettle();
    expect(find.text('Видео на казахском'), findsNWidgets(4));
    await tester.tap(find.byKey(const ValueKey('language-kk')));
    await tester.pumpAndSettle();
    expect(find.text('Жаттығулар'), findsOneWidget);
    expect(find.text('1-жаттығу'), findsOneWidget);
    expect(find.text('Бейне қазақ тілінде'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Language persists after rebuilding the app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = LanguageController(preferences: prefs);
    await tester.pumpWidget(ZhannaApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-as-participant')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('language-kk')));
    await tester.pumpAndSettle();
    expect(prefs.getString('language'), 'kk');
    await tester.pumpWidget(const SizedBox.shrink());
    final restored = LanguageController(preferences: prefs);
    await tester.pumpWidget(ZhannaApp(controller: restored));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-as-participant')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('participant-login')),
      'aidana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('participant-password')),
      'AidanaDemo2026',
    );
    await tester.tap(find.text('Кіру'));
    await tester.pumpAndSettle();
    expect(find.text('Сәлем, Айдана'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    restored.dispose();
  });

  testWidgets('Both languages and all tabs fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZhannaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-as-participant')));
    await tester.pumpAndSettle();
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
    for (final language in ['kk', 'ru']) {
      await tester.tap(find.byKey(ValueKey('language-$language')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(NavigationDestination).at(i));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
