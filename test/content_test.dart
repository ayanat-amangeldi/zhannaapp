import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhannaapp/content.dart';
import 'package:zhannaapp/data/sample_meals.dart';
import 'package:zhannaapp/data/shopping_data.dart';
import 'package:zhannaapp/language.dart';
import 'package:zhannaapp/shopping.dart';

void main() {
  test(
    'Local admin changes survive reopening and retire stale shopping data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = ContentStore(preferences);
      addTearDown(store.dispose);
      final shopping = ShoppingController(preferences, content: store);
      addTearDown(shopping.dispose);
      final original = store.meals.first;
      shopping.toggleMeal(original.id);
      await store.saveMeal(
        MealPreview(
          id: original.id,
          title: const LocalizedText('Новый обед', 'Жаңа түскі ас'),
          image: 'marathon_media/photo.jpg',
          summary: original.summary,
          category: MealCategory.dinner,
          ingredients: const [LocalizedText('Рис — 120 г', 'Күріш — 120 г')],
          steps: original.steps,
        ),
        ingredientsEdited: true,
      );
      await store.saveLesson((
        id: 'test_lesson',
        section: lessonSections.first.ru,
        title: const LocalizedText('Тренировка', 'Жаттығу'),
        description: const LocalizedText('', ''),
        video: const LocalizedText(
          'marathon_media/ru.mp4',
          'marathon_media/kk.mp4',
        ),
      ));
      expect(shopping.lines, isEmpty);
      expect(shopping.incomplete, isTrue);
      final restored = ContentStore(preferences);
      addTearDown(restored.dispose);
      expect(restored.meals.first.category, MealCategory.dinner);
      expect(restored.meals.first.title.kk, 'Жаңа түскі ас');
      expect(restored.meals.first.image, 'marathon_media/photo.jpg');
      expect(restored.lessons, hasLength(9));
      expect(restored.changedIngredients, contains(original.id));
      expect(
        restored.lessons
            .singleWhere((lesson) => lesson.id == 'test_lesson')
            .video
            .kk,
        'marathon_media/kk.mp4',
      );
    },
  );
  test('Existing catalog edits survive when bundled dinners are added', () async {
    SharedPreferences.setMockInitialValues({
      'local_admin_content_v1':
          '{"meals":[{"id":"lunch_01","title":["Локальная правка","Жергілікті өзгеріс"],"image":"assets/images/lunch_01.jpg","summary":["",""],"category":"lunch","ingredients":[],"steps":[]}],"lessons":[],"changedIngredients":["lunch_01"]}',
    });
    final store = ContentStore(await SharedPreferences.getInstance());
    addTearDown(store.dispose);
    expect(
      store.meals.where((meal) => meal.id == 'lunch_01').single.title.ru,
      'Локальная правка',
    );
    expect(
      store.meals.where((meal) => meal.category == MealCategory.dinner),
      hasLength(10),
    );
    final shopping = ShoppingController(null, content: store);
    addTearDown(shopping.dispose);
    shopping.toggleMeal('lunch_02');
    shopping.toggleMeal('dinner_03');
    expect(
      shopping.lines
          .singleWhere((line) => line.product.id == 'buckwheat')
          .amount,
      200,
    );
    expect(
      store.meals.where((meal) => meal.category == MealCategory.breakfast),
      hasLength(10),
    );
    shopping.toggleMeal('breakfast_10');
    expect(
      shopping.lines
          .singleWhere((line) => line.product.id == 'buckwheat')
          .amount,
      300,
    );
    shopping.toggleMeal('dinner_01');
    expect(
      shopping.lines.singleWhere((line) => line.product.id == 'fish').amount,
      170,
    );
  });
  test(
    'New ingredients and edited recipes update a saved shopping selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final content = ContentStore(prefs);
      addTearDown(content.dispose);
      final cart = ShoppingController(prefs, content: content);
      addTearDown(cart.dispose);
      const meal = MealPreview(
        id: 'admin_salad',
        title: LocalizedText('Салат', 'Салат'),
        image: '',
        summary: LocalizedText('', ''),
        ingredients: [],
        steps: [],
      );
      const greens = Product(
        'green_mix',
        ProductGroup.produce,
        'Зелень',
        'Көк шөп',
      );
      final cucumber = content.shoppingProducts.singleWhere(
        (p) => p.id == 'cucumber',
      );
      await content.saveMeal(
        meal,
        ingredientsEdited: true,
        shoppingRecipe: ShoppingRecipe([
          ShoppingIngredient(cucumber, 0.1, ProductUnit.kg, WeightBasis.raw),
          const ShoppingIngredient(greens, 25),
        ]),
      );
      cart.setCount(meal.id, 2);
      cart.toggleMeal('lunch_09');
      expect(
        cart.lines.singleWhere((line) => line.product.id == 'cucumber').amount,
        250,
      );
      await content.saveMeal(
        meal,
        ingredientsEdited: true,
        shoppingRecipe: ShoppingRecipe([
          ShoppingIngredient(cucumber, 125, ProductUnit.g, WeightBasis.raw),
          const ShoppingIngredient(greens, 25),
        ]),
      );
      expect(
        cart.lines.singleWhere((line) => line.product.id == 'cucumber').amount,
        300,
      );
      final restored = ContentStore(prefs);
      addTearDown(restored.dispose);
      final reopenedCart = ShoppingController(prefs, content: restored);
      addTearDown(reopenedCart.dispose);
      expect(
        reopenedCart.lines
            .singleWhere((line) => line.product.id == 'cucumber')
            .amount,
        300,
      );
      expect(
        reopenedCart.lines
            .singleWhere((line) => line.product.id == 'green_mix')
            .amount,
        50,
      );
      expect(
        restored.shoppingProducts
            .singleWhere((p) => p.id == 'green_mix')
            .name
            .kk,
        'Көк шөп',
      );
      expect(reopenedCart.incomplete, isFalse);
    },
  );
  test(
    'WhatsApp contact normalizes input, persists and can be removed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ContentStore(prefs);
      addTearDown(store.dispose);
      await store.saveWhatsAppNumber('+7 (700) 000-00-00');
      expect(store.whatsappNumber, '77000000000');
      await expectLater(
        store.saveWhatsAppNumber('https://example.com'),
        throwsArgumentError,
      );
      final restored = ContentStore(prefs);
      addTearDown(restored.dispose);
      expect(restored.whatsappNumber, '77000000000');
      await restored.saveWhatsAppNumber(' ');
      expect(restored.whatsappNumber, isNull);
    },
  );
}
