import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhannaapp/data/shopping_data.dart';
import 'package:zhannaapp/language.dart';
import 'package:zhannaapp/screens/recipe_ingredients_screen.dart';

void main() {
  testWidgets('An existing ingredient accepts a decimal amount with a comma', (
    tester,
  ) async {
    final language = LanguageController();
    addTearDown(language.dispose);
    ShoppingRecipe? result;
    const cucumber = Product(
      'cucumber',
      ProductGroup.produce,
      'Огурец',
      'Қияр',
    );
    await tester.pumpWidget(
      LanguageScope(
        controller: language,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<ShoppingRecipe>(
                  MaterialPageRoute(
                    builder: (_) => const RecipeIngredientsScreen(
                      initial: ShoppingRecipe([
                        ShoppingIngredient(
                          cucumber,
                          100,
                          ProductUnit.g,
                          WeightBasis.raw,
                        ),
                      ]),
                      products: [cucumber],
                    ),
                  ),
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Огурец'));
    await tester.pumpAndSettle();
    final amount = find.byKey(const ValueKey('ingredient-amount'));
    await tester.enterText(amount, '0');
    await tester.tap(find.text('Сохранить ингредиент'));
    await tester.pumpAndSettle();
    expect(find.text('Введи число больше нуля'), findsOneWidget);
    await tester.enterText(amount, '125,5');
    await tester.tap(find.text('Сохранить ингредиент'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(result!.ingredients.single.amount, 125.5);
    expect(result!.ingredients.single.product.id, 'cucumber');
    expect(result!.ingredients.single.basis, WeightBasis.raw);
  });
}
