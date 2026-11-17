import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sample_meals.dart';
import 'data/shopping_data.dart';
import 'language.dart';

part 'data/bundled_lessons.dart';

const healthSection = LocalizedText(
  'Анализы и витамины',
  'Талдаулар мен дәрумендер',
);
const analysesSection = LocalizedText('Анализы', 'Талдаулар');
const vitaminsSection = LocalizedText('Витамины', 'Дәрумендер');

const helpSection = LocalizedText('Помощь участнице', 'Қатысушыға көмек');

String? normalizeWhatsAppNumber(String input) {
  final digits = input
      .trim()
      .replaceAll(RegExp(r'[\s()-]'), '')
      .replaceFirst(RegExp(r'^\+'), '');
  return RegExp(r'^[1-9][0-9]{6,14}$').hasMatch(digits) ? digits : null;
}

const lessonSections = [
  LocalizedText('Тренировки', 'Жаттығулар'),
  LocalizedText('Вакуум', 'Вакуум'),
  LocalizedText('Психологические уроки', 'Психологиялық сабақтар'),
  LocalizedText('О марафоне', 'Марафон туралы'),
  analysesSection,
  vitaminsSection,
  helpSection,
];

typedef Lesson = ({
  String id,
  String section,
  LocalizedText title,
  LocalizedText description,
  LocalizedText video,
});

extension LessonMedia on Lesson {
  bool get hasVideo => video.ru.isNotEmpty || video.kk.isNotEmpty;
}

Object _pair(LocalizedText text) => [text.ru, text.kk];
LocalizedText _text(dynamic value) =>
    LocalizedText(value[0] as String, value[1] as String);

class ContentStore extends ChangeNotifier {
  ContentStore(this.preferences) {
    final saved = preferences?.getString(_key);
    if (saved == null) return;
    final data = jsonDecode(saved) as Map<String, dynamic>;
    meals = [
      for (final m in data['meals'])
        MealPreview(
          id: m['id'],
          title: _text(m['title']),
          image: m['image'],
          summary: _text(m['summary']),
          category: MealCategory.values.byName(m['category']),
          ingredients: (m['ingredients'] as List).map(_text).toList(),
          steps: (m['steps'] as List).map(_text).toList(),
        ),
    ];
    // Keep local edits, while including new bundled meals after an update.
    final savedIds = meals.map((meal) => meal.id).toSet();
    meals.addAll(sampleMeals.where((meal) => !savedIds.contains(meal.id)));
    lessons = [
      for (final l in data['lessons'])
        (
          id: l['id'] as String,
          section: l['section'] == healthSection.ru
              ? analysesSection.ru
              : l['section'] as String,
          title: _text(l['title']),
          description: _text(l['description']),
          video: _text(l['video']),
        ),
    ];
    final savedLessonIds = lessons.map((lesson) => lesson.id).toSet();
    lessons.addAll(
      bundledLessons.where((lesson) => !savedLessonIds.contains(lesson.id)),
    );
    changedIngredients = Set<String>.from(
      data['changedIngredients'] as List? ?? [],
    );
    final savedRecipes = data['shoppingRecipes'] as Map<String, dynamic>? ?? {};
    _customShopping = savedRecipes.map(
      (id, recipe) => MapEntry(id, _decodeRecipe(recipe)),
    );
  }

  static const _whatsappKey = 'organizer_whatsapp_v1';
  late String? _whatsappNumber = preferences?.getString(_whatsappKey);
  String? get whatsappNumber => _whatsappNumber;

  Future<void> saveWhatsAppNumber(String input) async {
    final number = normalizeWhatsAppNumber(input);
    if (number == null && input.trim().isNotEmpty) {
      throw ArgumentError('Invalid WhatsApp number');
    }
    final saved = number == null
        ? await preferences?.remove(_whatsappKey)
        : await preferences?.setString(_whatsappKey, number);
    if (saved == false) throw StateError('Could not save WhatsApp number');
    _whatsappNumber = number;
    notifyListeners();
  }

  static const _key = 'local_admin_content_v1';
  final SharedPreferences? preferences;
  List<MealPreview> meals = [...sampleMeals];
  List<Lesson> lessons = [...bundledLessons];
  Set<String> changedIngredients = {};
  Map<String, ShoppingRecipe> _customShopping = {};

  ShoppingRecipe? shoppingRecipeFor(String id) =>
      _customShopping[id] ??
      (changedIngredients.contains(id) ? null : shoppingRecipes[id]);

  List<Product> get shoppingProducts => <String, Product>{
    for (final recipe in [...shoppingRecipes.values, ..._customShopping.values])
      for (final item in recipe.ingredients) item.product.id: item.product,
  }.values.toList();

  Future<void> saveMeal(
    MealPreview meal, {
    required bool ingredientsEdited,
    ShoppingRecipe? shoppingRecipe,
  }) async {
    final next = [...meals];
    final index = next.indexWhere((entry) => entry.id == meal.id);
    if (index < 0) {
      next.add(meal);
    } else {
      next[index] = meal;
    }
    final changed = {...changedIngredients};
    final recipes = {..._customShopping};
    if (shoppingRecipe != null) {
      changed.remove(meal.id);
      recipes[meal.id] = ShoppingRecipe(
        List.unmodifiable(shoppingRecipe.ingredients),
        incomplete: shoppingRecipe.incomplete,
      );
    } else if (ingredientsEdited) {
      changed.add(meal.id);
      recipes.remove(meal.id);
    }
    await _save(next, lessons, changed, recipes);
  }

  Future<void> saveLesson(Lesson lesson) async {
    final next = [...lessons];
    final index = next.indexWhere((entry) => entry.id == lesson.id);
    if (index < 0) {
      next.add(lesson);
    } else {
      next[index] = lesson;
    }
    await _save(meals, next, changedIngredients, _customShopping);
  }

  Future<void> _save(
    List<MealPreview> nextMeals,
    List<Lesson> nextLessons,
    Set<String> changed,
    Map<String, ShoppingRecipe> recipes,
  ) async {
    final data = jsonEncode({
      'meals': [
        for (final m in nextMeals)
          {
            'id': m.id,
            'title': _pair(m.title),
            'image': m.image,
            'summary': _pair(m.summary),
            'category': m.category.name,
            'ingredients': m.ingredients.map(_pair).toList(),
            'steps': m.steps.map(_pair).toList(),
          },
      ],
      'lessons': [
        for (final l in nextLessons)
          {
            'id': l.id,
            'section': l.section,
            'title': _pair(l.title),
            'description': _pair(l.description),
            'video': _pair(l.video),
          },
      ],
      'changedIngredients': changed.toList(),
      'shoppingRecipes': recipes.map(
        (id, recipe) => MapEntry(id, _encodeRecipe(recipe)),
      ),
    });
    if (await preferences?.setString(_key, data) == false) {
      throw StateError('Could not save content');
    }
    meals = nextMeals;
    lessons = nextLessons;
    changedIngredients = changed;
    _customShopping = recipes;
    notifyListeners();
  }
}

Map<String, Object> _encodeRecipe(ShoppingRecipe recipe) => {
  'incomplete': recipe.incomplete,
  'ingredients': [
    for (final item in recipe.ingredients)
      {
        'id': item.product.id,
        'group': item.product.group.name,
        'name': _pair(item.product.name),
        'amount': item.amount,
        'unit': item.unit.name,
        'basis': item.basis.name,
      },
  ],
};

ShoppingRecipe _decodeRecipe(Map<String, dynamic> recipe) => ShoppingRecipe([
  for (final item in recipe['ingredients'] as List)
    ShoppingIngredient(
      Product(
        item['id'],
        ProductGroup.values.byName(item['group']),
        _text(item['name']).ru,
        _text(item['name']).kk,
      ),
      item['amount'] as num?,
      ProductUnit.values.byName(item['unit']),
      WeightBasis.values.byName(item['basis']),
    ),
], incomplete: recipe['incomplete'] == true);

class ContentScope extends InheritedNotifier<ContentStore> {
  const ContentScope({
    super.key,
    required ContentStore store,
    required super.child,
  }) : super(notifier: store);
  static ContentStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentScope>()!.notifier!;
}

Future<String> saveMedia(XFile file) async {
  final directory = await getApplicationDocumentsDirectory();
  final folder = await Directory(
    '${directory.path}/marathon_media',
  ).create(recursive: true);
  final extension =
      RegExp(r'\.[a-zA-Z0-9]{1,8}$').firstMatch(file.name)?.group(0) ?? '';
  final filename = '${DateTime.now().microsecondsSinceEpoch}$extension';
  await file.saveTo('${folder.path}/$filename');
  return 'marathon_media/$filename';
}

Future<File> localMedia(String path) async =>
    File('${(await getApplicationDocumentsDirectory()).path}/$path');

class MealImage extends StatelessWidget {
  const MealImage(this.path, {super.key, this.height, this.fit = BoxFit.cover});
  final String path;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(
      height: height,
      child: const Center(child: Icon(Icons.restaurant_menu)),
    );
    if (path.isEmpty) return placeholder;
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return FutureBuilder<File>(
      key: ValueKey(path),
      future: localMedia(path),
      builder: (context, snapshot) => snapshot.hasData
          ? Image.file(
              snapshot.data!,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    );
  }
}
