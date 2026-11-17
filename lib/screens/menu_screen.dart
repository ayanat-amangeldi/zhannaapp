import 'package:flutter/material.dart';
import '../data/sample_meals.dart';
import '../content.dart';
import '../language.dart';
import '../shopping.dart';
import 'shopping_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.mealIds});
  final Set<String>? mealIds;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  MealCategory category = MealCategory.lunch;

  @override
  Widget build(BuildContext context) {
    final mealIds = widget.mealIds;
    final meals = ContentScope.of(context).meals
        .where(
          (meal) =>
              meal.category == category && (mealIds?.contains(meal.id) ?? true),
        )
        .toList();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  context.tr('Моё меню', 'Менің мәзірім'),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Подборка №5', '№5 жинақ'),
                  style: const TextStyle(color: Color(0xFF806D65)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final item in MealCategory.values)
                      Expanded(
                        child: TextButton(
                          key: ValueKey('category-${item.name}'),
                          onPressed: () => setState(() => category = item),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 12,
                            ),
                            backgroundColor: category == item
                                ? const Color(0xFFF1DFE3)
                                : Colors.transparent,
                            foregroundColor: category == item
                                ? const Color(0xFF75354A)
                                : const Color(0xFF806D65),
                          ),
                          child: Text(
                            categoryTitle(context, item),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: category == item
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr(
                    'Быстрый и доступный вариант.',
                    'Тез дайындалатын, қолжетімді нұсқа.',
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (meals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 40,
                          color: Color(0xFF75354A),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr(
                            'Блюда этого раздела скоро появятся.',
                            'Бұл бөлімнің тағамдары жақында қосылады.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                for (final meal in meals) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MealImage(meal.image, height: 190, fit: BoxFit.cover),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.title.resolve(context),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meal.summary.resolve(context),
                                style: const TextStyle(
                                  height: 1.5,
                                  color: Color(0xFF806D65),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MealScreen(meal: meal),
                                  ),
                                ),
                                child: Text(
                                  context.tr('Смотреть состав', 'Құрамын көру'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AddToShoppingButton(meal: meal),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: OutlinedButton.icon(
              key: const ValueKey('open-shopping-selection'),
              onPressed: () => openShoppingSelection(context, mealIds: mealIds),
              icon: const Icon(Icons.shopping_basket_outlined),
              label: Text(
                '${context.tr('Мой выбор', 'Менің таңдауым')} · ${ShoppingScope.of(context).selectionFor(mealIds).length}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealScreen extends StatelessWidget {
  const MealScreen({super.key, required this.meal});
  final MealPreview meal;
  @override
  Widget build(BuildContext context) {
    final ingredients = meal.ingredients.isNotEmpty
        ? meal.ingredients
        : ContentScope.of(context)
                  .shoppingRecipeFor(meal.id)
                  ?.ingredients
                  .map((ingredient) => ingredient.portionLabel)
                  .toList() ??
              const <LocalizedText>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle(context, meal.category)),
        actions: const [LanguageSwitch()],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: const Color(0xFFFFFCF8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE5D9D0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 3 / 2,
                    child: MealImage(meal.image, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title.resolve(context),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                AddToShoppingButton(meal: meal),
                const SizedBox(height: 24),
                _RecipeSection(
                  icon: Icons.list_alt_rounded,
                  title: context.tr('Состав', 'Құрамы'),
                  children: [
                    for (final (index, item) in ingredients.indexed) ...[
                      if (index > 0)
                        const Divider(height: 1, color: Color(0xFFE5D9D0)),
                      _IngredientRow(text: item.resolve(context)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _RecipeSection(
                  icon: Icons.soup_kitchen_outlined,
                  title: context.tr('Способ приготовления', 'Дайындалу жолы'),
                  children: [
                    for (final (index, step) in meal.steps.indexed) ...[
                      if (index > 0) const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1DFE3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF75354A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step.resolve(context),
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: const Color(0xFFFFFCF8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFE5D9D0)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF75354A), size: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    // Existing recipe entries use an em dash to separate name and quantity.
    const separator = ' — ';
    final split = text.lastIndexOf(separator);
    final name = split < 0 ? text : text.substring(0, split);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
          if (split >= 0) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  text.substring(split + separator.length),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Color(0xFF75354A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String categoryTitle(BuildContext context, MealCategory category) =>
    switch (category) {
      MealCategory.breakfast => context.tr('Завтраки', 'Таңғы ас'),
      MealCategory.lunch => context.tr('Обеды', 'Түскі ас'),
      MealCategory.dinner => context.tr('Ужины', 'Кешкі ас'),
    };
