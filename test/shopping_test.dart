import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhannaapp/data/shopping_data.dart';
import 'package:zhannaapp/main.dart';
import 'package:zhannaapp/shopping.dart';

void main() {
  test(
    'Sums quantities across meals, preserves checks and restores selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final shopping = ShoppingController(prefs);
      addTearDown(shopping.dispose);
      shopping.setCount('lunch_01', 2);
      shopping.setCount('lunch_09', 1);
      ShoppingLine cucumber(ShoppingController controller) =>
          controller.lines.singleWhere((line) => line.product.id == 'cucumber');
      expect(cucumber(shopping).amount, 250);
      expect(shopping.incomplete, isTrue);
      shopping.setChecked(cucumber(shopping), true);
      shopping.setCount('lunch_01', 0);
      expect(cucumber(shopping).amount, 50);
      expect(shopping.isChecked(cucumber(shopping)), isTrue);
      expect(shopping.incomplete, isFalse);
      final restored = ShoppingController(prefs);
      addTearDown(restored.dispose);
      expect(restored.countFor('lunch_09'), 1);
      expect(restored.isChecked(cucumber(restored)), isTrue);
      expect(
        restored.lines.where((line) => line.product.id == 'salt').single.amount,
        isNull,
      );
      restored.clear();
      expect(restored.lines, isEmpty);
    },
  );

  test('Only compatible units and weight bases merge', () {
    const product = Product(
      'chicken',
      ProductGroup.protein,
      'Курица',
      'Тауық еті',
    );
    final lines = sumIngredients([
      (
        const ShoppingIngredient(product, 0.1, ProductUnit.kg, WeightBasis.raw),
        2,
      ),
      (
        const ShoppingIngredient(product, 50, ProductUnit.g, WeightBasis.raw),
        1,
      ),
      (
        const ShoppingIngredient(
          product,
          100,
          ProductUnit.g,
          WeightBasis.cooked,
        ),
        1,
      ),
      (const ShoppingIngredient(product, 1, ProductUnit.pieces), 1),
    ]);
    expect(lines.map((line) => line.amount), [250, 100, 1]);
    expect(lines.map((line) => line.unit), [
      ProductUnit.g,
      ProductUnit.g,
      ProductUnit.pieces,
    ]);
  });

  testWidgets(
    'A lunch can be selected and doubled to make a bilingual shopping list',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('shopping-toggle-lunch_01'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('open-shopping-selection'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('shopping-increase-lunch_01')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Составить список продуктов'));
      await tester.pumpAndSettle();
      final cucumber = find.byKey(const ValueKey('cucumber:g:raw'));
      expect(
        find.descendant(of: cucumber, matching: find.text('200 г · сырой вес')),
        findsOneWidget,
      );
      expect(find.text('Список неполный'), findsOneWidget);
      await tester.tap(cucumber);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(cucumber).value, isTrue);
      await tester.tap(find.byKey(const ValueKey('language-kk')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: cucumber, matching: find.text('Қияр')),
        findsOneWidget,
      );
      expect(tester.widget<CheckboxListTile>(cucumber).value, isTrue);
    },
  );
}
