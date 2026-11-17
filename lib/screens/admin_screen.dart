import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../content.dart';
import '../data/sample_meals.dart';
import '../data/shopping_data.dart';
import 'recipe_ingredients_screen.dart';
import '../language.dart';
import '../participant_accounts.dart';
import '../widgets/whatsapp_contact.dart';
import '../marathon_streams.dart';
import 'participants_screen.dart';
import 'streams_screen.dart';
import 'menu_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.accounts, required this.streams});
  final ParticipantAccounts accounts;
  final MarathonStreams streams;

  @override
  Widget build(BuildContext context) {
    final store = ContentScope.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Панель Жанны', 'Жаннаның басқару панелі')),
          actions: const [LanguageSwitch()],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.tr('Блюда', 'Тағамдар')),
              Tab(text: context.tr('Материалы', 'Материалдар')),
              Tab(text: context.tr('Участницы', 'Қатысушылар')),
              Tab(text: context.tr('Потоки', 'Топтар')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: () => _open(context, const _Editor()),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('Добавить блюдо', 'Тағам қосу')),
                ),
                for (final meal in store.meals)
                  Card(
                    child: ListTile(
                      title: Text(meal.title.resolve(context)),
                      subtitle: Text(categoryTitle(context, meal.category)),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _open(context, _Editor(meal: meal)),
                    ),
                  ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final section in lessonSections)
                  Card(
                    child: ExpansionTile(
                      key: PageStorageKey(section.ru),
                      title: Text(section.resolve(context)),
                      children: [
                        if (section == helpSection)
                          ListTile(
                            leading: const Icon(Icons.chat_outlined),
                            title: Text(
                              context.tr('Номер WhatsApp', 'WhatsApp нөмірі'),
                            ),
                            subtitle: Text(
                              store.whatsappNumber == null
                                  ? context.tr(
                                      'Номер не указан',
                                      'Нөмір көрсетілмеген',
                                    )
                                  : '+${store.whatsappNumber}',
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () =>
                                _open(context, const WhatsAppSettingsScreen()),
                          ),
                        for (final lesson in store.lessons.where(
                          (item) => item.section == section.ru,
                        ))
                          ListTile(
                            title: Text(lesson.title.resolve(context)),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _open(
                              context,
                              _Editor(isLesson: true, lesson: lesson),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(
                            context.tr('Добавить материал', 'Материал қосу'),
                          ),
                          onTap: () => _open(
                            context,
                            _Editor(isLesson: true, initialSection: section.ru),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            ParticipantsScreen(accounts: accounts),
            StreamsScreen(streams: streams, accounts: accounts),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget editor) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => editor));
}

class _Editor extends StatefulWidget {
  const _Editor({
    this.isLesson = false,
    this.meal,
    this.lesson,
    this.initialSection,
  });
  final bool isLesson;
  final MealPreview? meal;
  final Lesson? lesson;
  final String? initialSection;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final form = GlobalKey<FormState>();
  final picker = ImagePicker();
  late final title = _fields(widget.meal?.title ?? widget.lesson?.title);
  late final summary = _fields(
    widget.meal?.summary ?? widget.lesson?.description,
  );
  late final ingredients = _fields(_join(widget.meal?.ingredients));
  late final steps = _fields(_join(widget.meal?.steps));
  late MealCategory category = widget.meal?.category ?? MealCategory.lunch;
  late String section =
      widget.lesson?.section ??
      widget.initialSection ??
      lessonSections.first.ru;
  XFile? photo;
  final videos = <int, XFile>{};
  bool busy = false;
  String? error;
  ShoppingRecipe? _editedShopping;

  ShoppingRecipe? _shoppingFor(ContentStore store) =>
      _editedShopping ?? store.shoppingRecipeFor(widget.meal?.id ?? '');

  Future<void> _editShopping() async {
    final store = ContentScope.of(context);
    final recipe = await Navigator.of(context).push<ShoppingRecipe>(
      MaterialPageRoute(
        builder: (_) => RecipeIngredientsScreen(
          initial: _shoppingFor(store),
          products: store.shoppingProducts,
        ),
      ),
    );
    if (!mounted || recipe == null) return;
    setState(() {
      _editedShopping = recipe;
      error = null;
    });
  }

  List<TextEditingController> _fields(LocalizedText? value) => [
    TextEditingController(text: value?.ru),
    TextEditingController(text: value?.kk),
  ];

  LocalizedText? _join(List<LocalizedText>? lines) => lines == null
      ? null
      : LocalizedText(
          lines.map((line) => line.ru).join('\n'),
          lines.map((line) => line.kk).join('\n'),
        );

  LocalizedText _read(List<TextEditingController> fields) =>
      LocalizedText(fields[0].text.trim(), fields[1].text.trim());

  List<String> _lines(String text) => text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  List<LocalizedText> _pairedLines(List<TextEditingController> fields) {
    final ru = _lines(fields[0].text);
    final kk = _lines(fields[1].text);
    return [for (var i = 0; i < ru.length; i++) LocalizedText(ru[i], kk[i])];
  }

  @override
  void dispose() {
    for (final controller in [...title, ...summary, ...ingredients, ...steps]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pick({int? language}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = language == null
          ? await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1800,
              imageQuality: 88,
            )
          : await picker.pickVideo(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      if (language == null) {
        photo = file;
      } else {
        videos[language] = file;
      }
    } catch (_) {
      if (mounted) {
        error = context.tr(
          'Не удалось открыть медиатеку.',
          'Медиатеканы ашу мүмкін болмады.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    final isLesson = widget.isLesson;
    final oldVideo = widget.lesson?.video ?? const LocalizedText('', '');
    if (isLesson) {
      final body = _read(summary);
      final hasVideo =
          oldVideo.ru.isNotEmpty || oldVideo.kk.isNotEmpty || videos.isNotEmpty;
      if (!hasVideo && (body.ru.isEmpty || body.kk.isEmpty)) {
        setState(
          () => error = context.tr(
            'Добавь видео или заполни текст на обоих языках.',
            'Бейне қос немесе мәтінді екі тілде толтыр.',
          ),
        );
        return;
      }
    }
    if (!isLesson &&
        [ingredients, steps].any(
          (pair) => _lines(pair[0].text).length != _lines(pair[1].text).length,
        )) {
      setState(
        () => error = context.tr(
          'Число строк должно совпадать в обоих языках.',
          'Екі тілдегі жол саны бірдей болуы керек.',
        ),
      );
      return;
    }
    final store = ContentScope.of(context);
    final shoppingRecipe = _shoppingFor(store);
    final portion = _read(ingredients);
    final originalPortion =
        _join(widget.meal?.ingredients) ?? const LocalizedText('', '');
    final portionChanged =
        portion.ru != originalPortion.ru || portion.kk != originalPortion.kk;
    if (!isLesson &&
        (shoppingRecipe == null ||
            shoppingRecipe.ingredients.isEmpty ||
            (portionChanged && _editedShopping == null))) {
      setState(
        () => error = context.tr(
          'Открой «Ингредиенты для покупок» и примени состав для этого блюда.',
          '«Сатып алуға арналған өнімдер» бөлімін ашып, осы тағамның құрамын қолдан.',
        ),
      );
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (isLesson) {
        final video = LocalizedText(
          videos[0] == null ? oldVideo.ru : await saveMedia(videos[0]!),
          videos[1] == null ? oldVideo.kk : await saveMedia(videos[1]!),
        );
        await store.saveLesson((
          id: widget.lesson?.id ?? id,
          section: section,
          title: _read(title),
          description: _read(summary),
          video: video,
        ));
      } else {
        final old = widget.meal;
        final entries = _pairedLines(ingredients);
        await store.saveMeal(
          MealPreview(
            id: old?.id ?? id,
            title: _read(title),
            summary: _read(summary),
            image: photo == null ? old?.image ?? '' : await saveMedia(photo!),
            ingredients: entries,
            steps: _pairedLines(steps),
            category: category,
          ),
          ingredientsEdited: portionChanged,
          shoppingRecipe: shoppingRecipe,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = context.tr(
          'Не удалось сохранить. Попробуй ещё раз.',
          'Сақтау мүмкін болмады. Қайталап көр.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLesson = widget.isLesson;
    final shopping = isLesson ? null : _shoppingFor(ContentScope.of(context));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLesson
              ? context.tr('Материал', 'Материал')
              : context.tr('Карточка блюда', 'Тағам картасы'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (isLesson)
                DropdownButtonFormField<String>(
                  initialValue: section,
                  decoration: InputDecoration(
                    labelText: context.tr('Раздел', 'Бөлім'),
                  ),
                  items: [
                    for (final item in lessonSections)
                      DropdownMenuItem(
                        value: item.ru,
                        child: Text(item.resolve(context)),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() => section = value!),
                )
              else ...[
                DropdownButtonFormField<MealCategory>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: context.tr('Категория', 'Санат'),
                  ),
                  items: [
                    for (final item in MealCategory.values)
                      DropdownMenuItem(
                        value: item,
                        child: Text(categoryTitle(context, item)),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() => category = value!),
                ),
                if (photo != null)
                  Text(photo!.name)
                else if (widget.meal?.image.isNotEmpty ?? false)
                  MealImage(widget.meal!.image, height: 135),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _pick(),
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(context.tr('Выбрать фото', 'Фото таңдау')),
                ),
              ],
              if (!isLesson)
                Card(
                  child: ListTile(
                    key: const ValueKey('recipe-shopping-editor'),
                    leading: const Icon(Icons.shopping_basket_outlined),
                    title: Text(
                      context.tr(
                        'Ингредиенты для покупок',
                        'Сатып алуға арналған өнімдер',
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'Добавлено: ${shopping?.ingredients.length ?? 0}',
                        'Қосылды: ${shopping?.ingredients.length ?? 0}',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: busy ? null : _editShopping,
                  ),
                ),
              for (var i = 0; i < 2; i++) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          i == 0 ? 'Русский' : 'Қазақша',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _field(title[i], context.tr('Название', 'Атауы')),
                        _field(
                          summary[i],
                          isLesson
                              ? context.tr('Текст материала', 'Материал мәтіні')
                              : context.tr('Описание', 'Сипаттама'),
                          required: false,
                          lines: isLesson ? 5 : 2,
                        ),
                        if (isLesson) ...[
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => _pick(language: i),
                            icon: const Icon(Icons.video_file_outlined),
                            label: Text(
                              context.tr('Выбрать видео', 'Бейне таңдау'),
                            ),
                          ),
                          if (videos[i] != null)
                            Text(videos[i]!.name)
                          else if ((i == 0
                                      ? widget.lesson?.video.ru
                                      : widget.lesson?.video.kk)
                                  ?.isNotEmpty ??
                              false)
                            Text(
                              context.tr('Видео добавлено', 'Бейне қосылды'),
                            ),
                        ] else ...[
                          _field(
                            ingredients[i],
                            context.tr(
                              'Состав порции (если отличается от покупок)',
                              'Порция құрамы (сатып алу тізімінен өзгеше болса)',
                            ),
                            required: false,
                            lines: 4,
                          ),
                          _field(
                            steps[i],
                            context.tr(
                              'Приготовление · шаг на строку',
                              'Дайындау · әр жолға бір қадам',
                            ),
                            lines: 4,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : _save,
                child: Text(
                  busy
                      ? context.tr('Подожди…', 'Күте тұр…')
                      : context.tr('Сохранить', 'Сақтау'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: controller,
      enabled: !busy,
      minLines: lines,
      maxLines: lines == 1 ? 1 : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => required && (value?.trim().isEmpty ?? true)
          ? context.tr('Заполни поле', 'Өрісті толтыр')
          : null,
    ),
  );
}
