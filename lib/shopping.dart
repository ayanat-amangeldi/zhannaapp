import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sample_meals.dart';
import 'content.dart';
import 'data/shopping_data.dart';

typedef ShoppingKey = (String, ProductUnit, WeightBasis);

class ShoppingLine {
  const ShoppingLine(this.product, this.unit, this.basis, this.amount);
  final Product product;
  final ProductUnit unit;
  final WeightBasis basis;
  final num? amount;

  ShoppingKey get key => (product.id, unit, basis);
  String get storageKey => '${product.id}:${unit.name}:${basis.name}';
}

List<ShoppingLine> sumIngredients(Iterable<(ShoppingIngredient, int)> items) {
  final result = <ShoppingKey, ShoppingLine>{};
  for (final (item, count) in items) {
    final unit = item.unit.canonical;
    final key = (item.product.id, unit, item.basis);
    final amount = item.amount;
    result[key] = ShoppingLine(
      item.product,
      unit,
      item.basis,
      amount == null
          ? null
          : (result[key]?.amount ?? 0) + amount * item.unit.multiplier * count,
    );
  }
  return result.values.toList();
}

class ShoppingController extends ChangeNotifier {
  ShoppingController(this.preferences, {this.content}) {
    content?.addListener(_contentChanged);
    _restore();
  }

  String _account = 'aidana';
  String get _storageKey => _account == 'aidana'
      ? 'shopping_selection_v1'
      : 'shopping_selection_v1_$_account';

  void selectAccount(String login) {
    if (_account == login) return;
    _account = login;
    _restore();
    notifyListeners();
  }

  void _restore() {
    _counts.clear();
    _checked.clear();
    final saved = preferences?.getString(_storageKey);
    if (saved == null) return;
    try {
      final data = jsonDecode(saved);
      if (data is! Map) return;
      final counts = data['counts'];
      if (counts is Map) {
        for (final meal in _meals) {
          final count = counts[meal.id];
          if (count is int && count > 0) _counts[meal.id] = count;
        }
      }
      final checked = data['checked'];
      if (checked is List) _checked.addAll(checked.whereType<String>());
    } on FormatException {
      // Ignore an invalid local snapshot.
    }
  }

  final SharedPreferences? preferences;
  final ContentStore? content;
  List<MealPreview> get _meals => content?.meals ?? sampleMeals;

  ShoppingRecipe? _recipe(String id) =>
      content == null ? shoppingRecipes[id] : content!.shoppingRecipeFor(id);

  void _contentChanged() {
    _checked.retainAll(lines.map((line) => line.storageKey).toSet());
    _save();
  }

  @override
  void dispose() {
    content?.removeListener(_contentChanged);
    super.dispose();
  }

  final _counts = <String, int>{};
  final _checked = <String>{};

  int countFor(String id) => _counts[id] ?? 0;
  int get mealCount => _counts.length;
  Iterable<MealPreview> get selected => selectionFor(null);
  Iterable<MealPreview> selectionFor(Set<String>? mealIds) => _meals.where(
    (meal) =>
        _counts.containsKey(meal.id) && (mealIds?.contains(meal.id) ?? true),
  );
  bool get incomplete => incompleteFor(null);
  bool incompleteFor(Set<String>? mealIds) => _counts.keys
      .where((id) => mealIds?.contains(id) ?? true)
      .any((id) => _recipe(id)?.incomplete ?? true);
  List<ShoppingLine> get lines => linesFor(null);
  List<ShoppingLine> linesFor(Set<String>? mealIds) => sumIngredients([
    for (final entry in _counts.entries)
      if (mealIds?.contains(entry.key) ?? true)
        for (final item
            in _recipe(entry.key)?.ingredients ?? const <ShoppingIngredient>[])
          (item, entry.value),
  ]);

  void toggleMeal(String id) => setCount(id, countFor(id) == 0 ? 1 : 0);
  void setCount(String id, int count) {
    if (count <= 0) {
      _counts.remove(id);
    } else {
      _counts[id] = count;
    }
    _checked.retainAll(lines.map((line) => line.storageKey).toSet());
    _save();
  }

  void clear({Set<String>? mealIds}) {
    if (mealIds == null) {
      _counts.clear();
    } else {
      _counts.removeWhere((id, _) => mealIds.contains(id));
    }
    _checked.retainAll(lines.map((line) => line.storageKey).toSet());
    _save();
  }

  bool isChecked(ShoppingLine line) => _checked.contains(line.storageKey);
  void setChecked(ShoppingLine line, bool checked) {
    if (checked) {
      _checked.add(line.storageKey);
    } else {
      _checked.remove(line.storageKey);
    }
    _save();
  }

  void _save() {
    notifyListeners();
    preferences?.setString(
      _storageKey,
      jsonEncode({'counts': _counts, 'checked': _checked.toList()}),
    );
  }
}

class ShoppingScope extends InheritedNotifier<ShoppingController> {
  const ShoppingScope({
    super.key,
    required ShoppingController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShoppingController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShoppingScope>()!.notifier!;
}
