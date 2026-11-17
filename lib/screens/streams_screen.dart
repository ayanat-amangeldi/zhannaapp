import 'package:flutter/material.dart';

import '../language.dart';
import '../content.dart';
import 'menu_screen.dart';
import 'stream_catalog_picker.dart';
import '../marathon_streams.dart';
import '../participant_accounts.dart';

String streamDateTime(BuildContext context, DateTime instant) {
  final date = almatyClock(instant);
  final format = MaterialLocalizations.of(context);
  final time = TimeOfDay(hour: date.hour, minute: date.minute);
  return '${format.formatMediumDate(date)} · ${format.formatTimeOfDay(time, alwaysUse24HourFormat: true)}';
}

class StreamsScreen extends StatelessWidget {
  const StreamsScreen({
    super.key,
    required this.streams,
    required this.accounts,
  });
  final MarathonStreams streams;
  final ParticipantAccounts accounts;

  void _edit(BuildContext context, [MarathonStream? stream]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _StreamEditor(streams: streams, accounts: accounts, stream: stream),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: streams,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: Text(context.tr('Создать поток', 'Топ ашу')),
        ),
        const SizedBox(height: 12),
        if (streams.all.isEmpty)
          Text(context.tr('Потоков пока нет.', 'Әзірге топтар жоқ.')),
        for (final stream in streams.all)
          Card(
            child: ListTile(
              title: Text(stream.name),
              subtitle: Text(
                '${streamDateTime(context, stream.startsAt)}\n'
                '${streamDateTime(context, stream.endsAt)}\n'
                '${context.tr('Участницы', 'Қатысушылар')}: ${stream.members.length}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _edit(context, stream),
            ),
          ),
      ],
    ),
  );
}

class _StreamEditor extends StatefulWidget {
  const _StreamEditor({
    required this.streams,
    required this.accounts,
    this.stream,
  });
  final MarathonStreams streams;
  final ParticipantAccounts accounts;
  final MarathonStream? stream;

  @override
  State<_StreamEditor> createState() => _StreamEditorState();
}

class _StreamEditorState extends State<_StreamEditor> {
  late final _name = TextEditingController(text: widget.stream?.name);
  final _form = GlobalKey<FormState>();
  late final _members = {...?widget.stream?.members};
  late final _today = almatyClock(DateTime.now());
  late DateTime _start = widget.stream?.startsAt ?? _midnight(_today);
  late DateTime _end =
      widget.stream?.endsAt ?? _midnight(_today).add(const Duration(days: 1));
  bool _saving = false;
  bool _failed = false;
  late Set<String>? _mealIds = widget.stream?.mealIds;
  late Set<String>? _videoIds = widget.stream?.videoIds;

  Future<void> _pickCatalog(bool meals) async {
    final content = ContentScope.of(context);
    final items = <CatalogItem>[
      if (meals)
        for (final meal in content.meals)
          (
            id: meal.id,
            label: meal.title.resolve(context),
            group: categoryTitle(context, meal.category),
          )
      else
        for (final section in lessonSections)
          for (final lesson in content.lessons.where(
            (item) => item.section == section.ru && item.hasVideo,
          ))
            (
              id: lesson.id,
              label: lesson.title.resolve(context),
              group: section.resolve(context),
            ),
    ];
    final selection = await Navigator.of(context).push<CatalogSelection>(
      MaterialPageRoute(
        builder: (_) => StreamCatalogPicker(
          title: meals
              ? const LocalizedText('Блюда потока', 'Топтың тағамдары')
              : const LocalizedText('Видео потока', 'Топтың бейнелері'),
          items: items,
          initialIds: meals ? _mealIds : _videoIds,
        ),
      ),
    );
    if (!mounted || selection == null) return;
    setState(() {
      if (meals) {
        _mealIds = selection.ids;
      } else {
        _videoIds = selection.ids;
      }
    });
  }

  DateTime _midnight(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).subtract(almatyOffset);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final current = almatyClock(start ? _start : _end);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;
    _set(
      start,
      _midnight(
        date,
      ).add(Duration(hours: current.hour, minutes: current.minute)),
    );
  }

  Future<void> _pickTime(bool start) async {
    final current = almatyClock(start ? _start : _end);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted || time == null) return;
    _set(
      start,
      _midnight(current).add(Duration(hours: time.hour, minutes: time.minute)),
    );
  }

  void _set(bool start, DateTime instant) {
    setState(() {
      if (start) {
        _start = instant;
      } else {
        _end = instant;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_end.isAfter(_start) || !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.streams.save(
        MarathonStream(
          id:
              widget.stream?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          name: _name.text.trim(),
          startsAt: _start,
          endsAt: _end,
          members: _members,
          mealIds: _mealIds,
          videoIds: _videoIds,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  String _selectionSummary(BuildContext context, Set<String>? ids) =>
      ids == null
      ? context.tr('Весь каталог', 'Бүкіл каталог')
      : context.tr('Выбрано: ${ids.length}', 'Таңдалды: ${ids.length}');

  @override
  Widget build(BuildContext context) {
    final validDates = _end.isAfter(_start);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Настройки потока', 'Топ баптаулары')),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const ValueKey('stream-name'),
              controller: _name,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: context.tr('Название потока', 'Топ атауы'),
              ),
              validator: (text) => (text ?? '').trim().isEmpty
                  ? context.tr('Введи название', 'Атауын енгіз')
                  : null,
            ),
            const SizedBox(height: 16),
            Text(context.tr('Время Алматы (UTC+5)', 'Алматы уақыты (UTC+5)')),
            for (final start in [true, false])
              Card(
                child: ListTile(
                  title: Text(
                    start
                        ? context.tr('Начало', 'Басталуы')
                        : context.tr('Окончание', 'Аяқталуы'),
                  ),
                  subtitle: Text(
                    streamDateTime(context, start ? _start : _end),
                  ),
                  onTap: _saving ? null : () => _pickDate(start),
                  trailing: IconButton(
                    tooltip: context.tr('Изменить время', 'Уақытты өзгерту'),
                    icon: const Icon(Icons.schedule),
                    onPressed: _saving ? null : () => _pickTime(start),
                  ),
                ),
              ),
            if (!validDates)
              Text(
                context.tr(
                  'Окончание должно быть позже начала.',
                  'Аяқталу уақыты басталу уақытынан кейін болуы керек.',
                ),
              ),
            const SizedBox(height: 16),
            Text(
              context.tr('Участницы', 'Қатысушылар'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'Если участница уже в другом потоке, она будет перенесена в этот.',
                'Қатысушы басқа топта болса, ол осы топқа ауыстырылады.',
              ),
            ),
            if (widget.accounts.participants.isEmpty)
              Text(
                context.tr(
                  'Сначала создай аккаунт во вкладке «Участницы».',
                  'Алдымен «Қатысушылар» бөлімінде аккаунт аш.',
                ),
              ),
            for (final person in widget.accounts.participants)
              CheckboxListTile(
                key: ValueKey('stream-member-${person.login}'),
                title: Text(person.name),
                subtitle: Text(person.login),
                value: _members.contains(person.login),
                onChanged: _saving
                    ? null
                    : (selected) => setState(() {
                        if (selected == true) {
                          _members.add(person.login);
                        } else {
                          _members.remove(person.login);
                        }
                      }),
              ),
            const SizedBox(height: 16),
            Text(
              context.tr('Материалы потока', 'Топ материалдары'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final meals in [true, false])
              Card(
                child: ListTile(
                  key: ValueKey(meals ? 'stream-meals' : 'stream-videos'),
                  leading: Icon(
                    meals ? Icons.restaurant_menu : Icons.play_circle_outline,
                  ),
                  title: Text(
                    meals
                        ? context.tr('Доступные блюда', 'Қолжетімді тағамдар')
                        : context.tr('Доступные видео', 'Қолжетімді бейнелер'),
                  ),
                  subtitle: Text(
                    _selectionSummary(context, meals ? _mealIds : _videoIds),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _saving ? null : () => _pickCatalog(meals),
                ),
              ),
            if (_failed)
              Text(
                context.tr(
                  'Не удалось сохранить поток.',
                  'Топты сақтау мүмкін болмады.',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: validDates && !_saving ? _save : null,
              child: Text(context.tr('Сохранить поток', 'Топты сақтау')),
            ),
          ],
        ),
      ),
    );
  }
}
