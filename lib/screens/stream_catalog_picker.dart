import 'package:flutter/material.dart';

import '../language.dart';

typedef CatalogSelection = ({Set<String>? ids});
typedef CatalogItem = ({String id, String label, String group});

class StreamCatalogPicker extends StatefulWidget {
  const StreamCatalogPicker({
    super.key,
    required this.title,
    required this.items,
    required this.initialIds,
  });

  final LocalizedText title;
  final List<CatalogItem> items;
  final Set<String>? initialIds;

  @override
  State<StreamCatalogPicker> createState() => _StreamCatalogPickerState();
}

class _StreamCatalogPickerState extends State<StreamCatalogPicker> {
  late bool _all = widget.initialIds == null;
  late final Set<String> _selected = widget.initialIds == null
      ? widget.items.map((item) => item.id).toSet()
      : {...widget.initialIds!};

  @override
  Widget build(BuildContext context) {
    final groups = widget.items.map((item) => item.group).toSet();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title.resolve(context))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              key: const ValueKey('catalog-allow-all'),
              title: Text(context.tr('Весь каталог', 'Бүкіл каталог')),
              subtitle: Text(
                context.tr(
                  'Включая будущие добавления',
                  'Кейін қосылатын материалдарды қоса',
                ),
              ),
              value: _all,
              onChanged: (value) => setState(() => _all = value),
            ),
            if (!_all) ...[
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () =>
                          _selected.addAll(widget.items.map((item) => item.id)),
                    ),
                    child: Text(context.tr('Отметить всё', 'Бәрін белгілеу')),
                  ),
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: Text(
                      context.tr(
                        'Снять все отметки',
                        'Барлық белгіні алып тастау',
                      ),
                    ),
                  ),
                ],
              ),
              if (groups.isEmpty)
                Text(context.tr('Каталог пока пуст.', 'Каталог әзірге бос.')),
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    group,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final item in widget.items.where(
                  (item) => item.group == group,
                ))
                  CheckboxListTile(
                    key: ValueKey('catalog-item-${item.id}'),
                    title: Text(item.label),
                    value: _selected.contains(item.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(item.id);
                      } else {
                        _selected.remove(item.id);
                      }
                    }),
                  ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop<CatalogSelection>((
              ids: _all ? null : Set<String>.of(_selected),
            )),
            child: Text(context.tr('Применить', 'Қолдану')),
          ),
        ),
      ),
    );
  }
}
