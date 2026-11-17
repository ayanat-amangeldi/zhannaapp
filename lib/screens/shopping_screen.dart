import 'package:flutter/material.dart';

import '../content.dart' show MealImage;
import '../data/sample_meals.dart';
import '../data/shopping_data.dart';
import '../language.dart';
import '../shopping.dart';

void openShoppingSelection(BuildContext context, {Set<String>? mealIds}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShoppingSelectionScreen(mealIds: mealIds),
      ),
    );

class AddToShoppingButton extends StatelessWidget {
  const AddToShoppingButton({super.key, required this.meal});
  final MealPreview meal;

  @override
  Widget build(BuildContext context) {
    final shopping = ShoppingScope.of(context);
    final selected = shopping.countFor(meal.id) > 0;
    return FilledButton.icon(
      key: ValueKey('shopping-toggle-${meal.id}'),
      onPressed: () => shopping.toggleMeal(meal.id),
      icon: Icon(selected ? Icons.check_box : Icons.add_shopping_cart),
      label: Text(
        selected
            ? context.tr(
                'В покупках · убрать',
                'Сатып алу тізімінде · алып тастау',
              )
            : context.tr('Добавить в покупки', 'Сатып алу тізіміне қосу'),
      ),
    );
  }
}

class ShoppingSelectionScreen extends StatelessWidget {
  const ShoppingSelectionScreen({super.key, this.mealIds});
  final Set<String>? mealIds;

  @override
  Widget build(BuildContext context) {
    final shopping = ShoppingScope.of(context);
    final selection = shopping.selectionFor(mealIds).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Мой выбор', 'Менің таңдауым')),
        actions: const [LanguageSwitch()],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (selection.isEmpty)
              Text(
                context.tr(
                  'Выбери блюда в меню, чтобы составить список.',
                  'Тізім жасау үшін мәзірден тағам таңда.',
                ),
              )
            else ...[
              Text(
                context.tr(
                  'Укажи, сколько раз приготовить каждую порцию.',
                  'Әр порцияны неше рет дайындайтыныңды көрсет.',
                ),
              ),
              const SizedBox(height: 12),
              for (final meal in selection)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.title.resolve(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: context.tr(
                                'Уменьшить количество',
                                'Санын азайту',
                              ),
                              onPressed: shopping.countFor(meal.id) > 1
                                  ? () => shopping.setCount(
                                      meal.id,
                                      shopping.countFor(meal.id) - 1,
                                    )
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${shopping.countFor(meal.id)}'),
                            IconButton(
                              key: ValueKey('shopping-increase-${meal.id}'),
                              tooltip: context.tr(
                                'Увеличить количество',
                                'Санын көбейту',
                              ),
                              onPressed: () => shopping.setCount(
                                meal.id,
                                shopping.countFor(meal.id) + 1,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: context.tr(
                                'Убрать блюдо',
                                'Тағамды алып тастау',
                              ),
                              onPressed: () => shopping.setCount(meal.id, 0),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShoppingListScreen(mealIds: mealIds),
                  ),
                ),
                child: Text(
                  context.tr(
                    'Составить список продуктов',
                    'Азық-түлік тізімін жасау',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => shopping.clear(mealIds: mealIds),
                child: Text(context.tr('Очистить выбор', 'Таңдауды тазарту')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key, this.mealIds});
  final Set<String>? mealIds;

  @override
  Widget build(BuildContext context) {
    final shopping = ShoppingScope.of(context);
    final lines = shopping.linesFor(mealIds);
    final selected = shopping.selectionFor(mealIds).toList();
    final previews = selected.take(3).toList();
    final servings = selected.fold(
      0,
      (total, meal) => total + shopping.countFor(meal.id),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Список покупок', 'Сатып алу тізімі')),
        actions: const [LanguageSwitch()],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Изменить выбор', 'Таңдауды өзгерту')),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Text(
              context.tr('Покупки на неделю', 'Апталық сатып алу'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Количество порций: $servings',
                  'Порция саны: $servings',
                ),
                style: const TextStyle(color: Color(0xFF675953)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (index, meal) in previews.indexed)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == previews.length - 1 ? 0 : 8,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: SizedBox(
                            height: 72,
                            child: MealImage(meal.image),
                          ),
                        ),
                      ),
                    ),
                  for (var i = previews.length; i < 3; i++) const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (shopping.incompleteFor(mealIds))
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Список неполный', 'Тізім толық емес'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        context.tr(
                          'Для некоторых блюд указаны не все продукты или количества. Проверь состав перед покупкой.',
                          'Кей тағамдардың барлық өнімдері немесе мөлшері көрсетілмеген. Сатып алар алдында құрамын тексер.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (lines.isEmpty)
              Text(context.tr('Список пока пуст.', 'Тізім әзірге бос.'))
            else
              for (final group in ProductGroup.values)
                if (lines.any((line) => line.product.group == group)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 4),
                    child: Text(
                      group.label.resolve(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final line in lines.where(
                    (line) => line.product.group == group,
                  ))
                    Column(
                      children: [
                        const Divider(height: 1, color: Color(0xFFE5D9D0)),
                        CheckboxListTile(
                          key: ValueKey(line.storageKey),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(line.product.name.resolve(context)),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _quantity(context, line),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          value: shopping.isChecked(line),
                          onChanged: (value) =>
                              shopping.setChecked(line, value ?? false),
                        ),
                      ],
                    ),
                ],
          ],
        ),
      ),
    );
  }

  String _quantity(BuildContext context, ShoppingLine line) {
    final amount = line.amount;
    final unit = line.unit.label.resolve(context);
    final quantity = amount == null
        ? unit
        : '${amount.toString().replaceAll('.', ',')} $unit';
    return line.basis == WeightBasis.none
        ? quantity
        : '$quantity · ${line.basis.label.resolve(context)}';
  }
}
